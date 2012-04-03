class CustomersFeedObserver < ActiveRecord::Observer
  observe :client, :contact, :lead

  def after_create(record)
    customers_feed = record.build_customers_feed
    customers_feed.fill
  end

  def after_update(record)
    record.customers_feed.fill
  end
end
