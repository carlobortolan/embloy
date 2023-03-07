# frozen_string_literal: true

module ApiExceptionHandler
  extend ActiveSupport::Concern
  included do

    # =========== Job related exceptions ============
    # ===============================================

    rescue_from CustomExceptions::InvalidJob::Unknown,
                with: :job_unknown_error



    # =========== User related exceptions ===========
    # ===============================================

    rescue_from CustomExceptions::InvalidUser::Unknown,
                with: :user_unknown_error

    #--------------------------------------

    rescue_from CustomExceptions::Unauthorized::InsufficientRole::NotOwner,
                with: :user_not_owner_error

    #--------------------------------------

    rescue_from CustomExceptions::Unauthorized::InsufficientRole,
                with: :user_role_to_low_error



    # ========== Token related exceptions ===========
    # ===============================================

    rescue_from CustomExceptions::InvalidInput::Token,
                with: :token_invalid_input_error

    #--------------------------------------

    rescue_from JWT::ExpiredSignature,
                with: :token_expired_error



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
    access_denied_error
  end

  #--------------------------------------

  def user_role_to_low_error
    access_denied_error
  end



  # ========== Token related exceptions ===========
  # ===============================================

  def token_invalid_input_error
    malformed_error('token')
  end

  #--------------------------------------

  def token_expired_error
    unauthorized_token_error
    #render_error('token', 'ERR_INVALID', 'Attribute is expired', 401)
  end

  #--------------------------------------

  def token_invalid_issuer_error
    unauthorized_token_error
    #render_error('token', 'ERR_INVALID', 'Attribute was signed by an unknown issuer', 401)
  end

  #--------------------------------------

  def token_algorithm_error
    unauthorized_token_error
    #render_error('token', 'ERR_INVALID', 'Token was encoded with an unknown algorithm', 401)
  end

  #--------------------------------------

  def token_verification_error
    unauthorized_token_error
    #render_error('token', 'ERR_INVALID', 'Attribute can\'t be verified', 401)
  end

  #--------------------------------------

  def token_jti_error
    unauthorized_token_error
    #render_error('token', 'ERR_INACTIVE', 'Attribute is blocked', 403)
  end

  #--------------------------------------

  def token_iat_error
    unauthorized_token_error
    #render_error('token', 'ERR_INVALID', 'Attribute was timestamped incorrectly', 401)
  end

  #--------------------------------------

  def token_sub_error
    unauthorized_token_error
    #render_error('token', 'ERR_INVALID', 'Attribute can't be allocated to an existing user', 401)
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

  def unauthorized_token_error
    render_error('token', 'ERR_INVALID', 'Attribute is invalid or expired. Please authenticate again to access this resource', 401)
  end

  #--------------------------------------

  def access_denied_error
    render_error('user', 'ERR_ACCESS_DENIED', 'Attribute is not permitted do proceed', 403)
  end

  #--------------------------------------

  def unnecessary_error(attribute)
    render_error(attribute, 'ERR_UNNECESSARY', 'Attribute is already submitted', 422)
  end

  #--------------------------------------

  def render_error(attribute, error, description, status)
    render status: status, json: { attribute => [{ error: error, description: description }] }
  end
end

