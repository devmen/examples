class HotelsController < InheritedResources::Base
  respond_to :html, :js, :mss
  actions :show, :index
  before_filter :search_params!, :only => :index
  before_filter :save_search_uri, :only => :index
  # before_filter :authenticate_user!, :except => [:index, :show]
  # load_and_authorize_resource

  has_scope :by_q, :only => :index, :using => [:q], :as => :search,
            :if => lambda{|t|
    !!(t.params[:search].try(:[],:q) and ![ I18n.t("search_form.short_destination_placeholder"), I18n.t("search_form.destination_placeholder")
                                          ].include?(t.params[:search][:q].to_s)  )
  }
  has_scope :by_stars, :only => :index, :using => [:stars], :as => :search,
            :if => lambda{|t| t.params[:search].try(:[],:stars).to_i > 0}
  has_scope :by_max_price, :only => :index, :using => [:max_price], :as => :search,
            :if => lambda{|t| t.params[:search].try(:[],:max_price).to_i > 0}
  has_scope :by_people, :only => :index, :using => [:people], :as => :search,
            :if => lambda{|t| t.params[:search].try(:[],:people).to_i > 0}
  # has_scope :by_room, :only => :index, :using => [:room], :as => :search,
  #           :if => lambda{|t| t.params[:search].try(:[],:room).to_i > 0}
  # has_scope :by_available, :only => :index, :using => [:arrival, :departure], :as => :search,
  #           :if => lambda{|t| !!(t.params[:search].try(:[],:arrival) and t.params[:search].try(:[],:departure))}
  has_scope :by_available, :only => :index, :using => [:arrival, :departure, :room], :as => :search,
            :if => lambda{|t| !!(t.params[:search].try(:[],:arrival) and t.params[:search].try(:[],:departure) and t.params[:search].try(:[],:room))}
  has_scope :eager_loading, :default => 'true', :only => :index
  has_scope :page, :default => 1, :only => :index

  private
  def save_search_uri
    session[:return_to_search_results] = request.fullpath
  end
end
