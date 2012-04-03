class ClientsController < SubdomainController
  respond_to :js, :only => [:new, :create]

  load_and_authorize_resource
  before_filter :log_views, :only=> [:show]
  # visits counter
  before_filter lambda {
    resource.customers_feed.update_last_visit
  }, :only=> [:show]
  # needs for nested resources forms 
  before_filter lambda {
    resource.phone_numbers.build
    resource.offices.build
    resource.email_references.build
    resource.site_references.build
    resource.legal_entities.build
  }, :only => [:show, :edit, :new]

  include LogViews

  autocomplete :client,          :short_name, :full => true
  autocomplete :email_reference, :email,      :full => true

  def create
    @lead = Lead.find(params[:lead_id]) if params[:lead_id]
    @client.user = current_user if current_user.role == "sales_manager"

    create! do |success, failure|
      failure.js { render 'clients/new.js.haml' }
      failure.html { render 'leads/create_client' }
      success.html {
        @lead.update_attribute(:status, 'deleted')
        @lead.update_attribute(:is_converted_to_client, true)
        redirect_to client_path(resource)
      }
    end
  end

  def update
    update! do |success, failure|
      success.html { redirect_to :back }
      failure.html { render 'show' }
    end
  end

  def autocomplete_client_short_name # overrides autocomplete
    render :json => Client.where(["short_name ILIKE '%' || ? || '%' AND organization_id = ?", params[:term], @organization.id]).map { |client|
      { :label => client.short_name,
        :path  => client_path(client)
      }
    }
  end

  def autocomplete_email_reference_email # overrides autocomplete
    render :json => EmailReference.where(["email ILIKE '%' || ? || '%'", params[:term]]).
      select { |email_ref|
        email_ref.emailable && email_ref.emailable.organization == @organization
      }.map { |email_ref|
      { :label => "%s, %s" % [email_ref.email, email_ref.emailable.class.model_name.human],
        :value => email_ref.email,
        :path  => "/%s/%d" % [email_ref.emailable.class.name.underscore.pluralize, email_ref.emailable_id]
      }
    }
  end
end

