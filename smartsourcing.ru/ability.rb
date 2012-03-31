# -*- encoding : utf-8 -*-
class Ability
  include CanCan::Ability

  def initialize(user, request)
    user ||= User.new # guest visitor

    # any visitor
    can :show, Page
    can :read, Post, :state => 'published'
    cannot :show, Post, :visibility => 'registered'
    can :search, Post
    can :read, [PostsFeed, MicroPost, Question, Comment]
    can :read, [Company, Project, CompanyService, Order]
    can :read, [Location, Service] if request.xhr? # Category
    can :collective, Blog, :is_collective => true
    can [:show, :register], Event
    # can :create, [Company, Order]

    if user.roles?(:admin) and user.super_admin? # super admin only
      can :manage, :all
    end

    if user.roles?(:admin) and user.admin_communities?(Domain.current_domain) # local admin only
      can :manage, :all
      cannot :manage, [Location, Country, Status, Service, Reference, Setting, Category]
      can :manage, [Setting, Category], :domain => Domain.current_domain
      can :create, Category
      cannot [:destroy, :destroy_with_reason], Order
    end

    if user.roles?(:admin) # all admins
      # Use basic user rights instead
      cannot :read, Message
      cannot :post, Blog
      cannot [:create, :destroy], [Favorite, Draft]
      cannot [:subscribe, :unsubscribe], [Post, MicroPost, Question]
      cannot :publish_on_main, [Post, MicroPost, Question], :published_on_main => true
      cannot :unpublish_from_main, [Post, MicroPost, Question], :published_on_main => false
      cannot [:accept, :reject], Offer
      cannot :close, Order, :state => 'closed'
      # Manage only own files
      cannot :manage, [Ckeditor::AttachmentFile, Ckeditor::Picture]
      can :manage, [Ckeditor::AttachmentFile, Ckeditor::Picture], :user_id => user.id
      # Protection
      cannot :destroy, Template
      cannot :destroy, Setting
      cannot [:create, :edit, :destroy], Navigation, :parent_id => nil
    end

    # even admins can't do this
    cannot :show, Order, :state => 'deleted'

    if user.roles?(:author) # authors
      # can :post, Blog, :blog_users => {:user_id => user.id}
      can :post, Blog, ["blogs.id IN (SELECT blog_id FROM blog_users WHERE user_id = ?)", user.id] do |b|
        b.blog_users.include?(user)
      end
    end

    if user.roles?(:user) # all users
      can [:show, :invite], User
      can [:join_community, :leave_community], User
      can [:update, :edit_skills, :update_skills], User, :id => user.id
      can :manage, [Course, Credential, Institution, Job, Company], :user => {:id => user.id} # not :user_id => user.id because of nested association

      can [:read, :destroy], Message, :sender_id => user.id
      can [:read, :destroy], Message, :recipient_id => user.id
      can :create, Message

      if user.communities?(Domain.current_community) # current community members only
        can :post, Blog, :is_collective => true
        # can :post, Blog, :company => { :company_users => { :user_id => user.id } }
        can :post, Blog, ["blogs.company_id IN (SELECT company_id FROM company_users WHERE user_id = ?)", user.id] do |b|
          b.company_blog? and b.company.company_users.include?(user)
        end

        can :show, Post, :visibility => 'registered'
        can :read, [Post, MicroPost, Question], :user_id => user.id
        can(:create, Post){|p| user.can_create?(p) and (!p.blog or can?(:post, p.blog))}
        can(:create, [MicroPost, Question]) {|mp| user.can_create?(mp)}
        can(:update, Post) do |p|
          @new_blog = Blog.find_by_id request.params[:post].try(:fetch, :blog_id)
          p.user == user and (!@new_blog or can?(:post, @new_blog))
        end
        can [:update, :destroy], [MicroPost, Question], :user_id => user.id        

        can(:create, Comment) {|c| user.can_create?(c)}
        can(:destroy, Comment) {|c| c.user_id == user.id and !c.has_children?}

        can :create, Vote do |vote|
          user.current_rating.expertise > 0 and user.current_rating.votes_amount > 0 and user != vote.voteable.user rescue false
        end

        can(:subscribe, [Post, MicroPost, Question]) {|o| !user.subscribes.exists?(:subscribeable_id => o.id, :subscribeable_type => o.class)}
        can(:unsubscribe, [Post, MicroPost, Question]) {|o| !can?(:subscribe, o)}

        can :create, Draft
        can [:update, :destroy], Draft, :user_id => user.id
        can :read, [Draft, Favorite], :user_id => user.id
        can(:create, Favorite) {|f| !f.favorable.favorites.exists?(:user_id => user.id)}
        can(:destroy, Favorite) {|o| !can?(:create, o) and o.user == user}

        can [:invite, :accept, :participate], Event

        cannot :join_community, User
      else # not current community members
        cannot :leave_community, User
      end

      ### All users for exchange

      can [:create, :accept], Company
      can [:update, :destroy, :edit_technologies, :invite, :update_roles], Company, :users => {:id => user.id} # :user_id => user.id
      can(:add_more_projects, Company) {|c| c.can_add_more_projects?}
      can(:add_more_recommendations, Company) {|c| c.can_add_more_recommendations?}
      can(:add_more_certificates, Company) {|c| c.can_add_more_certificates?}

      can :manage, [Project, Recommendation, Certificate, CompanyService], :company => {:users => {:id => user.id}} # {:user_id => user.id}

      can [:create, :accept], Order
      can [:update, :close], Order, :user_id => user.id, :state => 'active'
      can :read_fields, Order do |order|
        order.visibility == 'public' or order.offers.roots.where(:company_id => user.companies.map(&:id)).accepted.present? or order.offers.roots.where(:user_id => user.id).accepted.present?
      end

      can :create, Offer do |offer| # through companies
        user_companies = user.confirmed_companies and user_companies_ids = user_companies.map(&:id) and # cache
        offer.order.state == 'active' and # active order
        (user_companies.with_roles(:provider).present? and # user has provider company
        offer.is_root? ? true : (user_companies_ids.include?(offer.root.company_id) or user_companies_ids.include?(offer.order.company_id)) and # check own tree
        case offer.order.visibility
        when 'public'; true # anyone can ofer and comment in own tree
        when 'anonymous'
          offer.is_root? ? true : offer.root.state == 'accepted' # anyone can offer, but comment in own tree only if offer accepted
        # when 'individual'
        #   offer.is_root? ? false : offer.root.state == 'accepted' # noone can create an offer, can comment in own tree only if invited
        end) # or user_companies_ids.include?(offer.order.company_id) # customer company users can write anywhere
      end
      can :create, Offer do |offer| # direct for user
        offer.order.state == 'active' and # active order
        offer.is_root? ? true : (offer.root.user_id == user.id or offer.order.user_id == user.id) and # check own tree
        case offer.order.visibility
        when 'public'; true # anyone can ofer and comment in own tree
        when 'anonymous'
          offer.is_root? ? true : offer.root.state == 'accepted' # anyone can offer, but comment in own tree only if offer accepted
        end # or offer.order.user_id == user.id # customer user can write anywhere
      end
      can [:accept, :reject], Offer, :order => {:user_id => user.id, :state => 'active'}, :ancestry => nil
      cannot :accept, Offer, :state => 'accepted'
      cannot :reject, Offer, :state => ['rejected', 'accepted']
      can :read, Offer, :order => {:company_id => user.companies.map(&:id)} # all offers for current_user companies orders
      can :read, Offer, :company_id => user.companies.map(&:id) # all offers from current_user companies
      can :read, Offer, :order => {:user_id => user.id} # all offers for current_user orders
      can :read, Offer, :user_id => user.id # all offers from current_user
      can :read, Offer, ["offers.id IN (SELECT descendants.id FROM offers INNER JOIN offers descendants ON descendants.ancestry = CAST(offers.id AS text) OR descendants.ancestry LIKE offers.id || '/%' WHERE offers.ancestry IS NULL AND offers.user_id = ?)", user.id]
      # can :read, Offer, :id => user.offers.roots.map(&:descendants).flatten
      # can :read, Offer, :ancestry => user.offers.roots.map{|r| r.descendants.map(&:ancestry)}.flatten
    end
  end
end
