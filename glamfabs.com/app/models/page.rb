class Page < ActiveRecord::Base
  belongs_to :user
  include FacebookClient

  def next_api_id
    max_used_api = Page.connection.select_rows("select max(api_id) from pages where facebook_id = E'#{self.facebook_id}'").flatten.first.to_i
    if max_used_api < APP_ID.count - 1
      return max_used_api + 1
    else 
      return nil
    end
  end

  def count_unread_forms
    Form.connection.select_rows("select count(distinct bucket_id) from forms where page_id = '#{self.id}' and viewed = false").flatten.first.to_i
  end

  def tabs
    Page.find(:all, :conditions => { :facebook_id => self.facebook_id })
  end

  class << self
    include FacebookClient

    def create_from_facebook_attrbutes(id, options)
      api_id, facebook_id = id.split(/-/)
      user = User.find(options[:user_id])
      access_token = OAuth2::AccessToken.new(facebook_client, user.access_token)
      page_attributes = JSON.parse(access_token.get("/#{facebook_id}"))
      page = Page.new(:title => page_attributes['name'], :user_id => user.id)
      page.api_id = api_id
      page.facebook_id = facebook_id
      page.id = id
      page.save!
      page
    end
  end
end
