class User < ActiveRecord::Base
  has_many :pages
  belongs_to :plan
  include ChargifyClient
  include FacebookClient

  before_create :apply_free_plan

  def next_api_id
    used_apis = Page.connection.select_rows("select api_id, count(*) from pages where user_id = E'#{self.id}' group by api_id order by count(*)")
    if used_apis.count < APP_ID.count
      return used_apis.count
    else
      used_apis.first[0]
    end
  end

  def apply_free_plan
    self.plan = Plan.find_by_name('free')
  end

  def already_uploaded
    Ckeditor::Asset.where(:user_id => id).map(&:data_file_size).sum
  end

  def available_space
    self.plan.upload_limit * 1024 - already_uploaded
  end

  def cancel_subscription
    chargify_client.cancel_subscription(self.subscription_id)
    update_attributes! :ad_free => "canceling"
    true
  end

  def pages_limit
    self.plan.pages_limit
  end

  def upload_limit
    self.plan.upload_limit
  end

  def cannot_create_page?
    self.pages.count >= self.pages_limit ? true : false
  end

  def exceeds_page_limit?
    self.pages.count > self.pages_limit
  end

  def reactivate_subscription
    update_attribute :ad_free, 'activating'
    chargify_client.reactivate_subscription(self.subscription_id)
  end

  def oauth_access_token
    @oauth_access_token ||= OAuth2::AccessToken.new(facebook_client, self.access_token)
  end

  def facebook_accounts
    @facebook_accounts ||= JSON.parse(oauth_access_token.get('/me/accounts'))['data']
  rescue
    []
  end

  class << self
    include FacebookClient

    def authorize(code, redirect_uri, args={})
      access_token = facebook_client.web_server.get_access_token(code, :redirect_uri => redirect_uri)

      facebook_attributes = JSON.parse(access_token.get('/me'))

      user = self.find_by_id(facebook_attributes['id']) || self.create_from_facebook_attributes(facebook_attributes, access_token.token)

      if user
        args.each do |k, v|
          user.update_attribute k, v if user.send(k) != v
        end
      end

      return user
    end

    def create_from_facebook_attributes(attrs, access_token)
      user = self.new :first_name => attrs['first_name'],
                      :last_name => attrs['last_name'],
                      :email => attrs['email'],
                      :access_token => access_token
      user.id = attrs['id']
      user.save!
      user
    end

  end
end
