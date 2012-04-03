# Allow the metal piece to run in isolation
require(File.dirname(__FILE__) + "/../../config/environment") unless defined?(Rails)

if Rails.env.to_s == 'development'
  DbBrowse = Rack::Builder.new do
    use RailsDbBrowser::URLTruncate, '/db_browse'
    use Rack::Auth::Basic, 'db_browser' do |user, password|
      user == 'admin' && password == 'iamgod'
    end
    run RailsDbBrowser::DbBrowser
  end
else
  class DbBrowse
    def self.call(env)
      [404, nil, nil]
    end
  end
end
