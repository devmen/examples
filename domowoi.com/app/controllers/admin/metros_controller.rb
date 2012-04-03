class Admin::MetrosController < ApplicationController
  layout 'office'
  before_filter do |c| c.authorize! :manage, Metro end

  inherit_resources

  def create
    create!{ collection_path }
  end

  def update
    update!{ collection_path }
  end

  def autocomplete_city_name
    @cities = Adress.find(:all, :conditions => ["o_type_id=? and name ilike ?", Adress::TYPES_REVERSE["City"], "#{params[:term]}%"], :limit => 15)
    render :json => @cities.collect {|c| {:id => c.id, :label => "#{c.name}, #{c.parents.first.name}", :value => "#{c.name}, #{c.parents.first.name}"} }
  end

  protected
    def collection
      @metros ||= end_of_association_chain.sorted.paginate(:page => params[:page], :per_page => 20)
    end
end

