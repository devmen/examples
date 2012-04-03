# -*- encoding : utf-8 -*-
require 'spec_helper'
describe MeetingsController do
  let!(:devmen_org ) { Organization.make!(:name => 'devmen') }
  let!(:devmen_user) { User.make!(:email => 'devmen@devmen.com', :role => 'sales_head',
                                 :organization => devmen_org).tap { |user| user.confirm! } }
  let!(:devmen_admin) { User.make!(:email => 'admin@devmen.com', :role => 'administrator',
                                 :organization => devmen_org).tap { |user| user.confirm! } }

  let!(:meeting){ Meeting.make!(:user => devmen_user, :organization => devmen_org)}
  before do
    meeting.todo_tasks <<  TodoTask.new(:description => "Test")

    @create_params = {:meeting => {"title"=>"Fuck you", "status"=>"planned", "start_datetime"=>"01.06.2011 00:00", "start_time_zone"=>"International Date Line West", "end_datetime"=>"30.06.2011 00:00", "end_time_zone"=>"International Date Line West", "place"=>"", "agenda"=>"Suck yourself", "user_id"=>devmen_user.id}}
  end

  context 'for user' do
    before do
      controller.stub!(:current_user).and_return(devmen_user)

      @source_file_path = File.join(Rails.root, 'spec', 'wassup.doc')
      @target_file_path = File.join(Rails.root, 'public', 'uploads', 'meeting', 'attachment', meeting.id.to_s, 'wassup.doc')
      create_test_file(@source_file_path)
    end

    after do
      File.delete(@source_file_path) if File.exists?(@source_file_path)
      File.delete(@target_file_path) if File.exists?(@target_file_path)
    end

    describe "update" do
      before(:each) do
        request.env["HTTP_REFERER"] = "/meetings/#{ meeting.id }"
        put :update, { :id => meeting.id, :meeting => {:status => "took_place"} }
      end

      it "should closed all todos" do
        meeting.todo_tasks.first.done.should be(true)
      end

      it 'should redirect to meeting page' do
        response.should redirect_to("/meetings/#{meeting.id}")
      end

      it 'should upload file' do
        put :update, { :id => meeting.id, :meeting=> { :attachment => fixture_file_upload(@source_file_path) } }
        File.exists?(@target_file_path).should be(true)
      end

      it 'should delete uploaded file' do
        put :update, { :id => meeting.id, :meeting=> { :attachment => fixture_file_upload(@source_file_path) } }
        #File.exists?(@target_file_path).should be(true)
        put :update, { :id => meeting.id, :meeting=> { :remove_attachment => true} }
        File.exists?(@target_file_path).should_not be(true)
      end
    end

    describe 'create' do
      it 'should redirect to new meeting page' do
        post :create, @create_params
        new_meeting = Meeting.last
        response.should redirect_to("/meetings/#{new_meeting.id}")
      end

      it 'should create 1 more meeting object into db' do
        lambda { post :create, @create_params }.should change{ Meeting.count }.by(1)
      end
    end

    describe 'destroy' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/meetings/#{ meeting.id }"
      end

      it 'redirect to meetings collection page' do
        delete :destroy, :id => meeting.id
        response.should redirect_to('/meetings')
      end

      it 'should mark meeting object as deleted' do
        lambda { delete :destroy, :id => meeting.id }.should change{ Meeting.deleted.count }.by(+1)
      end
    end

    describe 'index' do
      before(:each) do
        get :index
      end

      it 'should contain some meeting objects' do
        assigns[:meetings].count.should == 1
      end

      it 'should render meetings/index template' do
        response.should render_template('meetings/index')
      end
    end

    describe 'show' do
      before(:each) do
        get :show, :id => meeting.id
      end

      it 'should render meetings/show template' do
        response.should render_template('meetings/show')
      end

      it 'should contain @meeting object' do
        assigns[:meeting].id.should == meeting.id
      end
    end

    describe 'edit' do
      before(:each) do
        get :edit, :id => meeting.id
      end

      #it 'should render meetings/edit template' do
      #  response.should render_template('meetings/edit')
      #end

      it 'should redirect to show action' do
        response.should redirect_to("/meetings/#{meeting.id}")
      end

      #it 'should contain @meeting object' do
      #  assigns[:meeting].id.should == meeting.id
      #end
    end

    describe 'new' do
      before(:each) do
        get :new
      end

      it 'should render meetings/new template' do
        response.should render_template('meetings/new')
      end

      it 'should contain @meeting object' do
        assigns[:meeting].should_not be_blank
      end
    end
  end

  context 'for admin' do
    before(:each) do
      controller.stub!(:current_user).and_return(devmen_admin)
    end

    describe "update (anyones meeting)" do
      before(:each) do
        request.env["HTTP_REFERER"] = "/meetings/#{ meeting.id }"
        put :update, { :id => meeting.id, :meeting => {:status => "took_place"} }
      end

      it "should closed all todos" do
        meeting.todo_tasks.first.done.should be(true)
      end

      it 'should redirect to meeting page' do
        response.should redirect_to("/meetings/#{meeting.id}")
      end
    end

    describe 'destroy (anyones meeting)' do
      before(:each) do
        delete :destroy, :id => meeting.id
      end

      it 'redirect to meetings collection page' do
        response.should redirect_to('/meetings')
      end

      it 'should destroy meeting object from db' do
        lambda { delete :destroy, :id => meeting.id }.should change{ Meeting.count }.by(-1)
      end
    end
  end
end

