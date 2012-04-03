require 'spec_helper'

describe ActivityFeedsController do
  let!(:devmen_org ) { Organization.make!(:name => 'devmen') }
  let!(:devmen_admin) { User.make!(:email => 'devmen@devmen.com', :role => 'administrator',
                                 :organization => devmen_org).tap { |user| user.confirm! } }
  let!(:devmen_manager) { User.make!(:email => 'another@another.com', :role => 'sales_manager',
                                 :organization => devmen_org).tap { |user| user.confirm! } }


  let!(:client){ Client.make!(:organization => devmen_org)}

  let!(:closed_task){ Task.make!(:taskable => client, :status => 'closed', :user => devmen_admin, :organization => devmen_org)}
  let!(:active_task){ Task.make!(:taskable => client, :status => 'active', :user => devmen_admin, :organization => devmen_org)}
  let!(:new_task){ Task.make!(:taskable => client, :status => 'new', :user => devmen_admin, :organization => devmen_org)}

  let!(:planned_meeting){ Meeting.make!(:meetable => client, :status => 'planned', :user => devmen_manager, :organization => devmen_org)}
  let!(:took_place_meeting){ Meeting.make!(:meetable => client, :status => 'took_place', :user => devmen_manager, :organization => devmen_org)}
  let!(:canceled_meeting){ Meeting.make!(:meetable => client, :status => 'canceled', :user => devmen_manager, :organization => devmen_org)}

  let!(:planned_call){ Call.make!(:callable => client, :status => 'planned', :user => devmen_admin, :organization => devmen_org)}
  let!(:took_place_call){ Call.make!(:callable => client, :status => 'took_place', :user => devmen_admin, :organization => devmen_org)}
  let!(:canceled_call){ Call.make!(:callable => client, :status => 'canceled', :user => devmen_admin, :organization => devmen_org)}

  context 'for admin' do
    before {
      stub_current_user(devmen_admin)
    }

    describe 'index' do
      before { get :index }

      it_should_behave_like 'displays'

      it 'should render activity_feeds/index template' do
        response.should render_template('activity_feeds/index')
      end

      pending 'collection should be' do
        assigns(:activity_feeds).should_not be_blank
      end
    end

    describe 'more' do
      before { get :more }

      it 'should render activity_feeds/_more template' do
        response.should render_template('activity_feeds/_more')
      end

      it 'collection should be' do
        assigns(:activity_feeds).should_not be_blank
      end

      # Admin can see deleted objects + objects of another users.
      it 'should have 9 objects' do
        assigns(:activity_feeds).count.should == 9
      end
    end
  end

  context 'for manager' do
    before {
      stub_current_user(devmen_manager)
    }

    describe 'index' do
      before { get :index }

      it_should_behave_like 'displays'

      it 'should render activity_feeds/index template' do
        response.should render_template('activity_feeds/index')
      end

      pending 'collection should be' do
        assigns(:activity_feeds).should_not be_blank
      end
    end

    describe 'more' do
      before { get :more }

      it 'should render activity_feeds/index template' do
        response.should render_template('activity_feeds/_more')
      end

      it 'collection should be' do
        assigns(:activity_feeds).should_not be_blank
      end

      # Admin can see deleted objects + objects of another users.
      it 'should have 3 objects' do
        assigns(:activity_feeds).count.should == 3
      end
    end
  end
end

