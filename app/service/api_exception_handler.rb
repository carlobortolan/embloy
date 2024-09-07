# frozen_string_literal: true

# rubocop:disable Metrics/ModuleLength, Style/Documentation, Metrics/BlockLength

module ApiExceptionHandler
  extend ActiveSupport::Concern

  included do
    # =========== Job related exceptions ============
    # ===============================================

    rescue_from JWT::VerificationError,
                with: :token_verification_error

    #--------------------------------------

    rescue_from JWT::DecodeError,
                with: :token_decode_error

    #--------------------------------------

    rescue_from JWT::ExpiredSignature,
                with: :token_expired_error

    #--------------------------------------

    rescue_from JWT::InvalidIssuerError,
                with: :token_invalid_issuer_error

    #--------------------------------------

    rescue_from JWT::IncorrectAlgorithm,
                with: :token_algorithm_error

    #--------------------------------------

    rescue_from JWT::InvalidJtiError,
                with: :token_jti_error

    #--------------------------------------

    rescue_from JWT::InvalidIatError,
                with: :token_iat_error

    #--------------------------------------

    rescue_from JWT::InvalidSubError,
                with: :token_sub_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidJob::Unknown,
                with: :job_unknown_error

    rescue_from CustomExceptions::InvalidJob::Inactive,
                with: :job_inactive_error

    # =========== User related exceptions ===========
    # ===============================================

    rescue_from CustomExceptions::InvalidUser::Unknown,
                with: :user_unknown_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidUser::Inactive,
                with: :user_inactive_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidUser::Unknown,
                with: :user_unknown_error

    #--------------------------------------

    rescue_from CustomExceptions::Unauthorized::NotOwner,
                with: :user_not_owner_error

    #--------------------------------------

    rescue_from CustomExceptions::Unauthorized::InsufficientRole::NotVerified,
                with: :user_role_to_low_error

    #--------------------------------------

    rescue_from CustomExceptions::Unauthorized::InsufficientRole,
                with: :user_role_to_low_error

    #--------------------------------------

    rescue_from CustomExceptions::Unauthorized::Blocked,
                with: :user_blocked_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidInput::BlankCredentials,
                with: :user_pw_blank

    # ========== Token related exceptions ===========
    # ===============================================

    rescue_from CustomExceptions::InvalidInput::Token,
                with: :token_invalid_input_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidInput::CustomEXP,
                with: :custom_validity_invalid_input_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidInput::SUB,
                with: :user_sub_error

    #--------------------------------------
    rescue_from CustomExceptions::InvalidInput::Quicklink::Client::Malformed,
                with: :client_token_malformed_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::Client::Blank,
                with: :client_token_blank_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::Request::Malformed,
                with: :request_token_malformed_error
    rescue_from CustomExceptions::InvalidInput::Quicklink::Request::Blank,
                with: :request_token_blank_error
    rescue_from CustomExceptions::InvalidInput::Quicklink::Request::Forbidden,
                with: :request_token_forbidden_error
    rescue_from CustomExceptions::InvalidInput::Quicklink::Request::NotFound,
                with: :request_token_not_found_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::Mode::Malformed,
                with: :request_mode_malformed_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized,
                with: :api_key_unauthorized_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::ApiKey::Missing,
                with: :api_key_missing_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::ApiKey::Malformed,
                with: :api_key_malformed_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::ApiKey::Inactive,
                with: :api_key_inactive_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::OAuth::Forbidden,
                with: :oauth_forbidden_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::OAuth::NotFound,
                with: :oauth_not_found_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::OAuth::Unauthorized,
                with: :oauth_unauthorized_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::OAuth::NotAcceptable,
                with: :oauth_not_acceptable_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::Application::Malformed,
                with: :application_malformed_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::Application::Unauthorized,
                with: :application_unauthorized_error

    rescue_from CustomExceptions::InvalidInput::Quicklink::Application::Duplicate,
                with: :application_duplicate_error

    rescue_from CustomExceptions::Subscription::ExpiredOrMissing,
                with: :subscription_expired_or_missing_error

    rescue_from CustomExceptions::Subscription::LimitReached,
                with: :subscription_limit_reached_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidInput::GeniusQuery::Malformed,
                with: :genius_query_malformed_error

    rescue_from CustomExceptions::InvalidInput::GeniusQuery::Blank,
                with: :genius_query_blank_error

    rescue_from CustomExceptions::InvalidInput::GeniusQuery::Removed,
                with: :genius_query_removed_error
  end

  private

  # =========== Job related exceptions ============
  # ===============================================

  def job_unknown_error
    not_found_error('job')
  end

  def job_inactive_error
    access_denied_error('job')
  end

  # =========== User related exceptions ===========
  # ===============================================

  def user_unknown_error
    not_found_error('user')
  end

  #--------------------------------------

  def user_inactive_error
    access_denied_error('user')
  end

  #--------------------------------------

  def user_not_owner_error
    access_denied_error('user')
  end

  #--------------------------------------

  def user_role_to_low_error
    access_denied_error('user')
  end

  #--------------------------------------

  def user_blocked_error
    access_denied_error('user')
  end

  #--------------------------------------

  def user_pw_blank
    blank_error('email|password')
  end

  # sub: subject of a token is not authorized to act (token specific 401s => exists for internal troubleshooting reasons)
  def user_sub_error
    unauthorized_error('user')
  end

  def subscription_expired_or_missing_error
    access_denied_error('subscription')
  end

  def subscription_limit_reached_error
    too_many_requests_error('subscription', 'You\'ve reached the maximum number of allowed resources for your subscription type')
  end

  # ========== Token related exceptions ===========
  # ===============================================

  def token_invalid_input_error
    malformed_error('token')
  end

  def client_token_blank_error
    malformed_error('client_token')
  end

  def client_token_malformed_error
    malformed_error('client_token')
  end

  def request_token_blank_error
    malformed_error('request_token')
  end

  def request_token_forbidden_error
    access_denied_error('request_token')
  end

  def request_token_not_found_error
    not_found_error('request_token', 'The job included in the request token was not found')
  end

  def request_token_malformed_error
    malformed_error('request_token')
  end

  def request_mode_malformed_error
    malformed_error('mode')
  end

  def genius_query_malformed_error
    malformed_error('genius_query')
  end

  def genius_query_blank_error
    blank_error('genius_query')
  end

  def genius_query_removed_error
    removed_error('genius_query')
  end

  def custom_validity_invalid_input_error
    malformed_error('validity')
  end

  def api_key_unauthorized_error
    unauthorized_error('api_key')
  end

  def api_key_missing_error
    blank_error('api_key')
  end

  def api_key_malformed_error
    malformed_error('api_key')
  end

  def api_key_inactive_error
    access_denied_error('api_key', 'API key is inactive')
  end

  def oauth_unauthorized_error
    unauthorized_error('oauth', 'OAUth flow not authorized')
  end

  def oauth_forbidden_error
    access_denied_error('oauth', 'Either unable to find a signing key that matches, clientID not found or he key you provided does not have access to this endpoint')
  end

  def oauth_not_found_error
    not_found_error('oauth')
  end

  def oauth_not_acceptable_error
    not_acceptable_error('oauth', 'OAUth flow not acceptable')
  end

  def application_malformed_error
    malformed_error('application')
  end

  def application_unauthorized_error
    unauthorized_error('application')
  end

  def application_duplicate_error
    unnecessary_error('application')
  end

  #--------------------------------------

  def token_expired_error
    unauthorized_error('token')
  end

  #--------------------------------------

  def token_invalid_issuer_error
    unauthorized_error('token')
    # render_error('token', 'ERR_INVALID', 'Attribute was signed by an unknown issuer', 401)
  end

  #--------------------------------------

  def token_algorithm_error
    unauthorized_error('token')
    # render_error('token', 'ERR_INVALID', 'Token was encoded with an unknown algorithm', 401)
  end

  #--------------------------------------

  def token_verification_error
    unauthorized_error('token')
    # render_error('token', 'ERR_INVALID', 'Attribute can\'t be verified', 401)
  end

  #--------------------------------------

  def token_jti_error
    access_denied_error('token')
    # render_error('token', 'ERR_INACTIVE', 'Attribute is blocked', 403)
  end

  #--------------------------------------

  def token_iat_error
    unauthorized_error('token')
    # render_error('token', 'ERR_INVALID', 'Attribute was timestamped incorrectly', 401)
  end

  #--------------------------------------

  def token_sub_error
    unauthorized_error('token')
    # render_error('token', 'ERR_INVALID', 'Attribute can't be allocated to an existing user', 401)
  end

  #--------------------------------------
  def token_decode_error
    unauthorized_error('token')
  end

  # ============ Basic render methods =============
  # ===============================================

  def blank_error(attribute)
    render_error(attribute, 'ERR_BLANK', 'Attribute can\'t be blank', 400)
  end

  #--------------------------------------

  def malformed_error(attribute)
    render_error(attribute, 'ERR_INVALID', 'Attribute is malformed or unknown', 400)
  end

  #--------------------------------------

  def unauthorized_error(attribute, description = 'Attribute is invalid or expired')
    render_error(attribute, 'ERR_INVALID', description, 401)
  end

  #--------------------------------------

  def access_denied_error(attribute, message = nil)
    render_error(attribute, 'ERR_RAC', message || 'Proceeding is inhibited by an access restriction', 403)
  end

  #--------------------------------------

  def not_found_error(attribute, description = 'Attribute can not be retrieved')
    render_error(attribute, 'ERR_INVALID', description, 404)
  end

  #--------------------------------------

  def removed_error(attribute)
    render_error(attribute, 'ERR_REMOVED', 'Attribute was removed and cannot be accessed anymore', 409)
  end

  #--------------------------------------

  def unnecessary_error(attribute)
    render_error(attribute, 'ERR_UNNECESSARY', 'Attribute is already submitted', 422)
  end

  #--------------------------------------

  def mismatch_error(attribute)
    render_error(attribute, 'ERR_MISMATCH', 'Required matching attributes do not match', 422)
  end

  #--------------------------------------

  def biased_error(attribute)
    render_error(attribute, 'ERR_INVALID', 'Attribute is biased', 422)
  end

  #--------------------------------------

  def too_many_requests_error(attribute, message = nil)
    render_error(attribute, 'ERR_LIMIT', message || 'Too many request', 429)
  end

  #--------------------------------------

  def render_error(attribute, error, description, status)
    if attribute.instance_of?(Array)
      bin = {}
      attribute.each do |att|
        bin[att.to_s] = [{ error:, description: }]
      end
      render status:, json: bin
    else
      render status:, json: { attribute => [{ error:, description: }] }
    end
  end
end
# rubocop:enable Metrics/ModuleLength, Style/Documentation, Metrics/BlockLength
