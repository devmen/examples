require 'spec_helper'

require 'spec_helper'

describe CustomersFeedsController do
  let!(:devmen_org ) { Organization.make!(:name => 'devmen') }
  let!(:devmen_admin) { User.make!(:email => 'devmen@devmen.com', :role => 'administrator',
                                 :organization => devmen_org).tap { |user| user.confirm! } }
  let!(:devmen_manager) { User.make!(:email => 'another@another.com', :role => 'sales_manager',
                                 :organization => devmen_org).tap { |user| user.confirm! } }

  let!(:client){ Client.make!(:organization => devmen_org, :user => devmen_admin, :is_favourite => true)}
  let!(:lead){ Lead.make!(:organization => devmen_org, :user => devmen_admin)}
  let!(:second_lead){ Lead.make!(:organization => devmen_org, :user => devmen_manager)}
  let!(:deleted_lead){ Lead.make!(:organization => devmen_org, :user => devmen_manager, :status => 'deleted')}

  context 'for admin' do
    before {
      stub_current_user(devmen_admin)
    }

    describe 'more' do
      context 'all' do
        before {
          get :more, :all => 'true'
        }

        it 'should render customers_feeds/_more template' do
          response.should render_template('customers_feeds/_more')
        end

        it "should have some objects into feed" do
          assigns[:customers_feeds].should_not be_blank
        end

        # Admin can see deleted objects + objects of another users.
        it "should have 4 objects into feed" do
          assigns[:customers_feeds].count.should == 4
        end
      end

      context 'favourite' do
        before {
          get :more, :favourite => 'true'
        }

        it 'should render customers_feeds/_more template' do
          response.should render_template('customers_feeds/_more')
        end

        # Admin can see deleted objects + objects of another users.
        it "should have 1 objects into feed" do
          assigns[:customers_feeds].count.should == 1
        end

        it "should have only favourite client into feed" do
          Proc.new { assigns[:customers_feeds].first.customers_feedable_type == 'Client' && assigns[:customers_feeds].first.customers_feedable_id == client.id }.should be_true
        end
      end
    end
  end

  context 'for sales_manager' do
    before {
      stub_current_user(devmen_manager)
    }

    describe 'more' do
      before {
        get :more
      }

      it 'should render customers_feeds/_more template' do
        response.should render_template('customers_feeds/_more')
      end

      it "should have some objects into feed" do
        assigns[:customers_feeds].should_not be_blank
      end

      # Mnaager can not see deleted objects + can not see objects of another users.
      it "should have 1 objects into feed" do
        assigns[:customers_feeds].count.should == 1
      end
    end
  end
end

