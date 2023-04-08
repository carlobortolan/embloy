# frozen_string_literal: true

module ApiExceptionHandler
  # frozen_string_literal: true

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

    # =========== User related exceptions ===========
    # ===============================================

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

    rescue_from CustomExceptions::InvalidInput::BlankCredentials,
                with: :user_pw_blank

    #--------------------------------------
    # ========== Token related exceptions ===========
    # ===============================================

    rescue_from CustomExceptions::InvalidInput::Token,
                with: :token_invalid_input_error

    #--------------------------------------

    rescue_from CustomExceptions::InvalidInput::CustomEXP,
                with: :custom_validity_invalid_input_error

  end

  private

  # =========== Job related exceptions ============
  # ===============================================

  def job_unknown_error
    malformed_error('job')
  end

  # =========== User related exceptions ===========
  # ===============================================

  def user_unknown_error
    malformed_error('user')
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

  def user_pw_blank
    blank_error('email|password')
  end

  # ========== Token related exceptions ===========
  # ===============================================

  def token_invalid_input_error
    malformed_error('token')
  end

  def custom_validity_invalid_input_error
    malformed_error('validity')
  end

  #--------------------------------------

  def token_expired_error
    unauthorized_error('token')
    # render_error('token', 'ERR_INVALID', 'Attribute is expired', 401)
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
    malformed_error('token')
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

  def unauthorized_error(attribute)
    render_error(attribute, 'ERR_INVALID', 'Attribute is invalid or expired', 401)
  end

  #--------------------------------------

  def access_denied_error(attribute)
    render_error(attribute, 'ERR_RAC', 'Proceeding is inhibited by an access restriction', 403)
  end

  #--------------------------------------

  def not_found_error(attribute)
    render_error(attribute, 'ERR_INVALID', 'Attribute is malformed or unknown', 404)
  end

  #--------------------------------------

  def unnecessary_error(attribute)
    render_error(attribute, 'ERR_UNNECESSARY', 'Attribute is already submitted', 422)
  end

  #--------------------------------------

  def render_error(attribute, error, description, status)
    if attribute.class == Array
      bin = {}
      attribute.each do |att|
        bin["#{att}"]=[{ error: error, description: description }]
      end
      render status: status, json: bin
    else
      render status: status, json: { attribute => [{ error: error, description: description }] }
    end

  end
end



