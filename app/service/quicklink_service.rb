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
    ISSUER = Socket.gethostname
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
      def self.call(user_id, subscription, custom_exp)
        ApplicationController.must_be_verified!(user_id)
        exp = calculate_expiration(custom_exp, subscription)
        typ = SubscriptionHelper.subscription_type(subscription.processor_plan) # Needed for quick authorization when token is used
        iat = Time.now.to_i
        QuicklinkService::Client.encode(user_id, exp.to_i, typ, iat)
      end

      def self.calculate_expiration(custom_exp, subscription)
        exp = if custom_exp.nil? || custom_exp < Time.now
                Time.now.to_i + (60 * 60 * 24 * 31 * 3) # standard validity interval: 3 months or end of subscription
              else
                custom_exp.to_i # Set custom expiration date if available
              end

        [exp, subscription.current_period_end.to_i].min # Token can't be valid longer than subscription
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
    ISSUER = Socket.gethostname
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
        user_id = session[:client_id]
        typ = session[:subscription_type]
        # job_slug = session[:job_slug]
        mode = session[:mode]
        # success_url = session[:success_url]
        # cancel_url = session[:cancel_url]

        SubscriptionHelper.check_valid_mode(typ, mode)

        # ApplicationController.must_be_verified!(user_id) # TODO: This shouldn't be needed here as verification already happens on client_token creation
        # TODO: @cb verify job / account validity / price category?

        # job = job_slug # Other encoding/id options possible?
        exp = Time.now.to_i + (60 * 60 * 30) # standard validity interval: 30 minutes
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
