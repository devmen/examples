class ActivityFeed < ActiveRecord::Base
  cattr_reader :per_page
  @@per_page = 10


  belongs_to :feedable, :polymorphic => true
  belongs_to :organization
  belongs_to :user
  belongs_to :clientable, :polymorphic => true

  scope :not_closed, where(:status.ne => 'closed')
  scope :all
  scope :current, Proc.new { not_closed.where(:start_datetime.lte => Time.now.to_s, :end_datetime.gte => Time.now.to_s) }
  scope :past, Proc.new { not_closed.where(:end_datetime.lt => Time.now.to_s) }
  scope :future, Proc.new { not_closed.where(:end_datetime.gt => Time.now.to_s) }

  scope :today, Proc.new { not_closed.where("end_datetime BETWEEN ? AND ?", Date.today.to_s, ( Date.today + 1.day).to_s) }
  scope :tomorrow, Proc.new { not_closed.where(:start_datetime.lte => ( Date.today + 1.day ).end_of_day.to_s, :end_datetime.gte => ( Date.today + 1.day ).to_s) }
  scope :week, Proc.new { not_closed.where("start_datetime <= '#{ (Time.now + 1.week).to_s }' AND end_datetime >= '#{ Time.now.to_s }'")}

  scope :order_by_date, order(:end_datetime.asc)
  scope :order_by_date_desc, order(:end_datetime.desc)

  scope :by_organization, lambda { |organization_id| where(:organization_id => organization_id) }
  scope :by_contact, lambda { |contact_id| where(:clientable_type => 'Contact', :clientable_id => contact_id) }
  scope :by_client, lambda { |client_id| where(:clientable_type => 'Client', :clientable_id => client_id) }

  def fill
    self.update_attributes(
      :description => feedable.title,
      :organization => feedable.organization,
      :user => feedable.user,
      :status => feedable.status
    )

    case feedable_type
    when 'Task'
      self.start_datetime = feedable.start_date
      self.end_datetime = feedable.end_date
      if feedable.taskable
        self.clientable = feedable.taskable
        self.client_name = feedable.taskable.full_name
      end
    when 'Meeting'
      self.start_datetime = feedable.start_datetime
      self.end_datetime = feedable.end_datetime
      if feedable.meetable
        self.clientable = feedable.meetable
        self.client_name = feedable.meetable.full_name
      end
    when 'Call'
      self.start_datetime = feedable.start_datetime.beginning_of_day
      self.end_datetime = feedable.start_datetime
      if feedable.callable
        self.clientable = feedable.callable
        self.client_name = feedable.callable.full_name
      end
    when 'Emailer'
      self.start_datetime = Time.now
      self.end_datetime = Time.now + 1.year
      if feedable.mailable
        self.clientable = feedable.mailable
        self.client_name = feedable.mailable.full_name
      end
    end

    self.save!
  end

  class << self
    def collection_by_options(opts={})
      filter_by_date_scope = ( JSON.parse(opts[:filter_by_date]).first[0] rescue nil )
      filter_by_date_scope = :today if !%w[all current past future future today tomorrow week].include?(filter_by_date_scope)

      order_scope = ( JSON.parse(opts[:order_by_date]).first[0] rescue nil )
      order_scope = :order_by_date if !%w[order_by_date order_by_date_desc].include?(order_scope)

      filter_by_contact_scope = ( JSON.parse(opts[:filter_by_contact]) rescue nil )
      filter_by_client_scope = ( JSON.parse(opts[:filter_by_client]) rescue nil )

      if filter_by_contact_scope
        ActivityFeed.send( :by_contact, filter_by_contact_scope["by_contact"]).send( order_scope ).send( filter_by_date_scope )
      elsif filter_by_client_scope
        ActivityFeed.send( :by_client, filter_by_client_scope["by_client"] ).send( order_scope ).send( filter_by_date_scope )
      else
        ActivityFeed.send( filter_by_date_scope ).send( order_scope )
      end
    end
  end
end

