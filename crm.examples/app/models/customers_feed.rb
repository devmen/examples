class CustomersFeed < ActiveRecord::Base
  belongs_to :customers_feedable, :polymorphic => true
  belongs_to :organization

  scope :favourite, where(:is_favourite => true)
  scope :best, order(:last_visit.asc)
  scope :worst, order(:last_visit.desc)
  scope :all
  scope :order_by_description, order(:description.asc)
  scope :order_by_description_desc, order(:description.desc)
  scope :by_organization, lambda { |organization_id| where(:organization_id => organization_id) }
  scope :by_user, lambda { |user_id| where(:user_id => user_id) }

  def increase_visits_count
    self.customers_feedable.update_attribute(:visits_count, self.customers_feedable.visits_count + 1)
    self.update_attribute(:visits_count, self.customers_feedable.visits_count + 1)
  end

  def update_last_visit
    self.customers_feedable.update_attribute(:last_visit, Time.now)
    self.update_attribute(:last_visit, Time.now)
  end

  def fill
    self.organization = customers_feedable.organization
    self.user_id      = customers_feedable.user_id

    if customers_feedable_type == 'Lead'
      self.description = ( customers_feedable.full_name.blank? ? customers_feedable.company_name : customers_feedable.full_name )
      self.is_favourite = false
    else
      self.description = customers_feedable.full_name
      self.is_favourite = customers_feedable.is_favourite
    end

    if customers_feedable_type == 'Client'
      self.status = 'active'
    else
      self.status = customers_feedable.status
    end

    save!
  end

  class << self
    def collection_by_options(opts={})
      filter_scope = ( JSON.parse(opts[:customers_filter]).first[0] rescue nil )
      filter_scope = :all if !%w[all best worst favourite].include?(filter_scope)

      order_scope = ( JSON.parse(opts[:order_by_description]).first[0] rescue nil )
      order_scope = :order_by_description if !%w[order_by_description order_by_description_desc].include?(order_scope)

      CustomersFeed.send( order_scope )
    end
  end
end
