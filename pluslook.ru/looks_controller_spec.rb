require 'spec_helper'

describe LooksController do
  let(:look) { stub_look_downloads; Factory.create(:look) }

  before(:each) do
    @tested_object = look
    @extended_params = {:look => {:state => 'blocked'}}
  end

  context 'as guest' do
    it_should_behave_like 'can read'
    it_should_behave_like 'can not update'
    it_should_behave_like 'can not destroy'
  end
  
  context 'as user' do
    let(:user) { Factory.create(:user) }
    before(:each) { set_session_for user }
  
    it_should_behave_like 'can read'
    it_should_behave_like 'can not update'
    it_should_behave_like 'can not destroy'
  end
  
  context 'as admin' do
    let(:admin) { Factory.create(:admin) }
    before(:each) { set_session_for admin }
  
    it_should_behave_like 'can read'
    it_should_behave_like 'can update'
    it_should_behave_like 'can destroy'
  end

  context 'filters' do
    let(:look2) { stub_look_downloads; Factory.create(:look) }

    context 'blocked' do
      let(:look3) { stub_look_downloads; Factory.create(:blocked_look) }
      before { get :index }
      it { assigns(:looks).should include(look) }
      it { assigns(:looks).should_not include(look3) }
    end

    context 'by categories' do
      context 'with one category' do
        before { get :index, :categories => [look.site.category_id] }
        it { assigns(:looks).should_not include(look) }
        it { assigns(:looks).should include(look2) }
      end
      context 'with two categories' do
        before { get :index, :categories => [look.site.category_id, look2.site.category_id] }
        it { assigns(:looks).should_not include(look) }
        it { assigns(:looks).should_not include(look2) }
      end
    end

    context 'by month' do
      let(:look3) { stub_look_downloads; Factory.create(:look, :created_at => Time.current - 1.month) }
      before { get :index, :month => Time.current.month }
      it { assigns(:looks).should include(look) }
      it { assigns(:looks).should_not include(look3) }
    end

    context 'by album' do
      let(:album) { Factory.create(:album) }
      before do
        album.looks << look
        get :index, :album_id => album.id
      end
      it { assigns(:looks).should include(look) }
      it { assigns(:looks).should_not include(look2) }
    end

    context 'by best mode' do
      before do
        Factory.create(:voting, :voteable => look)
        get :index, :mode => 'best'
      end
      it { assigns(:looks).should include(look) }
      it { assigns(:looks).should_not include(look2) }
    end

    context 'by my mode' do
      let(:look3) { stub_look_downloads; Factory.create(:look) }
      before do
        set_session_for Factory.create(:user)
        look.site.subscribers << controller.current_user
        friend = Factory.create(:user)
        controller.current_user.own_friends << friend
        Factory.create(:voting, :voteable => look2, :voter => friend)
        get :index, :mode => 'my'
      end
      it { assigns(:looks).should include(look) }
      it { assigns(:looks).should include(look2) }
      it { assigns(:looks).should_not include(look3) }
    end

    context 'my best mode' do
      let(:look3) { stub_look_downloads; Factory.create(:look) }
      before do
        set_session_for Factory.create(:user)
        look.site.subscribers << controller.current_user
        friend = Factory.create(:user)
        controller.current_user.own_friends << friend
        Factory.create(:voting, :voteable => look2, :voter => friend)
        get :index, :mode => 'my_best'
      end
      it { assigns(:looks).should_not include(look) }
      it { assigns(:looks).should include(look2) }
      it { assigns(:looks).should_not include(look3) }
    end
  end
end
