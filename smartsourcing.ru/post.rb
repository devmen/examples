# -*- encoding : utf-8 -*-
class Post < ActiveRecord::Base
  belongs_to :user
  belongs_to :blog, :counter_cache => true

  has_many :comments, :as => :commentable, :dependent => :destroy
  has_many :subscribes, :as => :subscribeable, :dependent => :destroy
  has_many :subscribers, :source => :user, :through => :subscribes
  has_many :drafts, :as => :draftable, :dependent => :destroy
  has_many :favorites, :as => :favorable, :dependent => :destroy
  has_many :rates, :as => :rateable, :dependent => :destroy # DEPRECATED
  has_one :posts_feed, :as => :feedable, :dependent => :destroy

  validates :blog, :title, :annotation, :body, :state, :visibility, :published_at, :presence => true
  validates_attachment_size :thumb, :less_than => 1.megabyte, :message => 'размер файла не должен превышать :max байт'
  validates_attachment_content_type :thumb, :content_type => Ckeditor::IMAGE_TYPES, :message => 'неверный формат изображения'

  scope :published, where(:state => 'published')
  scope :published_on_main, lambda {|p| where(:published_on_main => p)}
  scope :by_blog, lambda{|blog_id| where(:blog_id => Blog.by_domain(Domain.current_domain).find(blog_id).id)}
  scope :by_group, lambda{|group_id|
    sql = GroupBlog.where(:group_id=>group_id).select('blog_id').to_sql
    where("blog_id IN (#{sql})")
  }
  scope :by_user, lambda{|user_id| where(:user_id => user_id)}
  scope :by_domain, lambda{|domain| joins(:blog).readonly(false).where("domains & #{Blog.bitmask_for_domains domain} <> 0")}
  scope :eager_loading, preload(:blog, :user, :tags) # :current_user_vote
  scope :eager_loading2, includes(:blog, :user)
  scope :eager_loading3, includes(:blog)
  scope :ordered, order('published_at DESC')

  after_initialize lambda {|r| r.published_at ||= Time.current } # default
  after_create lambda {|r|
    r.create_posts_feed(:domains => r.blog.domains, :published_on_main => r.published_on_main, :published_at => r.state == 'published' ? r.published_at : nil)
  }
  before_update lambda {|r| # sync with feed
    if r.posts_feed and (r.published_on_main_changed? or r.state_changed?)
      r.posts_feed.published_on_main = r.published_on_main
      r.posts_feed.published_at = r.state == 'published' ? r.published_at : nil
      r.posts_feed.save(:validate => false)
    end
  }

  attr_accessible :blog_id, :title, :annotation, :body, :state, :visibility, :tagz, :thumb #, :published_at, :meta_title, :meta_description, :meta_keywords

  has_attached_file :thumb,
                    :url  => "/assets/thumbs/post_:id.:extension",
                    :path => ":rails_root/public/assets/thumbs/post_:id.:extension",
                    :styles => {:original => "190x190>"}

  include Platform::Models::Ratingable
  include Platform::Models::Voteable
  include Platform::Models::Countable
  include Platform::Models::Tag

  define_index do
    indexes title
    indexes annotation
    indexes body
    has blog_id
    
    where "posts.state = 'published'"
    set_property :delta => true
  end
end
