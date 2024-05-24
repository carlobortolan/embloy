# frozen_string_literal: true

# The GeniusQueryService class is responsible for handling the server-side authorization
# part of the Genius application process. It includes two nested classes, Encoder and Decoder,
# which handle the encoding and decoding of tokens respectively.
class GeniusQueryService < AuthenticationTokenService
  HMAC_SECRET = ENV.fetch('GENIUS_QUERY_TOKEN_SECRET', nil)
  ALGORITHM_TYPE = 'HS256'
  ISSUER = 'api.embloy.com'
  REPLACEMENT_CHARACTER = '°'

  def self.encode(sub, exp, jti, iat, args)
    payload = { sub:, exp:, jti:,
                iat: }.merge(args)
    AuthenticationTokenService.call(HMAC_SECRET,
                                    ALGORITHM_TYPE, ISSUER, payload)
  end

  def self.decode(token)
    JWT.decode(token, HMAC_SECRET, true, { verify_jti: proc { |jti|
                                                         AuthenticationTokenService::Refresh.jti?(jti, token['sub'].to_i)
                                                       }, iss: ISSUER, verify_iss: true, verify_iat: true, required_claims: %w[iss sub exp jti iat], algorithm: ALGORITHM_TYPE })
  end

  def self.query(args)
    return unless args.key?('job_id') && !args.key('user_id')

    job = Job.find(args['job_id'])
    ApplicationController.user_not_blacklisted!(job.user_id)
    raise CustomExceptions::Subscription::ExpiredOrMissing unless job.user.active_subscription?

    raise CustomExceptions::InvalidInput::GeniusQuery::Removed unless %w[listed unlisted].include?(job.job_status) && job.activity_status == 1

    res = Job.json_for(job)
    { job: res }

    # elsif !args.key?('job_id') && args.key('user_id')
    # TODO: query users
    # []
    # elsif args.key?('job_id') && args.key('user_id')
    # # TODO: query applications
    #  []
    #    else
    #     []
  end

  # The Encoder class is responsible for encoding tokens.
  class Encoder
    MAX_INTERVAL = 1.year.to_i # == 12 months == 1 year
    MIN_INTERVAL = 1.minute.to_i # == 1 min

    # Encodes a token for a given user ID and arguments.
    def self.call(user_id, args)
      must_be_verified_and_args(user_id, args)
      iat, sub, bin_exp = prepare_token_values(user_id, args)
      GeniusQueryService.encode(sub, bin_exp, jti(iat), iat, args).gsub('.', REPLACEMENT_CHARACTER)
    end

    def self.must_be_verified_and_args(user_id, args)
      AuthenticationTokenService::Refresh.must_be_verified_id!(user_id)
      ApplicationController.must_be_verified!(user_id)
      ApplicationController.must_be_owner!(args['job_id'], user_id) if args.key?('job_id')
    end

    def self.prepare_token_values(user_id, args)
      iat = Time.now.to_i
      sub = user_id
      bin_exp = if args.include?('exp') && !args['exp'].nil?
                  args['exp'] = AuthenticationTokenService::Refresh.verify_expiration!(args['exp'] - iat, MAX_INTERVAL, MIN_INTERVAL)
                else
                  iat + 1.month.to_i # standard validity interval (1 month)
                end
      args.delete('exp')
      [iat, sub, bin_exp]
    end

    def self.jti(iat)
      AuthenticationTokenService::Refresh.jti(iat)
    end
  end

  # The Decoder class is responsible for decoding tokens.
  class Decoder
    def self.call(token)
      raise CustomExceptions::InvalidInput::GeniusQuery::Malformed if token.class != String
      raise CustomExceptions::InvalidInput::GeniusQuery::Blank if token[0] == ':' || token.blank?

      begin
        # necessary to shortcut actual JWT errors to prevent frontend from logging out due to 401s
        decoded_token = GeniusQueryService.decode(token.gsub(
                                                    REPLACEMENT_CHARACTER, '.'
                                                  ))[0]
      rescue StandardError
        raise CustomExceptions::InvalidInput::GeniusQuery::Malformed
      end
      GeniusQueryService.query(decoded_token)
    end
  end
end
