require 'spec_helper'
require 'cancan/matchers'

shared_examples "should not be able to" do
  it "create user" do
    should_not be_able_to(:create, User)
  end

  it "update organization" do
    should_not be_able_to(:update, user.organization)
  end
end

shared_examples "should be able to" do
  it "edit own profile" do
    should be_able_to(:update, user)
  end

  context "view" do
    it "users" do
      should be_able_to(:read, User)
    end

    it "organization" do
      #should be_able_to(:read, user.organization)
      should be_able_to(:read, user)
    end

    Ability::RESOURCES.each do |model|
      it "all visible #{model}" do
        should be_able_to(:read, model)
      end
    end

    Ability::ACTIVITIES.each do |model|
      it "own #{model}" do
        should be_able_to(:read, model.send(:make!, :user => user))
      end
    end
  end

  context "create" do
    (Ability::RESOURCES + Ability::ACTIVITIES).each do |model|
      it "#{model}" do
        should be_able_to(:create, model.send(:make!))
      end
    end
  end

  [:update, :destroy].each do |action|
    context "#{action}" do
      (Ability::RESOURCES + Ability::ACTIVITIES).each do |model|
       it "#{model}" do
         should be_able_to(action, model.send(:make!, :user => user))
       end
      end
    end
  end

  context "lose" do
    it "Lead" do
      should be_able_to(:lose, Lead.make!(:user => user))
    end
  end

  context "convert own lead to" do
    context "client" do
      it "Lead" do
        should be_able_to(:create_client, Lead.make!(:user => user))
      end
    end

    context "contact" do
      it "Lead" do
        should be_able_to(:create_contact, Lead.make!(:user => user))
      end
    end
  end
end

describe "Organization administrator" do
  let(:admin) { User.make!(:role => 'administrator') }

  before(:each) do
    Ability.new(admin)
  end

  # TODO: Repair this example!
  pending "should be able to do everything" do
    #should be_able_to(:manage, :all)
    (Ability::RESOURCES + Ability::ACTIVITIES).each do |model|
      should be_able_to(:manage, model.send(:make!, { :organization => admin.organization }))
    end
  end
end

describe "Guest" do
  subject { Ability.new(User.new) }

  it "should not be able to read anything" do
    should_not be_able_to(:read, :all)
  end
end

describe "Sales manager" do
  let(:user) { User.make!(:role => 'sales_manager') }
  subject { Ability.new(user) }

  it "should have editing ability only for own profile" do
    User.make!(5)
    User.accessible_by(subject, :update).should == [user]
  end

  it_behaves_like "should be able to"
  it_behaves_like "should not be able to"

  context "should not be able to" do
    context "view" do
      Ability::ACTIVITIES.each do |model|
        it "foreign #{model}" do
          should_not be_able_to(:read, model.send(:make!))
        end
      end
    end

    [:update, :destroy].each do |action|
      context "#{action}" do
        it "foreign Users" do
          should_not be_able_to(action, User.make!)
        end

        (Ability::RESOURCES + Ability::ACTIVITIES).each do |model|
          it "foreign #{model}" do
            should_not be_able_to(action, model.send(:make!))
          end
        end
      end
    end

    context "manage foreign" do
      let(:client) { Client.make!(:user => User.make!) }

      Ability::NESTED_RESOURCES.each do |model|
        it "nested #{model}" do
          should_not be_able_to(:manage, model.send(:make!, :client => client))
        end
      end

      it "nested Task" do
        should_not be_able_to(:manage, Task.make!(:taskable => client))
      end

      it "nested Meeting" do
        should_not be_able_to(:manage, Meeting.make!(:meetable => client))
      end

      it "nested Emailer" do
        should_not be_able_to(:manage, Emailer.make!(:mailable => client))
      end
    end

    context "convert foreign lead to" do
      context "client" do
        it "Lead" do
          should_not be_able_to(:create_client, Lead.make!)
        end
      end

      context "contact" do
        it "Lead" do
          should_not be_able_to(:create_contact, Lead.make!)
        end
      end
    end
  end
end

describe "Head of sales" do
  let(:user) { User.make!(:role => 'sales_head') }
  subject { Ability.new(user) }

  it_behaves_like "should be able to"

  context "should be able to" do
    it "update other managers" do
      should be_able_to(:update, User.make!(:role => 'sales_manager'))
    end

    [:update, :destroy].each do |action|
      context "#{action}" do
        Ability::RESOURCES.each do |model|
          #TODO: Repair this example!
          pending "foreign #{model}" do
            should be_able_to(action, model.send(:make!))
          end
        end
      end
    end

    context "view" do
      Ability::ACTIVITIES.each do |model|
        it "foreign #{model}" do
          should be_able_to(:read, model.send(:make!))
        end
      end
    end
  end

  #it_behaves_like "should not be able to"

  context "should not be able to" do
    it "update admins" do
      should_not be_able_to(:update, User.make!(:role => 'administrator'))
    end

    it "destroy User" do
      should_not be_able_to(:destroy, User.make!)
    end
  end
end
