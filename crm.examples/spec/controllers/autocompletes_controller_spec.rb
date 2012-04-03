require 'spec_helper'

describe AutocompletesController do
  let!(:org)  { Organization.make! }
  let!(:user) { User.make!(:organization => org, :position => 'position').tap { |user| user.confirm! } }
  let!(:client)  { Client.make!(:organization => org,
                                :user => user,
                                :short_name => "OOO Test",
                                :full_name => "OOO Plast Test") }
  let!(:contact) { Contact.make!(:user_id => user.id,
                                 :client => client,
                                 :surname => "Gladstone",
                                 :name => "John",
                                 :patronymic => "Johnson" ) }

  before do
    controller.stub!(:current_user).and_return(user)
  end

  it "should return json from new" do
    get :new, :term => "OOO", :format => :json
    response.body.should eq("[{\"label\":\"#{client.full_name}\",\"value\":\"#{client.full_name}\",\"id\":#{client.id},\"type\":\"Client\"}]")
  end

  it "should return json from client" do
    get :client, :id => client.id, :term => "John", :format => :json
    response.body.should eq("[{\"label\":\"#{contact.surname} #{contact.name} #{contact.patronymic}\",\"value\":\"#{contact.surname} #{contact.name} #{contact.patronymic}\",\"id\":#{contact.id},\"type\":\"Contact\"}]")
  end

end

