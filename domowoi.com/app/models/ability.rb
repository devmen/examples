class Ability
  include CanCan::Ability
  
  def initialize(user)
    if user.god?
      can :manage, :all
      cannot :manage, Seo do |seo|
        seo.url.starts_with?('/admin/') || seo.url.starts_with?('/office/')
      end
    else
      can :read, Objekt, :access_id => Objekt.aid('Public')
      can :read, Objekt, :access_id => Objekt.aid('Realtor') if user.realtor?
      cannot :read, Objekt, :blocks_active_cache => true
      cannot :read, Objekt, :blocks_user_active_cache => true
      
      can :create, Abuse unless user.is_none?
      can :read, Agency, :blocked => false
      can :manage, Agent, :user_id => user.id
      can :read, User, { :blocks_active_cache => false, :confirm_string => nil }
      can :create, User
      can :manage, User, :id => user.id unless user.is_none?
      can :create, Adress
    end
    cannot :manage, Favorite
    can :manage, Favorite, :user_id => user.id unless user.is_none?
    
    if user.mdrtr?
      for klass in [Objekt, Abuse, User, Agency]
        can :manage, klass, klass.for_adresses_condition(user.moderated_address_ids) do |instance|
          (instance.adress_ids & user.moderated_address_ids).present?
        end
      end

      can :manage, AddedByUserAdress, :mdrtr_id=>user.id
      can :manage, ApprovalAgency, :mdrtr_id => user.id
    end
    
    if user.mdrtr? || user.god?
      cannot :manage, Objekt, 'objekts.user_id in (select id from users where confirm_string is not null)' do |obj|
        !obj.user.confirm_string.nil?
      end
    end

    cannot :manage, Objekt, :access_id => Objekt.aid('Agency')
    cannot :see_real_owner, Objekt
    cannot :be_owner, Objekt
    can    :create_abuse, Objekt

    if user.manager?
      can :manage, Agency, :id => user.managed_agency.id
      can :read, User, :agency_id => user.managed_agency.id
      can :manage, Agent, :agency_id => user.managed_agency.id
      can :manage, Objekt, :user_id => user.managed_agency.user_ids
      cannot :create_abuse, Objekt, :user => {:agency_id => user.agency_id}
      cannot :create, Abuse, :objekt => {:user => {:agency_id => user.managed_agency.id} }
      can :manage, User, { :agency_id => user.managed_agency.id, :is_virtual => true }
      can :manage, VirtualsController
    elsif user.agent?(true)
      can :read, Objekt, :user => {:agency_id => user.agency_id}, :access_id => Objekt.aid('Agency')
      cannot :create_abuse, Objekt, :user_id => user.agency.user_ids
      cannot :create, Abuse, :objekt => {:user_id => user.agency.user_ids }
      can :read, Agency, :id => user.agency_id
      can :read, User, :agency_id => user.agency_id
    end
    
    if user.realtor? && !user.agent? && !user.manager?
      can :create, Agency
    else
      cannot :create, Agency
    end
    
    unless user.mdrtr? || user.god?
      cannot :block, User
      cannot :unblock, User
      cannot :send_admin_letter, User
    end
    
    cannot :manage, Objekt, :access_id => [Objekt.aid('Owner'), Objekt.aid('Closed')]
    can :manage, Objekt, :user_id => user.id, :archived => false unless user.is_none?
    cannot :create_abuse, Objekt, :user_id => user.id
    cannot :create, Abuse, :objekt => {:user_id => user.id}
    cannot :manage_abuses, Objekt unless user.moderator? || user.god?
    cannot :manage, Objekt, :archived => true unless user.god? || user.mdrtr?
    can :read, Objekt, :archived => true

    can :create, Objekt
    cannot :create, Objekt if (user.individual? || user.is_none?) && user.objekts.count >= 2
    
    can NdvCommon do |action, klass, ndv|
      can? action, (ndv.present? ? ndv.objekt : Objekt)
    end
  end
end
