class ApplicationController < ActionController::Base
  protect_from_forgery
  include FacebookClient
  include ChargifyClient
  before_filter :catch_referer
  before_filter :set_locale
  helper_method :login_url, :new_page_url, :current_user
  before_filter :authorize_user, :only => [ :remove_ads ]
  before_filter :load_pages, :only => [ :remove_ads ]

  def current_user
    @current_user ||= User.find_by_id(session[:user_id].to_s)
  end
  
  def index
    render :layout => false
  end

  def remove_ads
    raise "test exception" if params[:fail]
  end


  protected

  def catch_referer
    session[:referer] ||= request.referer
  end

  def set_locale
    if params[:locale] || session[:requested_locale]
      session[:requested_locale] = params[:locale] if params[:locale]
      I18n.locale = session[:requested_locale]
    elsif params[:user] && params[:user][:locale].match(/^ru/)
      I18n.locale = 'ru'
    else
      begin
        browser_locale = request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
        browser_locale = 'en' unless browser_locale.match(/^(ru|en)$/)
        I18n.locale = browser_locale
      rescue => e
      end
    end
  end

  def authorize_user
    session[:redirect_to] = request.fullpath
    redirect_to login_url unless authorized?
  end

  def load_pages
    if current_user
      @pages ||= lambda do
        local_pages = current_user.pages
        current_user.facebook_accounts.map do |facebook_account|
          if local_page = local_pages.detect{|it| it.facebook_id.to_s == facebook_account['id'].to_s}
            facebook_account['local_page'] = local_page
          end
          facebook_account
        end
      end.call
    end
    @pages ||= current_user.pages if current_user
  end

  def authorized?
    current_user ? true : false
  end
end
