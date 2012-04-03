require "spec_helper"

describe "Sending Email" do
  include EmailSpec::Helpers
  include EmailSpec::Matchers


  let!(:devmen_org ) { Organization.make!(:name => 'devmen') }
  let!(:devmen_user) { User.make!(:email => 'devmen@devmen.com',
                                 :organization => devmen_org).tap { |user| user.confirm! } }

  before do
    @client = Client.make!(:organization => devmen_org, :user_id => devmen_user.id)
    devmen_org.clients << @client
    @client.email_references <<  EmailReference.new({:email => "email@test.lo"})
    @test_title = "Test Title 1"
    @emailer = Emailer.new({:email_to => @client.email_references.first.email, :title =>@test_title , :body => Faker::Lorem.paragraph, :sign => "Ivanov <iv@a.com>" })
    @emailer.user = devmen_user
    @client.emailers << @emailer
  end


  subject { AppMailer.mailto(@emailer, devmen_user) }

  it "should be delivered to the email passed in" do
    should deliver_to(@client.emailers.first.email_to)
  end


end
