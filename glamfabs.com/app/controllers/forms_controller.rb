class FormsController < ApplicationController
  before_filter :authorize_user, :only => [ :index, :show, :destroy ]
  before_filter :load_page, :only => [ :show, :index, :destroy ]
  before_filter :check_page_ownership, :only => [ :show, :destroy ]
  before_filter :load_pages, :only => [ :index, :show ]
  before_filter :load_form, :only => [ :show, :destroy ]
  before_filter :load_forms, :only => [ :index ]
  before_filter :destroy_forms, :only => [ :destroy ]

  def index
  end

  def show
  end

  def submit
    params.each do |k,v|
      next if %w(page_id locale bucket_id controller action).include?(k.to_s)
      Form.create! :page_id => params[:page_id], :key => k, :value => v, :bucket_id => Digest::MD5.hexdigest(params[:bucket_id])
    end
    render :layout => "canvas"
  end

  def destroy
    redirect_to page_forms_path(params[:page_id])
  end


  protected
  def destroy_forms
    Form.connection.execute "delete from forms where id in (0, #{@forms.map(&:id).join(',')})"
    true
  end

  def check_page_ownership
    redirect_to "/pages" if current_user.id != @page.user_id
  end

  def load_page
    @page = Page.find(params[:page_id])
  end

  def load_form
    @forms = Form.find(:all, :conditions => { :bucket_id => params[:id], :page_id => params[:page_id] }, :order => "key")
    Form.update_all "viewed = true", :id => @forms.map(&:id)
  end

  def load_forms
    @forms = Form.paginate( 
                       :select => "min(created_at) created_at, bucket_id, every(viewed) viewed", 
                       :conditions => { :page_id => params[:page_id] }, 
                       :group => "bucket_id", 
                       :order => "every(viewed), min(created_at) desc",
                       :page => params[:page], :per_page => 25
                      )
  end

end
