class PagesController < InheritedResources::Base
  include FacebookClient

  before_filter :cache_contents, :only => [ :update ]
  before_filter :extract_facebook_id, :only => [ :edit ]
  before_filter :load_page, :only => [ :edit, :update, :canvas, :new_tab, :remove ]
  before_filter :load_contents_from_cache, :only => [ :edit ]
  before_filter :authorize_user, :only => [ :edit, :update, :settings, :new_tab, :index ]
  before_filter :load_user, :only => [:edit]
  before_filter :collection, :only => [ :edit, :settings, :cant_create, :index, :remove ]
  before_filter :handle_not_installed, :only => [ :edit ]
  before_filter :handle_cant_create, :only => [:edit]
  before_filter :handle_exceeds_limit, :only => [:edit]
  before_filter :create_page, :only => [ :canvas, :edit ]
  before_filter :handle_not_found, :only => [ :canvas ]

  def index
    if request.post?
      render :action => "facebook_index", :layout => "canvas"
    else
      render :layout => false
    end
  end

  def edit
    session[:page_id] = @page.id
    @page_template = PageTemplate.find params[:template] if params[:template]
    if @page.contents.blank? && @page_template.blank? && request.referer !~ /page_templates/
      redirect_to page_choose_tamplates_path(@page)
    end
  end

  def new_tab
    raise "Out of api_id" unless @page.next_api_id
    redirect_to new_page_url(@page.next_api_id, @page.facebook_id)
  end

  def remove

  end

  def settings
    @page = resource
  end

  def canvas
    render :layout => "canvas"
  end

  def update
    redirect_url = params[:redirect_to] || edit_page_path(@page)
    update!{ redirect_url }
  end

  def destroy
    super do |format|
      format.html { redirect_to pages_path, :notice => I18n.t("destroy_page") }
    end
   end

  protected

  def load_page
    page_id = (params[:page] and params[:page][:id]) || params[:id]
    if params[:api_id]
      page_id = "#{params[:api_id]}-#{page_id}"
    end
    @page = Page.find(:first, :conditions => { :id => page_id })
  end

  def load_user
    user_id = (session[:user_id].present?) ? session[:user_id] : params[:user_id]
    @current_user = User.find(user_id)
  end

  def handle_not_installed
    render :action => "not_installed", :layout => "text" unless JSON.parse(OAuth2::AccessToken.new(facebook_client, ACCESS_TOKEN[0]).get("/#{@facebook_id}"))['has_added_app']
  rescue
  end

  def handle_not_found
    render :action => "not_found", :layout => "canvas" unless @page
  end

  def create_page
    unless @page
      if session[:user_id]
        @page = Page.create_from_facebook_attrbutes(params[:id], :user_id => session[:user_id])
      end
    end
  end

  def cache_contents
    session[:cached_contents] = params[:page][:contents] if params[:page]
  end

  def load_contents_from_cache
    if @page && session[:cached_contents]
      @page.contents = session[:cached_contents]
      @page.save
      session.delete(:cached_contents)
    end
  end

  def authorize_user
    return nil if params[:action] == "index" && !params[:auth]

    if @page
      if session[:user_id].to_s != @page.user_id.to_s
        session[:redirect_to] = "/pages/#{@page.id}/edit"
        redirect_to login_url(params[:api_id])
      end
    else
      super
    end
  end

  def extract_facebook_id
    @facebook_id = params[:id].to_s.gsub(/^.+?\-/, '')
  end

  def collection
    load_pages
  end
end
