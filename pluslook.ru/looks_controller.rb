class LooksController < InheritedResources::Base

 
  respond_to :html
  respond_to :js, :only => :index
  actions :all, :except => [:new, :create]
  

  load_and_authorize_resource
  skip_authorize_resource :only => [:random, :embed]
  
  has_scope :active, :default => 'true', :only => [:index]
  has_scope :by_album, :as => :album_id, :only => :index
  has_scope :by_voters, :as => :user_id, :only => :index
  # has_scope :by_user, :as => :user, :only => :index
  has_scope :by_categories, :as => :categories, :type => :array, :only => :index
  has_scope :by_month, :as => :month, :only => :index
  has_scope :mode, :only => :index do |controller, scope, value|
    case value
    when 'best'; scope.best
    when 'my','my_best'
      s = scope.scoped
      case
      when (controller.params[:own] and controller.params[:friends]) # both checked
        s = s.where('1 = 2') # show nothing
      when controller.params[:own] # skip own subscribed sites checked
        s = s.by_voters(controller.current_user.own_friends.map(&:id), true) # use only friends
      when controller.params[:friends] # skip friends voted looks checked
        s = s.where(:site_id => controller.current_user.own_subscriptions.map(&:id)) # use only own subscriptions
      else # nothing checked
        s = s.my(controller.current_user.own_friends.map(&:id), controller.current_user.own_subscriptions.map(&:id)) # previous joined by OR
      end if controller.current_user
      value == 'my_best' ? s.best : s
      
      # @tags = Tag.all
    else
      scope
    end
  end

  has_scope :page, :default => 1, :only => :index do |controller, scope, value|
    scope.page(value).per(controller.params[:view] == 'one' ? 50 : 100)
  end
  
  has_scope :eager_loading, :default => 'true', :only => :index
  has_scope :ordered, :default => 'true', :only => :index

  before_filter lambda { @album = Album.find(params[:album_id]) if params[:album_id] }, :only => :index

  before_filter lambda { @user = User.find(params[:user_id]) if params[:user_id] }, :only => :index
  
  def index
    if params[:own] == "false" and params[:friends] == "false"
      return redirect_to mode_looks_path(:mode => params[:mode], :page => 1, :view => params[:view])
    end
    render 'index', :layout => 'looks_wide' if params[:view] != "one"
    
  end  
  
  def search
    @search = Look.search do
      fulltext params[:q]
      paginate :page => params[:page], :per_page => params[:view] == 'one' ? 50 : 100
    end
    @collection = @search#.results
    render 'search', :layout => 'looks_wide' if params[:view] != "one"
  end
  
  def face_info
    render :text => @look.get_face_info.to_json
  end
  
  def random
    looks = Look.best_by_day.all
    @random_look = looks.sort_by{rand}.first
    return render :json => @random_look.to_json
  end
   
  def embed
    @looks = Look.best.ordered.limit(10)
    render 'embed', :layout => nil
  end
  
end