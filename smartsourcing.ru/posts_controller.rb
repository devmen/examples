# -*- encoding : utf-8 -*-
class PostsController < InheritedResources::Base
  respond_to :html
  respond_to :rss, :only => :index

  # process not authenticated file download same as post for registered users only
  before_filter lambda { raise CanCan::AccessDenied.new("Not authorized!", :show, Post.new) if params[:id] == 'download' }, :only => 'show'

  before_filter :authenticate_user!, :except => [:index, :show, :search]
  load_and_authorize_resource :except => :search

  has_scope :page, :default => 1, :only => :index
  has_scope :ordered, :default => 'true', :only => :index
  has_scope :by_blog, :only => :index, :as => :blog_id
  has_scope :by_group, :only => :index, :as => :group_id
  has_scope :by_user, :only => :index, :as => :user_id
  has_scope :tag, :only => :index

  before_filter lambda { resource.thumb = nil if params[:thumb_delete] }, :only => :update
  before_filter lambda {
    if params[:blog_id]
      @blog = Blog.by_domain(Domain.current_domain).find(params[:blog_id])
      redirect_to @blog, :status => :moved_permanently unless @blog.friendly_id_status.best?
    end
    @group = Group.by_domain(Domain.current_domain).find(params[:group_id]) if params[:group_id]
    @tag = ActsAsTaggableOn::Tag.find(params[:tag]) if params[:tag]
    @user = User.find(params[:user_id]) if params[:user_id]
  }, :only => :index
  # Redirect legacy URLs
  before_filter lambda {
    unless resource.blog.cached_slug == params[:blog]
      # redirect_to blog_post_path(resource, :blog => resource.blog.cached_slug), :status => :moved_permanently
      redirect_to resource, :status => :moved_permanently
    end
  }, :only => :show
  before_filter lambda {
    recommendations = params[:post].delete(:recommendations)
    unless recommendations.nil?
      authorize! :recommend, resource
      resource.recommendations = recommendations
    end
  }, :only => [:update, :create]

  after_filter lambda { cookies[:new_post] = 'true' }, :only => :create

  helper_method :current_ability

  caches_page :show, :unless => lambda { |c| c.user_signed_in? }
  cache_sweeper :post_sweeper, :only => [:create, :update, :destroy]
  cache_sweeper :posts_feed_sweeper, :only => [:publish_on_main, :unpublish_from_main]

  # include Platform::Controllers::CollectionRedirect
  include Platform::Controllers::Paternity
  include Platform::Controllers::Domain
  include Platform::Controllers::EagerLoading
  include Platform::Controllers::Subscribeable
  include Platform::Controllers::Publishable

  def index
    respond_with(collection) do |format|
      format.html { render request.xhr? ? {:partial => 'all'} : 'index' }
    end
  end

  def search
    respond_with(collection)
  end

  protected

  def collection
    @posts ||= if params[:action] == 'search'
                 Post.search params[:query],
                             :with => {:blog_id => Blog.by_domain(Domain.current_domain).map(&:id)},
                             :include => [:blog, :user, :tags],
                             :page => params[:page],
                             :per_page => Platform.per_page
               else
                 super
               end
  end
end
