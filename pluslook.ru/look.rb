class Look < ActiveRecord::Base
  STATES = %w(active blocked draft frozen)
  MIN_WIDTH = 380; MIN_HEIGHT = 500

  paginates_per 50
  serialize :source_info
  serialize :face_info
  belongs_to :topic, counter_cache: true
  belongs_to :site, counter_cache: true
  has_many :complaints, as: :complaintable, dependent: :destroy
  has_many :look_albums, :dependent => :destroy
  has_many :comments
  has_many :albums, :through => :look_albums
  has_many :votings
  has_one :current_user_voting, :class_name => 'MakeVoteable::Voting', :as => :voteable, :conditions => proc{ {:voter_id => User.current_user.try(:id), :voter_type => 'User'} }
  has_one :current_user_complaint, :class_name => 'Complaint', :as => :complaintable, :conditions => proc{ {:user_id => User.current_user.try(:id)} }
  has_many :current_user_look_albums, :class_name => 'LookAlbum', :conditions => proc{ {:album_id => User.current_user.try(:albums)} }

  validates :topic, :site, :source_url, :image, :md5_hash, :presence => true
  validates :md5_hash, :uniqueness => true #, :on => :create
  validate lambda { errors.add(:image, :dimensions_error) if image.width.to_i < MIN_WIDTH or image.height.to_i < MIN_HEIGHT } #, :on => :create

  after_initialize lambda {|record| record.state ||= 'active'} # default

  before_validation {|record|
    record.md5_hash = Digest::MD5.file(record.image.path).hexdigest if record.image_changed? or record.remote_image_url
    record.source_url = record.remote_image_url if record.remote_image_url
    record.site_id = record.topic.site_id # sync with topic
  }
  after_destroy {|record| FileUtils.rm_rf File.dirname(record.image.path)}
  
  before_create :update_source_info
  before_create :set_face_info
  
  scope :frozen, where(:state => 'frozen')
  scope :active, where(:state => 'active')
  scope :by_album, lambda {|album| joins(:look_albums).where("look_albums.album_id = ?", album)}
  scope :by_voters, lambda {|voters, up = 1| joins(:votings).where("votings.voter_type = 'User' AND votings.voter_id IN (?) AND votings.up_vote = ?", voters, up)}
  scope :by_user, lambda {|user| joins(:site).where("sites.user_id = ?", user)}
  scope :by_categories, lambda {|categories| joins(:site).where("sites.category_id NOT IN (?)", categories)} # joins(:topic => :site)
  scope :by_month, lambda {|month| where("MONTH(looks.created_at) = ?", month)}
  scope :best, where('looks.up_votes - looks.down_votes >= 1')
  scope :my, lambda {|voters, sites|
    joins("LEFT JOIN votings ON votings.voteable_id = looks.id AND votings.voteable_type = 'Look'").
    where("(votings.voter_type = 'User' AND votings.voter_id IN (?) AND votings.up_vote = ?) OR (site_id IN (?))", voters, true, sites)}
  scope :but, lambda{|look| where('looks.id <> ?', look)}
  scope :last_week, lambda { lw = Time.current.since(-1.week); where('looks.created_at >= ? AND looks.created_at <= ?', lw.beginning_of_week, lw.end_of_week) }
  scope :eager_loading, preload(:topic, :current_user_voting, :current_user_complaint, :current_user_look_albums)
  scope :ordered, order('created_at DESC')

  scope :best_by_day, where(["created_at > ?", 10.day.ago]).order('looks.up_votes - looks.down_votes desc').limit(10)
  

  mount_uploader :image, ImageUploader
  make_voteable
  
  acts_as_commentable
  
  
  # searchable do
  #   text :topic_title, :boost => 5 do
  #     topic.title
  #   end
  #   text :topic_tags, :boost => 5 do
  #     topic.categories.map(&:name)
  #   end
  # end
  
  
  def voters
    User.where(:id => self.votings.map(&:voter_id))
  end
  
  def update_source_info
    self.source_info = {:w => self.image.width.to_i, :h => self.image.height.to_i, :r => (self.image.width.to_f / self.image.height.to_f).round(3)}
  end
  
  def set_face_info
    self.face_info = get_face_info(false)
  end
  
  def get_height(width = 240)
    (width / self.source_info[:r]).to_i if self.source_info
  end  
  
  def get_face_info(use_cache = true)
    return self.face_info if use_cache && self.face_info
    client = Face.get_client(:api_key => @@apis_config[Rails.env]["face"]["key"], :api_secret => @@apis_config[Rails.env]["face"]["secret"])
    face = client.faces_detect(:urls => [source_url])
    begin
      face["photos"][0]["tags"][0]["attributes"]
    rescue => e
      face_logger ||= Logger.new("log/face_info.log")
      face_logger.error(e)
      face_logger.error(face.to_yaml)
    end
  end
  
  def get_gender(min_confidence = 50)
    return if !face_info.is_a?(Hash)
    return if !face_info["gender"].present?
    return if face_info["gender"]["confidence"] <= min_confidence
    face_info["gender"]["value"]
  end
  
end
