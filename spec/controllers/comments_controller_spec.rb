require File.dirname(__FILE__) + '/../spec_helper'
 
describe CommentsController, "as guest" do
  fixtures :all
  render_views
  
  it "index action should render index template" do
    get :index
    response.should render_template(:index)
  end

  it "index action should render index template for rss with xml" do
    get :index, :format => 'rss'
    response.should render_template(:index)
    response.content_type.should == 'application/rss+xml'
    response.should have_selector('title', :content => 'Railscasts Comments')
  end

  it "new action should redirect to root url with flash notice" do
    get :new
    response.should redirect_to(root_url)
    flash[:notice].should_not be_blank
  end

  it "create action should redirect to episode when valid" do
    request.stubs(:remote_ip).returns('ip')
    Comment.any_instance.stubs(:valid?).returns(true)
    post :create, :spam_key => APP_CONFIG['spam_key'], :comment => { :episode_id => Episode.first.id }
    response.should redirect_to(episode_path(Episode.first))
    assigns[:comment].user_ip.should == 'ip'
  end

  it "create action should render new template when model is invalid" do
    Comment.any_instance.stubs(:valid?).returns(false)
    post :create, :spam_key => APP_CONFIG['spam_key']
    response.should render_template(:new)
  end
  
  it "create action should render new template when spam even if model is valid" do
    Comment.any_instance.stubs(:valid?).returns(true)
    Comment.any_instance.stubs(:spam?).returns(true)
    post :create
    response.should render_template(:new)
  end

  it "create action should render new template when preview button is pressed" do
    Comment.any_instance.stubs(:valid?).returns(true)
    post :create, :spam_key => APP_CONFIG['spam_key'], :preview_button => true
    response.should render_template(:new)
    flash[:error].should be_nil
  end
  
  it "create action should render new template when fake email filled even if model is valid" do
    Comment.any_instance.stubs(:valid?).returns(true)
    post :create, :email => 'spammer', :spam_key => APP_CONFIG['spam_key']
    response.should render_template(:new)
  end
  
  it "create action should submit new comment when answering spam question properly" do
    spam_question = SpamQuestion.create!(:question => "My name?", :answer => "Ryan")
    session[:spam_question_id] = spam_question.id
    Comment.any_instance.stubs(:valid?).returns(true)
    post :create, :spam_key => APP_CONFIG['spam_key'], :spam_answer => "ryan bates", :comment => { :episode_id => Episode.first.id }
    response.should redirect_to(episode_path(Episode.first))
    session[:spam_question_id].should be_nil
  end
  
  it "create action should not submit new comment when answering spam question incorrectly" do
    spam_question = SpamQuestion.create!(:question => "My name?", :answer => "Ryan")
    session[:spam_question_id] = spam_question.id
    Comment.any_instance.stubs(:valid?).returns(true)
    post :create, :spam_key => APP_CONFIG['spam_key'], :spam_answer => "joe", :comment => { :episode_id => Episode.first.id }
    response.should render_template(:new)
  end

  it "create action should should display spam question if it looks spammish" do
    SpamCheck.delete_all
    SpamQuestion.delete_all
    SpamCheck.create!(:regexp => "ugg", :weight => 20)
    spam_question = SpamQuestion.create!(:question => "My name?", :answer => "Ryan")
    Comment.any_instance.stubs(:valid?).returns(true)
    post :create, :spam_key => APP_CONFIG['spam_key'], :comment => { :content => "ugg" }
    response.should render_template(:new)
    session[:spam_question_id].should == spam_question.id
  end

  it "create action should should reject comment completely when it looks like obvious spam" do
    SpamCheck.delete_all
    SpamQuestion.delete_all
    SpamCheck.create!(:regexp => "ugg", :weight => 60)
    Comment.any_instance.stubs(:valid?).returns(true)
    post :create, :spam_key => APP_CONFIG['spam_key'], :comment => { :content => "ugg" }
    response.should render_template(:new)
    session[:spam_question_id].should be_nil
  end
  
  it_should_require_admin_for_actions :edit, :update, :destroy
end

describe CommentsController, "as admin" do
  fixtures :all
  render_views
  
  before(:each) do
    session[:admin] = true
  end
  
  it "edit action should render edit template" do
    get :edit, :id => Comment.first
    response.should render_template(:edit)
  end

  it "update action should render edit template when model is invalid" do
    Comment.any_instance.stubs(:valid?).returns(false)
    put :update, :id => Comment.first
    response.should render_template(:edit)
  end

  it "update action should redirect to episode page when model is valid" do
    Comment.any_instance.stubs(:valid?).returns(true)
    put :update, :id => Comment.first, :comment => { :episode_id => Episode.first.id }
    response.should redirect_to(episode_path(Episode.first))
  end

  it "destroy action should destroy model and redirect to index action" do
    comment = Comment.first
    delete :destroy, :id => comment
    response.should redirect_to(comments_path)
    Comment.exists?(comment.id).should be_false
  end
  
  it "destroy action should render template on javascript request" do
    post :destroy, :id => Comment.first, :format => 'js'
    response.should render_template(:destroy)
  end
end
