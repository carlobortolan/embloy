# frozen_string_literal: true

# The Token class represents an token (e.g., API-Key, access_token, client_token, refresh_token or third party secret) of a user.
class Token < ApplicationRecord
  belongs_to :user
  attr_encrypted :token, key: 'This is a key that is 256 bits!!'

  validates :name, :token, :issued_at, :expires_at, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" }
  validates :token_type, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                         inclusion: { in: %w[api_key access_token refresh_token request_token client_token otp], error: 'ERR_INVALID', description: '%<value>s is not a valid token type' }
  validates :issuer, presence: { error: 'ERR_BLANK', description: "Attribute can't be blank" },
                     inclusion: { in: %w[embloy ashby lever softgarden], error: 'ERR_INVALID', description: '%<value>s is not a valid token issuer' }

  def deactivate!
    update(active: false)
  end

  def self.fetch_token(client, issuer, token_type)
    # Find API Key for current client
    current_keys = client.tokens.where(token_type:, issuer:).where('expires_at > ?', Time.now.utc)
    return if current_keys.empty?

    current_keys.detect(&:active?)&.token
  end

  def self.fetch_token!(client, issuer, token_type)
    # Find API Key for current client and throw errors if missing or inactive
    current_keys = client.tokens.where(token_type:, issuer:).where('expires_at > ?', Time.now.utc)
    raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Missing and return if current_keys.empty?

    token = current_keys.detect(&:active?)&.token
    raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Inactive and return if token.nil?

    token
  end

  def self.generate_otp(client)
    Token.save_token(client, 'OTP', :embloy, :otp, SecureRandom.random_number(1_000_000).to_s.rjust(6, '0'), Time.current + 10.minutes, Time.current)&.token
  end

  def self.valid_otp?(client, otp_code)
    current_keys = client.tokens.where(token_type: :otp, issuer: :embloy).where('expires_at > ?', Time.now.utc)
    return false if current_keys.empty?

    active_key = current_keys.detect(&:active?)
    return false if active_key.nil?

    token = active_key.token
    return false unless token.to_i == otp_code.to_i

    active_key.destroy!
    client.update!(user_role: :verified) if client.user_role == 'spectator'
    true
  end

  def self.save_token(client, name, issuer, token_type, token, expires_at, issued_at) # rubocop:disable Metrics/ParameterLists
    # Find API Key for current client
    client.tokens.where(token_type:, issuer:).where('expires_at > ?', Time.now.utc).each(&:deactivate!)
    client.tokens.create!(token_type:, name:, issuer:, token:, expires_at:, issued_at:)
  end

  def self.deactivate_all(client, issuer)
    client.tokens.where(issuer: issuer).each(&:deactivate!)
  end
end
