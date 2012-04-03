# encoding: utf-8
class Call < ActiveRecord::Base
  include Features::Viewable
  include Features::TodoTaskable
  include Features::Categorizable

  STATUSES = { 'Запланирован' => 'planned',
               'Состоялся'    => 'took_place',
               'Отменен'      => 'canceled',
               'Помечена на удаление' => 'deleted' }

  belongs_to :organization
  belongs_to :user
  belongs_to :callable, :polymorphic => true

  has_one  :activity_feed, :as => :feedable, :dependent => :destroy

  scope :not_parent_resource, where(:callable_id => nil, :callable_type => nil)
  scope :active_events_for, lambda { |callable|
    Call.where("callable_id = ? AND callable_type = ? AND status = 'planned'", callable.id, callable.class.to_s) }


  before_save :check_callable
  before_save :close_tasks_when_closed
  before_save :save_callable_name


  validates :attachment, :file_size => { :maximum => 1.0.megabytes.to_i }
  validates :title, :user, :presence => true
  validates_datetime :start_datetime
  validate Proc.new {
    errors.add :to_remind, "Дата напоминания должна быть больше даты начала" if to_remind && (!start_datetime || !reminder_time || start_datetime >= reminder_time || Time.now > reminder_time)
  }
  validate  Proc.new {
    errors.add :to_remind, "Нельзя выставлять напоминание, если звонок состоялся" if to_remind && status == 'took_place'
  }

  mount_uploader :attachment, AttachmentUploader
  acts_as_deletant

  define_index do
    indexes status, title, note, callable_name
    indexes [user.surname, user.name], :as => :manager_name

    has start_datetime, organization_id, deleted_at
    has user_id, :as => :user_id, :type => :integer
    has '7', :as => :model_order, :type => :integer

    set_property :field_weights => {
      :title => 1,
      :start_datetime => 2,
      :user_id => 7
    }

    set_property :delta => true

    where "calls.deleted_at IS NULL"
  end

  def check_callable
    self.callable_id = nil if self.callable_id.blank?
    self.callable_type = nil if self.callable_type.blank?
  end

  def close_tasks_when_closed
    if %w{canceled took_place}.include? self.status
      self.close_tasks
    end
  end

  def save_callable_name
    self.callable_name = self.callable_full_name unless self.callable_id.blank?
  end

  def callable_full_name
    m = self.callable
    if m.is_a? Client
      m.full_name
    elsif m.is_a? Contact
      "#{m.surname} #{m.name} #{m.patronymic}"
    elsif m.is_a? Lead
      "#{m.surname} #{m.name} #{m.patronymic}"
    end
  end
end
