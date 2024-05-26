# frozen_string_literal: true

# The Token class represents an token (e.g., API-Key, access_token, client_token, refresh_token or third party secret) of a user.
class Token < ApplicationRecord
  belongs_to :user
  validates :name, :issuer, :token, :issued_at, :last_used_at, :expires_at, :scopes, :active, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  validates :type, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                   inclusion: { in: %w[api_key access_token refresh_token request_token client_token], error: 'ERR_BLANK', description: '%<value>s is not a valid token type' }

  # Can be called e.g., to:
  #
  # >>> get all tokens of a user:
  # ==> `Current.user.tokens.all`
  #
  # >>> get all active tokens of a user:
  # ==> `Current.user.tokens.active`
  #
  # >>> get the first active Ashby-API-Key of a user:
  # ==> `Current.user.tokens.active` or `Current.user.tokens.where(type: "api_key", issuer: "ashby", active: true).where('expires_at > ?', Time.now.utc).first`
end
