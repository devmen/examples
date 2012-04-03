require 'spec_helper'

describe EmailersController do
  let!(:devmen_org ) { Organization.make!(:name => 'devmen') }
  let!(:devmen_user) { User.make!(:email => 'devmen@devmen.com',
                                 :organization => devmen_org).tap { |user| user.confirm! } }

  before do
    controller.stub!(:current_user).and_return(devmen_user)

    @client = Client.make!(:organization => devmen_org, :user_id => devmen_user.id)
    devmen_org.clients << @client
    @client.email_references <<  EmailReference.new({:email => "email@test.lo"})
  end

  describe "crud spec" do

    it "save email" do
      post :create, :client_id => @client.id, :emailer => {:email_to => @client.email_references.first.email, :title => "Test Title", :body => Faker::Lorem.paragraph, :sign => "Ivanov <iv@a.com>" }

      #client.emailers.count.should == 1
      response.should redirect_to("/clients/#{@client.id}/emailers/#{@client.emailers.first.id}")
    end

    describe "update and sending emailer" do

      before(:each) do
        @test_title = "Test Title 1"
        @emailer = Emailer.new({:email_to => @client.email_references.first.email, :title =>@test_title , :body => Faker::Lorem.paragraph, :sign => "Ivanov <iv@a.com>" })
        @emailer.user = devmen_user
        @client.emailers << @emailer
      end

      it "should update emailer title" do
        request.env["HTTP_REFERER"] = "/clients/#{@client.id}/emailers/1"
        put :update, :client_id => @client.id, :id => 1, :emailer => {:email_to => @client.email_references.first.email, :title => @test_title, :body => Faker::Lorem.paragraph, :sign => "Ivanov <iv@a.com>" }

        @client.emailers.first.title.should == @test_title
        response.should redirect_to("/clients/#{@client.id}/emailers/1")
      end

      it "should redirect to updated emailer page" do
        request.env["HTTP_REFERER"] = "/clients/#{@client.id}/emailers/1"
        put :update, :client_id => @client.id, :id => 1, :emailer => {:email_to => @client.email_references.first.email, :title => @test_title, :body => Faker::Lorem.paragraph, :sign => "Ivanov <iv@a.com>" }

        @client.emailers.first.title.should == @test_title
        response.should redirect_to("/clients/#{@client.id}/emailers/1")
      end

      it "should change status email" do
        request.env["HTTP_REFERER"] = "/clients/1/emailers"
        get :sending, :id=>@client.emailers.first.id

        @client.emailers.first.sent?.should be( true )
      end

      it "should deliver email" do
        request.env["HTTP_REFERER"] = "/clients/1/emailers"
        lambda {
          get :sending, :id=>@client.emailers.first.id
        }.should change(ActionMailer::Base.deliveries, :size).by(1)
      end

      it "should inluce email into delivery" do
        request.env["HTTP_REFERER"] = "/clients/1/emailers"
        get :sending, :id=>@client.emailers.first.id

        last_delivery = ActionMailer::Base.deliveries.last
        last_delivery.to.should include @client.email_references.first.email
      end

    end
  end
end
