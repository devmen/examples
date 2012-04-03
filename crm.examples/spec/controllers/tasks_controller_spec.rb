# encoding: utf-8
require 'spec_helper'

describe TasksController do
  let!(:devmen_org ) { Organization.make!(:name => 'devmen') }
  let!(:devmen_user) { User.make!(:email => 'devmen@devmen.com', :role => 'sales_head',
                                 :organization => devmen_org).tap { |user| user.confirm! } }
  let!(:devmen_admin) { User.make!(:email => 'admin@devmen.com',
                                 :organization => devmen_org, :role => 'administrator').tap { |user| user.confirm! } }
  let!(:task_normal){ Task.make!(:organization => devmen_org, :user => devmen_user)}
  let!(:task_deleted){ Task.make!(:organization => devmen_org, :user => devmen_user, :deleted_at => Time.now, :status => 'deleted')}

  def add_todo
    task_normal.todo_tasks <<  TodoTask.new(:description => 'Test')
  end

  shared_examples_for 'user can GET action (tasks)' do
    describe 'new' do
      before { get :new }

      it_should_behave_like 'displays'

      it 'should render tasks/new template' do
        response.should render_template('tasks/new')
      end
    end

    describe 'show' do
      before { get :show, :id => task_normal.id }

      it_should_behave_like 'displays'

      it 'should render tasks/show template' do
        response.should render_template('tasks/show')
      end

      it 'should contain @task object' do
        assigns[:task].id.should == task_normal.id
      end
    end
  end

  describe 'for user' do
    before do
      stub_current_user(devmen_user)
      add_todo

      @source_file_path = File.join(Rails.root, 'spec', 'wassup.doc')
      @target_file_path = File.join(Rails.root, 'public', 'uploads', 'task', 'attachment', task_normal.id.to_s, 'wassup.doc')
      create_test_file(@source_file_path)

      @create_params = {"task" => {"title"=>"Test Maza Fuka", "status"=>"new", "start_date"=>"01.06.2011 00:00", "end_date"=>"26.06.2011 00:00", "content"=>"I'll kill you.", "user_id"=>devmen_user.id, "time_zone"=>"International Date Line West"}}
    end

    after do
      File.delete(@source_file_path) if File.exists?(@source_file_path)
      File.delete(@target_file_path) if File.exists?(@target_file_path)
    end

    it_should_behave_like 'user can GET action (tasks)'

    describe 'index' do
      before { get :index }

      it_should_behave_like 'displays'

      it 'should render tasks/index template' do
        response.should render_template('tasks/index')
      end

      it 'should contain 1 task (without deleted)' do
        assigns[:tasks].count.should == 1
      end
    end

    describe 'update' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/tasks/#{ task_normal.id }"
      end

      it 'should closed all todos' do
        put :update, { :id => task_normal.id, :task=> { :status => 'closed' } }

        task_normal.todo_tasks.first.done.should be(true)
      end

      it 'should upload file' do
        put :update, { :id => task_normal.id, :task=> { :attachment => fixture_file_upload(@source_file_path) } }

        File.exists?(@target_file_path).should be(true)
      end

      it 'should delete uploaded file' do
        put :update, { :id => task_normal.id, :task=> { :attachment => fixture_file_upload(@source_file_path) } }
        #File.exists?(@target_file_path).should be(true)
        put :update, { :id => task_normal.id, :task=> { :remove_attachment => true} }
        File.exists?(@target_file_path).should_not be(true)
      end
    end

    describe 'destroy' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/tasks/#{ task_normal.id }"
        delete :destroy, :id => task_normal.id
      end

      it 'should be marked for delete' do
        task_normal.reload.deleted?.should be(true)
        response.should redirect_to('/tasks')
      end

      it 'should not be deleted' do
        delete :destroy, :id => task_normal.id
        response.should redirect_to('/tasks')
        Task.last.should_not be(nil)
      end
    end

    describe 'create' do
      it 'should redirect to new task page' do
        post :create, @create_params
        new_task = Task.last
        response.should redirect_to("/tasks/#{new_task.id}")
      end

      it 'should create 1 more task object into db' do
        lambda { post :create, @create_params }.should change{ Task.count }.by(1)
      end
    end

    describe 'update' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/tasks/#{ task_normal.id }"
        put :update, :id => task_normal.id, :task => {:title => 'Suck'}
      end

      it 'should redirect to updated task page' do
        response.should redirect_to("/tasks/#{task_normal.id}")
      end

      it 'should update title' do
        task_normal.reload.title.should == 'Suck'
      end
    end
  end

  context 'for admin' do
    before do
      stub_current_user(devmen_admin)
      add_todo
    end

    it_should_behave_like 'user can GET action (tasks)'

    describe 'destroy' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/tasks/#{ task_normal.id }"
        delete :destroy, :id => task_normal.id
      end
      it 'should be marked for delete' do
        task_normal.reload.deleted?.should be(true)
        response.should redirect_to('/tasks')
      end
      it 'should be deleted' do
        delete :destroy, :id => task_normal.id
        Task.all.should_not include(task_normal)
      end
    end

    describe 'index' do
      before { get :index }

      it_should_behave_like 'displays'

      it 'should render tasks/index template' do
        response.should render_template('tasks/index')
      end

      it 'should contain 2 tasks (with deleted)' do
        assigns[:tasks].count.should == 2
      end
    end
  end
end

