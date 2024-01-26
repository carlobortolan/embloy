# frozen_string_literal: true

# The AuthenticationTokenService class is responsible for generating and decoding JWT tokens.
class AuthenticationTokenService
  # generates a generic token (=> is used to generate refresh and access token)
  # CAUTION: NO INPUT VERIFICATION ETC. PROVIDED BY THIS METHOD
  def self.call(secret, algorithm, issuer, payload)
    payload['iss'] = issuer.to_s
    JWT.encode payload, secret, algorithm
  end

  #########################################################
  ############### En-/Decoding Refresh token ##############
  #########################################################
  # The Refresh class is responsible for handling refresh tokens.
  class Refresh
    HMAC_SECRET = ENV.fetch('REFRESH_TOKEN_SECRET', nil)
    ALGORITHM_TYPE = 'HS256'
    ISSUER = Socket.gethostname

    def self.encode(sub, exp, jti, iat)
      # serializes token generation for a refresh token
      payload = { sub:, exp:, jti:, iat: }
      AuthenticationTokenService.call(
        HMAC_SECRET, ALGORITHM_TYPE, ISSUER, payload
      )
    end

    def self.decode(token)
      # token decoding for a refresh token
      # this method decodes a jwt token
      decoded_token = JWT.decode(token, HMAC_SECRET, true, { verify_jti: proc { |jti|
                                                                           jti?(jti, token['sub'].to_i)
                                                                         }, iss: ISSUER, verify_iss: true, verify_iat: true, required_claims: %w[iss sub exp jti iat], algorithm: ALGORITHM_TYPE })

      raise JWT::InvalidSubError if User.find_by(id: decoded_token[0]['sub']).blank?

      ApplicationController.must_be_verified!(decoded_token[0]['sub']) # if not: ApplicationController::InvalidUser::Taboo is risen

      decoded_token
    end

    def self.forbidden?(token)
      # if exists and is explicitly blacklisted .forbidden? is true if token is allowed .forbidden? is false
      jti = content(token)
      # if .content returns { "status": status, "token": errors } == nil, because {...}[0] == nil
      unless jti[0].nil?
        return !jti?(jti[0]['jti'],
                     token['sub'].to_i)
      end

      # if .jti? finds token identifier blacklisted, it returns true. .forbidden? returns false in this case

      jti # error message from content
    end

    def self.jti(iat)
      # creates a unique token identifier (made for application in refresh tokens)
      Digest::MD5.hexdigest([iat.to_s, ISSUER,
                             HMAC_SECRET].join(':').to_s)
    end

    def self.jti?(jti, sub = nil)
      # checks whether a specifc (refresh) token is blacklisted (via its identifier "jti")
      !(AuthBlacklist.find_by(token: jti).present? || User.find_by(id: sub).present?)
    end

    def self.must_be_verified_id!(user_id)
      if user_id.class != Integer || !user_id.positive? # is user_id parameter not an integer?
        raise CustomExceptions::InvalidInput::SUB

      elsif User.find_by(id: user_id).blank? # is the given id referencing an non-existing user?
        raise CustomExceptions::InvalidUser::Unknown

      elsif User.find_by(id: user_id).activity_status.zero? # is the user for the given id deactivated?
        raise CustomExceptions::InvalidUser::Inactive

      elsif UserBlacklist.find_by(user_id:).present? # is the user for the given id blacklisted/actively blocked?
        raise CustomExceptions::Unauthorized::Blocked
      end
    end

    def self.verify_expiration(man_interval, max, min)
      # is man_interval a positive integer?
      raise CustomExceptions::InvalidInput::CustomEXP unless man_interval.instance_of?(Integer) && man_interval.positive?

      if man_interval <= max && man_interval >= min # is the given required validity interval not longer than MAX_INTERVAL and not shorter than MIN_INTERVAL?
        man_interval # the given required validity interval is sufficient

      elsif man_interval > max # the given required validity interval is too long, so the token validity interval gets set to MAX_INTERVAL
        max

      elsif man_interval < min # the given required validity interval is too short, so the token validity interval gets set to MIN_INTERVAL
        min
      end

      # man_interval is no integer or either negative or 0
    end

    # TODO: ISSUE #25
    #     def self.sub?(sub)
    #       # checks whether a user exists in the database
    #       if User.find_by(id: sub.to_i).present?
    #         true # user is known
    #       else
    #         false # user is unknown
    #       end
    #     end
    # helper class for token generation
    class Encoder
      MAX_INTERVAL = 1_209_600 # == 336 hours == 2 weeks
      MIN_INTERVAL = 1800 # == 0.5 hours == 30 min

      def self.call(user_id, man_interval = nil)
        #         if user_id.class != Integer || !user_id.positive? # is user_id parameter not an integer?
        #           raise CustomExceptions::InvalidInput::SUB
        #
        #         elsif User.find_by(id: user_id).blank? # is the given id referencing an non-existing user?
        #           raise CustomExceptions::InvalidUser::Unknown
        #
        #         elsif User.find_by(id: user_id).activity_status == 0 # is the user for the given id deactivated?
        #           raise CustomExceptions::InvalidUser::Inactive
        #
        #         elsif UserBlacklist.find_by(user_id: user_id).present? # is the user for the given id blacklisted/actively blocked?
        #           raise CustomExceptions::Unauthorized::Blocked
        AuthenticationTokenService::Refresh.must_be_verified_id!(user_id)
        ApplicationController.must_be_verified!(user_id) # if not: ApplicationController::InvalidUser::Taboo is risen
        # the given id references an existing user, who is active and not blacklisted
        iat = Time.now.to_i # timestamp
        sub = user_id # who "owns" the token

        bin_exp = if man_interval.nil? # the man_interval parameter is not given/used
                    iat + 14_400 # standard validity interval (4 hours == 240 min == 14400 sec)

                  else
                    #           # the man_interval parameter is given/user -> a manual token expiration time is required
                    #           if man_interval.class == Integer && man_interval.positive? # is man_interval a positive integer?
                    #
                    #             if man_interval <= MAX_INTERVAL && man_interval >= MIN_INTERVAL
                    # is the given required validity interval not longer than MAX_INTERVAL and not shorter than MIN_INTERVAL?
                    #               bin_exp = iat + man_interval # the given required validity interval is sufficient
                    #
                    #             elsif man_interval > MAX_INTERVAL # the given required validity interval is too long, so the token validity interval gets set to MAX_INTERVAL
                    #               bin_exp = iat + MAX_INTERVAL
                    #
                    #             elsif man_interval < MIN_INTERVAL # the given required validity interval is too short, so the token validity interval gets set to MIN_INTERVAL
                    #               bin_exp = iat + MIN_INTERVAL
                    #             end
                    #
                    #           else
                    #             # man_interval is no integer or either negative or 0
                    #             raise CustomExceptions::InvalidInput::CustomEXP
                    #           end
                    iat + AuthenticationTokenService::Refresh.verify_expiration(man_interval, MAX_INTERVAL,
                                                                                MIN_INTERVAL)

                  end
        exp = bin_exp # placeholder for a standard value or a manually set value
        jti = AuthenticationTokenService::Refresh.jti(iat) # unique token identifier based on the issuing time and the issuer (more info above)
        AuthenticationTokenService::Refresh.encode(sub, exp, jti, iat) # make a refresh token
      end
    end

    # The Decoder class is responsible for decoding refresh tokens.
    class Decoder
      def self.call(token)
        raise CustomExceptions::InvalidInput::Token if token.class != String || token.blank?

        AuthenticationTokenService::Refresh.decode(token)
      end
    end
  end

  #########################################################
  ############### En-/Decoding Access token ###############
  #########################################################
  # The Access class is responsible for handling access tokens.
  class Access
    HMAC_SECRET = ENV.fetch('ACCESS_TOKEN_SECRET', nil)
    ALGORITHM_TYPE = 'HS256'
    ISSUER = Socket.gethostname

    def self.encode(sub, exp, typ, _scope = nil)
      payload = { sub:, exp:, typ: }
      AuthenticationTokenService.call(
        HMAC_SECRET, ALGORITHM_TYPE, ISSUER, payload
      )
    end

    def self.decode(token)
      # token decoding for an access token
      # this method decodes a jwt token
      JWT.decode(token, HMAC_SECRET, true,
                 { iss: ISSUER, verify_iss: true, required_claims: %w[iss sub exp typ], algorithm: ALGORITHM_TYPE })
    end

    # The Encoder class is responsible for generating access tokens.
    class Encoder
      def self.call(refresh_token)
        AuthenticationTokenService::Refresh::Decoder.call(refresh_token)[0]
        sub = Current.user.id # who "owns" the token
        # AuthenticationTokenService::Refresh.must_be_verified_id!(sub)
        # ApplicationController.must_be_verified!(sub)
        typ = Current.user.user_role
        exp = Time.now.to_i + 1200 # standard validity interval;: 1200 sec == 20 min
        AuthenticationTokenService::Access.encode(
          sub, exp, typ
        )
      end
    end

    # The Decoder class is responsible for decoding access tokens.
    class Decoder
      def self.call(token)
        raise CustomExceptions::InvalidInput::Access::Malformed if token.class != String
        raise CustomExceptions::InvalidInput::Access::Blank if token[0] == ':' || token.blank?

        AuthenticationTokenService::Access.decode(token)
      end
    end
  end
end
