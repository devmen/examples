# -*- encoding : utf-8 -*-
require 'spec_helper'

shared_examples_for 'signed in user manage questions' do
  describe 'GET index' do
    def do_get
      get :index
    end

    before(:each) do
      do_get
    end

    it 'should render questions/index template' do
      response.should render_template('questions/index')
    end

    it 'should be successful' do
      response.should be_success
    end

    it 'should contain some questions objects' do
      assigns[:questions].should_not be_blank
    end
  end

  describe 'GET show' do
    def do_get(opts={})
      get :show, :id => opts[:id]
    end

    it 'should be success' do
      do_get(:id => @question.id)
      response.should be_success
    end
  end

  describe 'POST subscribe' do
    def do_post
      post :subscribe, :id => @question.id
    end

    before(:each) do
      request.env['HTTP_REFERER'] = '/'
      do_post
    end

    it 'should redirect_to back' do
      response.should redirect_to('/')
    end

    it 'should really subscribe to question' do
      @question.reload.subscribes.should_not be_blank
    end
  end

  describe 'POST unsubscribe' do
    def do_post
      post :unsubscribe, :id => @question.id
    end

    before(:each) do
      request.env['HTTP_REFERER'] = '/'
      FactoryGirl.create(:subscribe, :user_id => @user.id, :subscribeable => @question)
      do_post
    end

    it 'should redirect_to back' do
      response.should redirect_to('/')
    end

    it 'should really unsubscribe from question' do
      @question.reload.subscribes.should be_blank
    end
  end

  describe 'GET new' do
    def do_get
      get :new
    end

    it 'should be success' do
      do_get
      response.should be_success
    end

    it 'should render /questions/new template' do
      do_get
      response.should render_template('questions/new')
    end
  end

  describe 'POST create' do
    def do_post
      post :create, :question => {:user_id => @user.id, :title => 'Hello!', :body => 'What\'s up man??', :category_id => @category.id}
    end

    it 'should be success' do
      do_post
      response.status.should equal 302
    end

    it 'should add question' do
      lambda { do_post }.should change{ Question.count }.by(1)
    end
  end
end


describe QuestionsController do
  let(:simple_user) { FactoryGirl.create(:user) }
  let(:author_user) { FactoryGirl.create(:author_user) }
  let(:admin) { FactoryGirl.create(:admin_user) }

  def create_questions
    @category = FactoryGirl.create(:category, :name => 'Category')
    @question = FactoryGirl.create(:question, :user_id => author_user.id, :category => @category)
    @published_on_main_question = FactoryGirl.create(:question, :published_on_main => true)
  end

  before(:each) do
    set_current_domain_to("smartsourcing.local", 3000)
    create_questions
    stub(Question).search(anything, anything).returns { Question.paginate({:page => 1}) }
  end

  context 'for simple user' do
    before(:each) do
      @user = simple_user
      set_session_for(@user)
    end

    it_should_behave_like 'signed in user manage questions'

    describe 'PUT update' do
      def do_put
        put :update, :id => @question.id, :question => {:title => 'Updated!'}
      end

      before(:each) do
        do_put
      end

      it 'should not be success' do
        response.should_not be_success
      end

      it 'should not change question title' do
        @question.reload.title.should_not == 'Updated!'
      end
    end

    describe 'DELETE destroy' do
      def do_delete
        delete :destroy, :id => @question.id
      end

      before(:each) do
        set_session_for(@user)
      end

      it 'should not be success' do
        do_delete
        response.should_not be_success
      end

      it 'should not change questions count down by 1' do
        lambda { do_delete }.should_not change{ Question.count }.by(-1)
      end
    end
  end

  context 'for author user' do
    before(:each) do
      @user = author_user
      set_session_for(@user)
    end

    it_should_behave_like 'signed in user manage questions'

    describe 'PUT update' do
      def do_put
        put :update, :id => @question.id, :question => {:title => 'Updated!'}
      end

      before(:each) do
        do_put
      end

      it 'should be success' do
        response.status.should equal 302
      end

      it 'should change question title' do
        @question.reload.title.should == 'Updated!'
      end
    end

    describe 'DELETE destroy' do
      def do_delete
        delete :destroy, :id => @question.id
      end

      before(:each) do
        question_author = User.find(@question.user_id)
        set_session_for(question_author)
      end

      it 'should be success' do
        do_delete
        response.should redirect_to('/questions')
      end

      it 'should change questions count down by 1' do
        lambda { do_delete }.should change{ Question.count }.by(-1)
      end
    end
  end

  context 'for admin' do
    before(:each) do
      @user = admin
      set_session_for(@user)
    end

    it_should_behave_like 'signed in user manage questions'

    describe 'PUT update' do
      def do_put
        put :update, :id => @question.id, :question => {:title => 'Updated!'}
      end

      before(:each) do
        do_put
      end

      it 'should be success' do
        response.status.should equal 302
      end

      it 'should change question title' do
        @question.reload.title.should == 'Updated!'
      end
    end

    describe 'DELETE destroy' do
      def do_delete
        delete :destroy, :id => @question.id
      end

      before(:each) do
        question_author = User.find(@question.user_id)
        set_session_for(question_author)
      end

      it 'should be success' do
        do_delete
        response.should redirect_to('/questions')
      end

      it 'should change questions count down by 1' do
        lambda { do_delete }.should change{ Question.count }.by(-1)
      end
    end
  end

  context 'for not signed id user' do
    describe 'GET show' do
      def do_get(opts={})
        get :show, :id => opts[:id]
      end

      it 'should be success' do
        do_get(:id => @question.id)
        response.should be_success
      end
    end

    describe 'GET index' do
      def do_get
        get :index
      end

      before(:each) do
        do_get
      end

      it 'should render questions/index template' do
        response.should render_template('questions/index')
      end

      it 'should be successful' do
        response.should be_success
      end

      it 'should contain some questions objects' do
        assigns[:questions].should_not be_blank
      end
    end

    describe 'POST create' do
      def do_post
        post :create, :question => {:user_id => simple_user.id, :title => 'Hello!', :body => 'What\'s up man??', :category_id => @category.id}
      end

      it 'should not be success' do
        do_post
        response.should_not be_success
      end

      it 'should not add question' do
        lambda { do_post }.should_not change{ Question.count }
      end
    end

    describe 'PUT update' do
      def do_put
        put :update, :id => @question.id, :question => {:title => 'Updated!'}
      end

      before(:each) do
        do_put
      end

      it 'should not be success' do
        response.should_not be_success
      end

      it 'should not change question title' do
        @question.reload.title.should_not == 'Updated!'
      end
    end

    describe 'DELETE destroy' do
      def do_delete
        delete :destroy, :id => @question.id
      end

      it 'should not be success' do
        do_delete
        response.should_not be_success
      end

      it 'should not change questions count down by 1' do
        lambda { do_delete }.should_not change{ Question.count }
      end
    end

  end

end
