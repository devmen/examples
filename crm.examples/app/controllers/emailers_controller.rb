class EmailersController <  InheritedResources::Base
  belongs_to :client, :contact, :lead, :polymorphic => true, :optional => true
  respond_to :js, :only => [:new, :create]

  load_and_authorize_resource :emailer, :through => [:client, :contact, :lead]
  custom_actions :resource => :sending
  before_filter :set_options, :only => :new

  def new
    if params[:mailable_id] && params[:mailable_type]
      mailable = eval "#{params[:mailable_type]}.find(#{params[:mailable_id]})"
      resource.email_to = mailable.email rescue nil || mailable.common_email rescue nil
    end
    new!
  end

  def edit
    redirect_to resource
  end

  def create
    @emailer.user = current_user
    @emailer.organization = current_user.organization
    create! do |success, failure|
      failure.js { render 'emailers/new.js.haml' }
    end
    if params[:save_and_send]
      #send mail
      @emailer.sending!
    end
  end

  def update
    update! do |success, failure|
      success.html { redirect_to :back }
      failure.html { render 'show' }
    end
  end

  def sending
    @emailer = current_user.emailers.find(params[:id])
    if @emailer.sending!
      redirect_to :back, :notice => t("emailer.successfull_sending")
    end
  end

  protected
  def set_options
    @emailer.sign = set_sign
    if parent?
      @emailer.email_to =  ( parent_class == Lead ) ? parent.common_email : parent.email
    end
  end

  def set_sign
    current_user.email_sign.try(:body) || "#{ current_user.fio } #{t("user.#{current_user.role}")} <#{current_user.email}> #{current_user.phone_number.try( :phone )}"
  end

end

