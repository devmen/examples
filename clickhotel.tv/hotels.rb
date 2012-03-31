ActiveAdmin.register Hotel do
  # config.clear_sidebar_sections!

  menu :priority => 2, :label => "Hotels"
  scope(:hotels, :default => true){|hotels| current_user.admin? ? hotels : current_user.hotels  }

  filter :name_core, :label => "Hotelsuche"

  index do
    column :name_core
    column :street_address
    column :postal_code
    column :locality
    default_actions
  end

  show do
    panel "" do
      attributes_table_for resource, :name_core, :name_verified, :chtv_number, :chtv_number_verified, :cooperation,  :cooperation_verified,
      :stars, :stars_verified, :hotel_type_id, :hotel_type_verified, :hotel_kinds_verified, :location_verified, :street_address,
      :locality, :region, :postal_code, :phone_number, :fax_number, :email, :website, :address_verified, :email_for_booking,
      :fax_for_booking, :email_for_contracts, :fax_for_contracts, :email_for_chtv_bills, :fax_for_chtv_bills, :contact_info_verified,
      :contact_first_name, :contact_last_name, :contact_phone_number, :contact_fax_number, :contact_email, :contact_verified,
      :floors_count, :rooms_count, :single_rooms_count, :double_rooms_count, :double_rooms_2_single_beds_count, :double_rooms_double_bed_count,
      :double_rooms_as_triple_count, :double_rooms_as_4_beds_count, :double_rooms_connecting_door_count, :suites_rooms_count,
      :junior_suites_rooms_count, :appartments_rooms_count, :non_smoking_rooms_count, :allergy_rooms_count,
      :family_rooms_count, :family_rooms_max_people_count, :baby_beds_count, :comfort_rooms_count, :business_rooms_count, :has_handicapped_rooms,
      :handicapped_rooms_count, :build_year, :last_repair_year, :description_verified, :atmosphere_de, :location_de, :features_de,
      :atmosphere_en, :location_en, :features_en, :marketing_text, :short_description, :latitude, :longitude

      attributes_table_for resource do
        row( I18n.t("activerecord.attributes.hotel.reception_open") )        {
          I18n.l(resource.reception_open,        :format => "%H:%M")  if resource.reception_open
        }
        row( I18n.t("activerecord.attributes.hotel.reception_closed") )      {
          I18n.l(resource.reception_closed,      :format => "%H:%M") if resource.reception_closed
        }
        row( I18n.t("activerecord.attributes.hotel.check_in_out_earliest") ) {
          I18n.l(resource.check_in_out_earliest, :format => "%H:%M") if resource.check_in_out_earliest
        }
        row( I18n.t("activerecord.attributes.hotel.check_in_out_no_later") ) {
          I18n.l(resource.check_in_out_no_later, :format => "%H:%M") if resource.check_in_out_no_later
        }

      end

      attributes_table_for resource,  :reception_verified, :multilingual_staff, :english_speaking_staff, :multilingual_staff_verified,  :brochure, :home_page
      if can?(:verify, resource)
        attributes_table_for resource do
          row(I18n.t("activerecord.attributes.hotel.commission_rate") ){ number_to_percentage( resource.commission_rate.to_f, :precision => 2 )  }
        end

      end
    end


  end

  form :partial => "form"

  sidebar :resources, :only => [:show, :edit, :locations, :brouschure, :services]

  [:locations, :brouschure, :services].each do |act|

    member_action(act, :method => :get) do
      @action_items = []
      render("#{act}")
    end
  end

  [:locations, :brouschure].each do |act|
    member_action "update_#{act}", :method => :put do
      if update_resource(resource, resource_params)
        flash[:notice] = I18n.t "flash.actions.#{act}.notice"
        redirect_to send("#{act}_admin_hotel_path", resource)
      else
        render("#{act}")
      end
    end
  end

  member_action :update_services, :method => :put do
    resource.services = params[:hotel][:services]
    resource.save(:validate => false)
    redirect_to services_admin_hotel_path(resource)
  end

  member_action :brouchure_destroy, :method => :delete do
    resource.remove_brochure!
    render :brouschure
  end


  before_create { |hotel| hotel.user = current_user }
  controller { def edit; super; end }

  controller do

    protected

    # Need remove after install  InheritedResources ~> 1.3.0
    #
    def update_resource(object, attributes)
      object.update_attributes(*attributes)
    end

    # Need remove after install  InheritedResources ~> 1.3.0
    #
    def build_resource
      get_resource_ivar || set_resource_ivar(end_of_association_chain.send(method_for_build, *resource_params))
    end

    private

    # Need remove after install  InheritedResources ~> 1.3.0
    #
    def resource_params
      rparams = [params[:hotel] || {}]
      rparams << { :as => current_user.attr_accessible_role }
      rparams
    end

  end
  controller { before_filter(:only => [:services, :brouschure, :locations]) { action_methods.delete('new') } }
  controller { before_filter(:only => :index) { action_methods.add('new') } }

end
