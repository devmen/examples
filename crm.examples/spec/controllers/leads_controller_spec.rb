# encoding: utf-8
require 'spec_helper'

describe LeadsController do
  # TODO: smth like find_or_make (as seen in datamapper)
  let(:devmen_user) { User.make!(:email => 'devmen@devmen.com',
                                 :role => 'sales_manager').tap { |user| user.confirm! } }
  let(:devmen_admin) { User.make!(:email => 'admin@devmen.com',
                                  :role => 'administrator').tap { |user| user.confirm! } }
  before { Lead.make!(4, :user => devmen_user) }

  def stub_request_subdomain
    @request.stub(:subdomain).and_return('devmen')
  end

  def login_devmen_user( user )
    @request.env['devise.mapping'] = Devise.mappings[:user]
    sign_in user
  end
#
  shared_examples_for 'user can view index' do
    describe 'GET index' do
      before { get :index }

      it 'displays successfully' do
        response.should be_success
      end

      it 'fetches 4 leads' do
        assigns(:leads).size.should == 4
      end
    end
  end


  shared_examples_for 'devmen users new' do
    it 'displays successfully' do
      response.should be_success
    end

    it 'builds lead with phone number field provided' do
      assigns(:lead).phone_number.should_not be_nil
    end
  end


  context 'for sales manager' do
    before do
      login_devmen_user(devmen_user)
      stub_request_subdomain

      LeadsController.stub(:current_user).and_return(devmen_user)
    end

    it_should_behave_like 'user can view index'

    describe 'GET new' do
      before { get :new }

      it_should_behave_like 'devmen users new'

      it 'builds lead with user_id == devmen_user.id' do
        assigns(:lead).user_id.should == devmen_user.id
      end
    end

    describe 'GET show' do
      before do
        get :show, :id => Lead.first.id
      end

      it 'displays successfully' do
        response.should be_success
      end

      it 'needs phone_number provided to show phone_number inputs' do
        assigns(:lead).phone_number.should_not be_nil
      end
    end


    def lead_parameters
      @defaults = {
        :user_id => devmen_user.id
      }

      @contact_with_work_phone = {
        :name => Faker::Name.first_name,
        :surname => Faker::Name.last_name,
        :phone_number_attributes => {
          :name => "work",
          :phone => Faker::PhoneNumber.phone_number
        }}.merge(@defaults)

      @client_with_work_phone = {
        :company_name => Faker::Company.suffix,
        :phone_number_attributes => {
          :name => "work",
          :phone => Faker::PhoneNumber.phone_number
        }}.merge(@defaults)

      @valid_parameters = {
        :name => Faker::Name.first_name,
        :surname => Faker::Name.last_name,
        :patronymic => 'Fucker',
        :common_email => 'fucker@fuckyeah.fuck',
        :company_name => Faker::Company.suffix,
        :phone_number_attributes => {
          :name => "work",
          :phone => Faker::PhoneNumber.phone_number
        }}.merge(@defaults)

      @blank_phone_number = {
        :name => Faker::Name.first_name,
        :surname => Faker::Name.last_name,
        :company_name => Faker::Company.suffix,
        :phone_number_attributes => {
          :name => "work",
          :phone => ""
        }}.merge(@defaults)
    end

    describe 'POST create' do
      before { lead_parameters }

      describe 'with valid parameters' do
        before { post :create, :lead => @valid_parameters }

        it 'should create new lead' do
          assigns(:lead).company_name.should == @valid_parameters[:company_name]
          assigns(:lead).phone_number.phone.should == @valid_parameters[:phone_number_attributes][:phone]
        end
      end

      #TODO: Remove this if it's not more actual.
      pending 'with blank phone number' do
        before { post :create, :lead => @blank_phone_number }

        # NOTE: it can't be done w/ standard validation?

        it 'should redirect to leads list' do
          response.should redirect_to("/leads")
        end

        it 'should create new lead' do
          assigns(:lead).company_name.should == @blank_phone_number[:company_name] # just to test a field
        end
      end
    end # POST create


    describe "POST update" do
      before do
        request.env["HTTP_REFERER"] = "/leads/#{ Lead.first.id }"
        post :update, :id => Lead.first.id, :lead => @valid_parameters
        lead_parameters
      end

      it "should redirect to lead page" do
        response.should redirect_to("/leads/#{Lead.first.id}")
      end

      # pending "with todo notes"
    end # POST update

    describe "POST update, convert to client button pressed" do
      before do
        request.env["HTTP_REFERER"] = "/leads/#{ Lead.first.id }"
        post :update, :id => Lead.first.id, :lead => @valid_parameters, :convert_client => true
      end

      it "should redirect to create_client from lead" do
        response.should redirect_to("/leads/#{Lead.first.id}/create_client")
      end
    end # POST update, with convert

    describe "POST update, convert to contact button pressed" do
      before do
        request.env["HTTP_REFERER"] = "/leads/#{ Lead.first.id }"
        post :update, :id => Lead.first.id, :lead => @valid_parameters, :convert_contact => true
      end

      it "should redirect to create_client from lead" do
        response.should redirect_to("/leads/#{Lead.first.id}/create_contact")
      end
    end # POST update, with convert

    pending "POST lose" do
      before do
        post :lose, :id => Lead.first.id, :lose => { :reason => "Falled down" }
      end

      it "should make a lead lost" do
        lead = assigns(:lead)
        lead.reload
        lead.status.should == "lost"
      end

      it "should redirect to leads list" do
        response.should redirect_to("/leads")
      end
    end # GET new
  end

  context 'for admin' do
    before do
      login_devmen_user(devmen_admin)
      stub_request_subdomain
    end

    it_should_behave_like 'user can view index'

    describe 'GET new' do
      before { get :new }

      it_should_behave_like 'devmen users new'

      it 'builds lead with user_id == devmen_admin.id' do
        assigns(:lead).user_id.should == devmen_admin.id
      end
    end
  end
end
