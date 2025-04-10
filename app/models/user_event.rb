# frozen_string_literal: true

class UserEvent < ApplicationRecord
  belongs_to :user
  belongs_to :user_session

  enum :category, {
    login:                                   0,
    reauthenticate:                          25,
    failed_login:                            50,
    banned_login:                            60,
    failed_reauthenticate:                   75,
    logout:                                  100,
    user_creation:                           200,
    user_deletion:                           300,
    password_reset:                          400,
    password_change:                         500,
    email_change:                            600,
    email_verify:                            650,
    mfa_enable:                              700,
    mfa_update:                              710,
    mfa_disable:                             720,
    mfa_login:                               730,
    mfa_login_pending_verification:          733,
    mfa_failed_login:                        736,
    mfa_reauthenticate:                      740,
    mfa_reauthenticate_pending_verification: 743,
    mfa_failed_reauthenticate:               746,
    backup_codes_generate:                   800,
    backup_code_login:                       840,
    backup_code_reauthenticate:              845,
  }

  delegate :session_id, :ip_addr, :ip_geolocation, to: :user_session

  module ConstructorMethods
    def create_from_request!(user, category, request)
      raise(StandardError, "Anonymous user supplied to UserEvent#create_from_request!") if user.is_anonymous?
      ip_addr = request.remote_ip
      user_session = UserSession.new(session_id: request.session[:session_id], ip_addr: ip_addr, user_agent: request.user_agent)
      user.user_events.create!(category: category, user_session: user_session, ip_addr: ip_addr, session_id: request.session[:session_id], user_agent: request.user_agent)
    end
  end

  module SearchMethods
    def visible(user)
      if user.is_admin?
        all
      else
        where(user: user)
      end
    end

    def search(params)
      q = super
      q = q.where_user(:user_id, :user, params)
      q = q.attribute_matches(:category, params[:category])
      q = q.attribute_matches(:session_id, params[:session_id])
      q = q.attribute_matches(:user_agent, params[:user_agent])
      if params[:ip_addr].present?
        q = q.where("ip_addr <<= ?", params[:ip_addr])
      end
      q.apply_basic_order(params)
    end
  end

  extend SearchMethods
  extend ConstructorMethods
end
