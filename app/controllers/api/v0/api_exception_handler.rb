# frozen_string_literal: true

module ApiExceptionHandler
  extend ActiveSupport::Concern
  included do
    rescue_from CustomExceptions::Unauthorized::InsufficientRole::NotOwner,
                with: :user_not_owner_error
    rescue_from CustomExceptions::Unauthorized::InsufficientRole,
                with: :user_role_to_low_error

    rescue_from CustomExceptions::InvalidInput::Token,
                with: :token_invalid_input_error
    rescue_from JWT::ExpiredSignature,
                with: :token_expired_error
    rescue_from JWT::InvalidIssuerError,
                with: :token_invalid_issuer_error
    rescue_from JWT::IncorrectAlgorithm,
                with: :token_algorithm_error
    rescue_from JWT::VerificationError,
                with: :token_verification_error
    rescue_from JWT::DecodeError,
                with: :token_decode_error

  end

  private

  def user_not_owner_error
    access_denied_error
  end

  def user_role_to_low_error
    access_denied_error
  end

  def token_invalid_input_error
    token_decode_error
  end

  def token_expired_error
    render_error('token', 'ERR_INVALID', 'Attribute is expired', 401)
  end

  def token_invalid_issuer_error
    render_error('token', 'ERR_INVALID', 'Attribute was signed by an unknown issuer', 401)
  end

  def token_algorithm_error
    render_error('token', 'ERR_INVALID', 'Token was encoded with an unknown algorithm', 401)
  end

  def token_verification_error
    render_error('token', 'ERR_INVALID', 'Token can\'t be verified', 401)
  end

  def token_decode_error
    malformed_token_error
  end

  # ============ Basic render methods =============
  # ===============================================
  def access_denied_error
    render_error('user', 'ERR_ACCESS_DENIED', 'Attribute is not permitted do proceed', 403)
  end

  #--------------------------------------

  def malformed_token_error
    render_error('token', 'ERR_INVALID', 'Attribute is malformed or unknown', 400)
  end

  #--------------------------------------

  def render_error(attribute, error, description, status)
    render status: status, json: { attribute => [{ error: error, description: description }] }
  end
end

=begin

rescue JWT::InvalidJtiError
render status: 403, json: { "refresh_token": [
  {
    "error": "ERR_INACTIVE",
    "description": "Attribute is blocked."
  }
]
}
rescue CustomExceptions::InvalidInput::Token
render status: 400, json: { "refresh_token": [
  {
    "error": "ERR_INVALID",
    "description": "Attribute is malformed or unknown."
  }
]
}
# ========== Rescue severe Exceptions ==========
rescue JWT::InvalidIatError
render status: 401, json: { "refresh_token": [
  {
    "error": "ERR_INVALID",
    "description": "Attribute was timestamped incorrectly."
  }
]
}
rescue JWT::InvalidSubError
render status: 401, json: { "refresh_token": [
  {
    "error": "ERR_INVALID",
    "description": "Attribute can't be allocated to an existing user."
  }
]
}


rescue CustomExceptions::Unauthorized::InsufficientRole
render status: 403, json: { "user": [
  {
    "error": "ERR_INACTIVE",
    "description": "Attribute is blocked."
  }
]
}

=end