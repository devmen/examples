class OauthController < ApplicationController
  before_filter :handle_errors, :only => [ :oauth ]

  def create
    user = User.authorize(params[:code], "http://#{request.host}/oauth/", :ref_page => session[:referer])
    if user
      session[:user_id] = user.id
      if session[:redirect_to]
        redirect_to session.delete(:redirect_to)
      else
        redirect_to "/pages"
      end
    else
      render :text => "not authorized"
    end
  end

  protected

  def handle_errors
    render :text => params[:error] if params[:error] 
    redirect_to "/" if params[:error_reason] == 'user_denied'
  end

end
