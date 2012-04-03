class ActivityFeedObserver < ActiveRecord::Observer
  observe :task, :meeting, :call, :emailer

  def after_create(record)
    activity_feed = record.build_activity_feed
    activity_feed.fill
  end

  def after_update(record)
      record.create_activity_feed if !record.activity_feed
      record.activity_feed.fill
  end
end
