# frozen_string_literal: true

# The QuicklinkService class is responsible for handling the server-side authorization
# part of the Embloy application process. It includes two nested classes, Client and Request,
# which handle the encoding and decoding of client and request tokens respectively.
class QuicklinkService < AuthenticationTokenService
  # The Client class is responsible for handling client tokens. These tokens are used
  # to authenticate the server making requests to Embloy's API.
  class Client
    HMAC_SECRET = ENV.fetch('CLIENT_TOKEN_SECRET', nil)
    ALGORITHM_TYPE = 'HS256'
    ISSUER = 'api.embloy.com'
    REPLACEMENT_CHARACTER = '°'

    # Encodes a client token with the given payload.
    def self.encode(sub, exp, typ, iat)
      payload = { sub:, exp:, typ:, iat: }
      AuthenticationTokenService.call(
        HMAC_SECRET, ALGORITHM_TYPE, ISSUER, payload
      )
    end

    # Decodes a client token and returns the decoded payload.
    def self.decode(token)
      JWT.decode(token, HMAC_SECRET, true, { iss: ISSUER, verify_iss: true, verify_iat: true, required_claims: %w[iss sub exp typ iat], algorithm: ALGORITHM_TYPE })
    end

    # The Encoder class is responsible for encoding client tokens.
    class Encoder
      include SubscriptionHelper
      # Encodes a client token for a given user ID and subscription and expiration date.
      def self.call(stripe_price_id, custom_exp)
        exp = calculate_expiration(custom_exp)
        typ = SubscriptionHelper.subscription_type(stripe_price_id) # Needed for quick authorization when token is used
        iat = Time.now.to_i
        client_token = QuicklinkService::Client.encode(Current.user.id.to_i, exp.to_i, typ, iat)
        Token.create!(
          user: Current.user,
          name: 'Automatically generated client token',
          issuer: 'embloy',
          token: client_token,
          issued_at: Time.at(iat),
          expires_at: Time.at(exp),
          token_type: 'client_token'
        )
        client_token
      end

      def self.calculate_expiration(custom_exp)
        if custom_exp.nil? || custom_exp < Time.now
          Time.now.to_i + 3.months # standard validity interval: 3 months
        else
          custom_exp.to_i # Set custom expiration date if available
        end

        # [exp, subscription.current_period_end.to_i].min # Token can't be valid longer than subscription
      end
    end

    # The Decoder class is responsible for decoding client tokens.
    class Decoder
      # Decodes a client token.
      def self.call(token)
        raise CustomExceptions::InvalidInput::Quicklink::Client::Malformed if token.class != String
        raise CustomExceptions::InvalidInput::Quicklink::Client::Blank if token[0] == ':' || token.blank?

        QuicklinkService::Client.decode(token)
      end
    end
  end

  # The Request class is responsible for handling request tokens. These tokens are used
  # to authenticate the user's application request to Embloy's API and communicate the selected job.
  class Request
    HMAC_SECRET = ENV.fetch('REQUEST_TOKEN_SECRET', nil)
    ALGORITHM_TYPE = 'HS256'
    ISSUER = 'api.embloy.com'
    REPLACEMENT_CHARACTER = '°'

    # Encodes a request token with the given payload.
    def self.encode(sub, exp, session, iat)
      payload = { sub:, exp:, session:, iat: }
      AuthenticationTokenService.call(
        HMAC_SECRET, ALGORITHM_TYPE, ISSUER, payload
      )
    end

    # Decodes a request token and returns the decoded payload.
    def self.decode(token)
      JWT.decode(token, HMAC_SECRET, true,
                 { iss: ISSUER, verify_iss: true, verify_iat: true, required_claims: %w[iss sub exp session iat], algorithm: ALGORITHM_TYPE })
    end

    # The Encoder class is responsible for encoding request tokens.
    class Encoder
      # Encodes a request token for a given application process session.
      def self.call(session)
        user_id = session[:user_id]
        typ = session[:subscription_type]
        mode = session[:mode]

        SubscriptionHelper.check_valid_mode(typ, mode)

        # TODO: @cb verify job / account validity / price category?

        # job = job_slug # Other encoding/id options possible?
        exp = Time.now.to_i + 30.minutes.to_i # standard validity interval: 30 minutes
        iat = Time.now.to_i
        QuicklinkService::Request.encode(user_id, exp, session, iat)
      end
    end

    # The Decoder class is responsible for decoding request tokens.
    class Decoder
      # Decodes a request token.
      def self.call(token)
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed if token.class != String
        raise CustomExceptions::InvalidInput::Quicklink::Request::Blank if token[0] == ':' || token.blank?

        QuicklinkService::Request.decode(token)
      end
    end
  end
end
