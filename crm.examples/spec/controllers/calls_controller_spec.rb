require 'spec_helper'

describe CallsController do
  let!(:devmen_org ) { Organization.make!(:name => 'devmen') }
  let!(:devmen_user) { User.make!(:email => 'devmen@devmen.com', :role => 'sales_head',
                                 :organization => devmen_org).tap { |user| user.confirm! } }
  let!(:devmen_admin) { User.make!(:email => 'admin@devmen.com',
                                 :organization => devmen_org, :role => 'administrator').tap { |user| user.confirm! } }
  let!(:call_normal){ Call.make!(:organization => devmen_org, :user => devmen_user)}
  let!(:call_deleted){ Call.make!(:organization => devmen_org, :user => devmen_user, :deleted_at => Time.now, :status => 'deleted')}

  let!(:client){ Client.make!(:organization => devmen_org)}
  let!(:closed_task){ Task.make!(:taskable => client, :status => 'closed', :user => devmen_user)}
  let!(:active_task){ Task.make!(:taskable => client, :status => 'active', :user => devmen_user)}
  let!(:new_task){ Task.make!(:taskable => client, :status => 'new', :user => devmen_user)}

  let!(:planned_meeting){ Meeting.make!(:meetable => client, :status => 'planned', :user => devmen_user)}
  let!(:took_place_meeting){ Meeting.make!(:meetable => client, :status => 'took_place', :user => devmen_user)}
  let!(:canceled_meeting){ Meeting.make!(:meetable => client, :status => 'canceled', :user => devmen_user)}

  let!(:planned_call){ Call.make!(:callable => client, :status => 'planned', :user => devmen_user)}
  let!(:took_place_call){ Call.make!(:callable => client, :status => 'took_place', :user => devmen_user)}
  let!(:canceled_call){ Call.make!(:callable => client, :status => 'canceled', :user => devmen_user)}

  def add_todo
    call_normal.todo_tasks <<  TodoTask.new(:description => 'Test')
  end

  shared_examples 'user can GET action (calls)' do
    describe 'new' do
      before { get :new }

      it_should_behave_like 'displays'

      it 'should render calls/new template' do
        response.should render_template('calls/new')
      end
    end

    describe 'show' do
      before { get :show, :id => call_normal.id }

      it_should_behave_like 'displays'

      it 'should render calls/show template' do
        response.should render_template('calls/show')
      end

      it "should contain @call object" do
        assigns[:call].id.should == call_normal.id
      end
    end

    describe 'ajax request events for call' do
      before do
        get :new
        xhr :get, :event_list, { :callable_id => client.id, :callable_type => client.class.to_s}
      end

      it 'should return list' do
        assigns(:events).should_not be_nil
      end

      it 'list should include right tasks' do
        assigns(:events).should include(new_task)
        assigns(:events).should include(active_task)
        assigns(:events).should_not include(closed_task)
      end

      it 'list should include right meetings' do
        assigns(:events).should include(planned_meeting)
        assigns(:events).should_not include(took_place_meeting)
        assigns(:events).should_not include(canceled_meeting)
      end

      it 'list should include right calls' do
        assigns(:events).should include(planned_call)
        assigns(:events).should_not include(took_place_call)
        assigns(:events).should_not include(canceled_call)
      end
    end
  end

  describe 'for user' do
    before do
      stub_current_user(devmen_user)
      add_todo

      @source_file_path = File.join(Rails.root, 'spec', 'wassup.doc')
      @target_file_path = File.join(Rails.root, 'public', 'uploads', 'call', 'attachment', call_normal.id.to_s, 'wassup.doc')
      create_test_file(@source_file_path)

      @create_params = {"call" => {"title"=>"Test Maza Fuka", "status"=>"new", "start_datetime"=>"01.06.2011 00:00", "note"=>"I'll kill you.", "user_id"=>devmen_user.id, "time_zone"=>"International Date Line West"}}
    end

    after do
      File.delete(@source_file_path) if File.exists?(@source_file_path)
      File.delete(@target_file_path) if File.exists?(@target_file_path)
    end

    it_should_behave_like 'user can GET action (calls)'

    describe 'index' do
      before { get :index }

      it_should_behave_like 'displays'

      it 'should render calls/index template' do
        response.should render_template('calls/index')
      end

      it 'should contain 1 call (without deleted)' do
        assigns[:calls].count.should == 1
      end
    end

    describe 'update' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/calls/#{ call_normal.id }"
      end

      pending 'should closed all todos' do
        put :update, { :id => call_normal.id, :call=> { :status => 'closed' } }
        call_normal.todo_tasks.first.done.should be(true)
      end

      it 'should upload file' do
        put :update, { :id => call_normal.id, :call=> { :attachment => fixture_file_upload(@source_file_path) } }
        File.exists?(@target_file_path).should be(true)
      end

      it 'should delete uploaded file' do
        put :update, { :id => call_normal.id, :call=> { :attachment => fixture_file_upload(@source_file_path) } }
        #File.exists?(@target_file_path).should be(true)
        put :update, { :id => call_normal.id, :call=> { :remove_attachment => true} }
        File.exists?(@target_file_path).should_not be(true)
      end
    end

    describe 'destroy' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/calls/#{ call_normal.id }"
        delete :destroy, :id => call_normal.id
      end

      it 'should be marked for delete' do
        call_normal.reload.deleted?.should be(true)
        response.should redirect_to('/calls')
      end

      it 'should not be deleted' do
        delete :destroy, :id => call_normal.id
        response.should redirect_to('/calls')
        Call.last.should_not be(nil)
      end
    end

    describe 'create' do
      it 'should redirect to new call page' do
        post :create, @create_params
        new_call = Call.last
        response.should redirect_to("/calls/#{new_call.id}")
      end

      it 'should create 1 more call object into db' do
        lambda { post :create, @create_params }.should change{ Call.count }.by(1)
      end
    end

    describe 'update' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/calls/#{ call_normal.id }"
        put :update, :id => call_normal.id, :call => {:title => 'Suck'}
      end

      it 'should redirect to updated call page' do
        response.should redirect_to("/calls/#{call_normal.id}")
      end

      it 'should update title' do
        call_normal.reload.title.should == 'Suck'
      end
    end
  end

  context 'for admin' do
    before do
      stub_current_user(devmen_admin)
      add_todo
    end

    it_should_behave_like 'user can GET action (calls)'

    describe 'destroy' do
      before(:each) do
        request.env["HTTP_REFERER"] = "/calls/#{ call_normal.id }"
        delete :destroy, :id => call_normal.id
      end
      it 'should be marked for delete' do
        call_normal.reload.deleted?.should be(true)
        response.should redirect_to('/calls')
      end
      it 'should be deleted' do
        delete :destroy, :id => call_normal.id
        Call.all.should_not include(call_normal)
      end
    end

    describe 'index' do
      before { get :index }

      it_should_behave_like 'displays'

      it 'should render calls/index template' do
        response.should render_template('calls/index')
      end

      it 'should contain 2 calls (with deleted)' do
        assigns[:calls].count.should == 5
      end
    end
  end
end

