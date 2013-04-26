class ApplicationController < ActionController::Base
  protect_from_forgery
  before_filter :sign_guest_user

  private

  def sign_guest_user
    unless current_user
      sign_in :user, User.guest_user
    end
  end

end
