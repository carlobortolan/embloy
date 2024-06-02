# frozen_string_literal: true

# The Token class represents an token (e.g., API-Key, access_token, client_token, refresh_token or third party secret) of a user.
class Token < ApplicationRecord
  belongs_to :user
  attr_encrypted :token, key: 'This is a key that is 256 bits!!'

  validates :name, :token, :issued_at, :expires_at, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  validates :token_type, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                         inclusion: { in: %w[api_key access_token refresh_token request_token client_token], error: 'ERR_INVALID', description: '%<value>s is not a valid token type' }
  validates :issuer, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                     inclusion: { in: %w[embloy ashby lever softgarden], error: 'ERR_INVALID', description: '%<value>s is not a valid token issuer' }
end
