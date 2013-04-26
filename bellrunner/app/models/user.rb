class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me

  LIMIT_OF_DURATION = 30.minutes


  has_many :tracks

  # Total track duration
  #
  def duration
    tracks.sum(:duration)
  end

  def limit_of_duration?
    duration >= LIMIT_OF_DURATION
  end

  class << self

    # Create guest user
    #
    def guest_user
      u = create(:email => "guest_#{Time.now.to_i}#{rand(99)}@example.com")
      u.save(:validate => false)
      u
    end

  end

end
