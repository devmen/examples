# encoding: utf-8
class Hotel < ActiveRecord::Base
  include Platform::Models::RandomOrder
  include Platform::Models::HotelValidate
  include Platform::Models::HotelAttrAccessible
  include Platform::Models::AdvancedTranslate

  belongs_to :user
  belongs_to :hotel_type
  belongs_to :hotel_region, :class_name => 'Region', :foreign_key => 'region', :primary_key => 'region'

  has_many :hotel_translations, :dependent => :destroy
  has_many :hotel_reference_books, :dependent => :destroy
  has_many :hotel_kinds, :through => :hotel_reference_books, :uniq => true
  has_many :hotel_locations, :through => :hotel_reference_books, :uniq => true
  has_many :services, :through => :hotel_reference_books, :uniq => true
  has_many :photos, :as => :photoable, :dependent => :destroy
  has_one  :main_photo, :as => :photoable, :class_name  => "Photo", :readonly => true
  has_many :videos, :as => :videoable, :dependent => :destroy
  has_many :gallery_videos, :as => :videoable, :class_name  => "Video", :conditions => {:media_gallery => true}, :readonly => true
  has_many :hotel_room_categories, :dependent => :destroy
  has_many :rooms, :through => :hotel_room_categories, :source => :rooms
  has_many :hotel_additional_services, :dependent => :destroy
  has_many :hotel_distances, :dependent => :destroy
  has_many :arrangements, :dependent => :destroy
  has_many :orders, :dependent => :destroy
  has_many :hotel_events, :dependent => :destroy

  serialize :extra, Hash

  validates_lengths_from_database :except => [:brochure]
  validates :marketing_text, :short_description, :presence => true

  translates :atmosphere, :location, :features, :promo, :get_by_car, :get_by_public_transport

  # Added method "#{field}_#{locale}"
  advanced_translate :atmosphere, :location, :features, :promo, :get_by_car, :get_by_public_transport

  scope :by_q, lambda{|q| where{(name_core =~ "%#{q}%") | (locality =~ "%#{q}%") | (region =~ "%#{q}%")}}
  scope :by_stars, lambda{|_stars| where(:stars => _stars)}
  scope :by_max_price, lambda{|max_price| joins(:rooms).group{hotels.id}.where{rooms.price <= max_price.to_f}}
  scope :by_people, lambda{|people|
    joins(:rooms).group{hotels.id}.where{
    (hotel_room_categories.min_number_of_guests <= people.to_i) & (hotel_room_categories.max_number_of_guests >= people.to_i)}
  }
  # scope :by_room, lambda{|room| joins(:rooms).group('hotels.id').having("count(rooms.id) >= ?", room.to_i)}
  # scope :by_available, lambda{|from, to|
  #   if booked = Booking.rooms.by_period(from, to).select(:bookingable_id).map(&:bookingable_id) and booked.present?
  #     joins(:rooms).group('hotels.id').where{rooms.id << booked}
  #   end
  # }
  scope :by_available, lambda{|from, to, room|
    booked = Booking.rooms.by_period(from, to).select(:bookingable_id).map(&:bookingable_id)
    joins(:rooms).where{rooms.id << booked}.having{count(rooms.id) >= room.to_i}.group{hotels.id}
  }
  scope :eager_loading, preload(:main_photo) # with_translations # fail during migration
  scope :default_order, order('id DESC')
  scope :home_page, lambda{ with_photos.where(:home_page => true).with_marketing_text.eager_loading.random_order(4)  }
  scope :with_photos, lambda{
    where("COALESCE((select count(photos.id) from photos where hotels.id = photos.photoable_id and photos.photoable_type = :hotel_type ),0)>0", :hotel_type => "Hotel")
  }
  scope :with_marketing_text, where("hotels.marketing_text is not null")

  # marketing_text
  mount_uploader :brochure, SimpleUploader

  extend FriendlyId
  friendly_id :name_core, :use => :slugged

  accepts_nested_attributes_for :services, :hotel_reference_books

  STARS = [1, 2, 3, 4, 5]
  def stars_enum; STARS; end

  alias_attribute :name, :name_core # def name; name_core; end

  def hotel_kind_description(kind_id = nil)
    self.extra ||= { }
    self.extra[:hotel_kind_description] ||= { }
    kind_id ? self.extra[:hotel_kind_description][kind_id.to_s] : self.extra[:hotel_kind_description]
  end
  def hotel_kind_description=(attrs)
    self.extra ||= { }
    self.extra[:hotel_kind_description] ||= { }
    attrs.each { |kind_id, value| self.extra[:hotel_kind_description][kind_id.to_s] = value }
  end

  # TODO Dirty method
  #
  def services=(attrs)
    attrs.each do |service_id, attr|
      @hotel_reference_book = nil
      if attr["enable"].to_s == 'true'
        @hotel_reference_book = self.hotel_service(service_id) ||  self.hotel_reference_books.build({:reference_book_id => service_id, :extra => { }})

        if attr["extra"].present? && attr["extra"].is_a?(Hash)
          @hotel_reference_book.extra = (@hotel_reference_book.extra ||{ }).merge(attr["extra"] || { })
        end
        @hotel_reference_book.verified = attr["verified"] if attr["verified"]

        @hotel_reference_book.save! if @hotel_reference_book.changed?
      else
        if (@hotel_reference_book = hotel_reference_books.find_by_reference_book_id(service_id))
          @hotel_reference_book.destroy
        end
      end

    end
  end

  def hotel_service(service_id)
    hotel_reference_books.find_by_reference_book_id(service_id)
  end

  def all_photos
    photos + hotel_room_categories.map(&:photos).flatten + rooms.map(&:photos).flatten + arrangements.map(&:photos).flatten
  end
  def all_gallery_videos
    [gallery_videos, hotel_room_categories.map(&:gallery_videos),
      rooms.map(&:gallery_videos), arrangements.map(&:gallery_videos)].flatten # Video.all
  end
  class << self
    def for_options(ability)
      order("name_core").accessible_by(ability, :read).map{|v| [v.name, v.id] }
    end
  end
end
