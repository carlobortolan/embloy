# frozen_string_literal: true

require 'faraday'
require 'tempfile'

# OauthCallbacksController handles oauth-related actions
class OauthCallbacksController < ApplicationController
  skip_before_action :require_user_not_blacklisted!

  def github
    authenticate
    # TODO: FETCH ADDITIONAL METADATA
  end

  def google
    authenticate
    # TODO: FETCH ADDITIONAL METADATA
  end

  def azure
    authenticate
    # TODO: FETCH ADDITIONAL METADATA
  end

  def linkedin
    authenticate
    # TODO: FETCH ADDITIONAL METADATA
  end

  def auth
    puts "auth=#{request.env['omniauth.auth']}"
    request.env['omniauth.auth']
  end

  private

  #   def authenticate
  #     if auth.info.email.nil?
  #       flash[:alert] = 'Invalid email or password'
  #       render :new, status: :bad_request
  #     else
  #       user = User.find_by(email: auth.info.email)
  #       if user.present? # && user.authenticate(auth.credentials.token)
  #         refresh_token = AuthenticationTokenService::Refresh::Encoder.call(user.id.to_i)
  #         redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}?refresh_token=#{refresh_token}", allow_other_host: true) and return
  #       else
  #         pw = SecureRandom.hex
  #         user = User.new(
  #           email: auth.info.email,
  #           password: pw,
  #           password_confirmation: pw,
  #           first_name: auth.info.name.split[0],
  #           last_name: auth.info.name.split[1],
  #           user_role: 'verified',
  #           activity_status: '1'
  #         )
  #
  #         if user.save!
  #           begin
  #             response = Faraday.get(auth.info.image)
  #             raise 'Unable to download image' unless response.success?
  #
  #             Tempfile.open(['image', '.jpg']) do |tempfile|
  #               tempfile.binmode
  #               tempfile.write(response.body)
  #               tempfile.rewind
  #
  #               user.image_url.attach(io: tempfile, filename: 'image.jpg', content_type: response.headers['content-type'])
  #             end
  #           rescue StandardError => e
  #             render status: 400, message: "Failed to download image: #{e.message}" and return
  #           end
  #           WelcomeMailer.with(user:).welcome_email.deliver_later
  #           refresh_token = AuthenticationTokenService::Refresh::Encoder.call(user.id.to_i)
  #           redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}?refresh_token=#{refresh_token}", allow_other_host: true) and return
  #         end
  #       end
  #     end
  #     redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/register", allow_other_host: true)
  #   end
  def authenticate
    if auth.info.email.nil?
      redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?error=Invalid email or password", allow_other_host: true) and return
    else
      user = User.find_by(email: auth.info.email)
      user.present? ? handle_existing_user(user) : handle_new_user
    end
  end

  def handle_existing_user(user)
    refresh_token = AuthenticationTokenService::Refresh::Encoder.call(user.id.to_i)
    redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?refresh_token=#{refresh_token}", allow_other_host: true) and return
  end

  def handle_new_user
    user = create_new_user
    return unless user.save!

    attach_user_image(user)
    WelcomeMailer.with(user:).welcome_email.deliver_later
    refresh_token = AuthenticationTokenService::Refresh::Encoder.call(user.id.to_i)
    redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?refresh_token=#{refresh_token}", allow_other_host: true) and return
  end

  def create_new_user
    pw = SecureRandom.hex
    User.new(
      email: auth.info.email,
      password: pw,
      password_confirmation: pw,
      first_name: auth.info.name.split[0],
      last_name: auth.info.name.split[1],
      user_role: 'verified',
      activity_status: '1'
    )
  end

  def attach_user_image(user)
    return unless auth.info.image

    response = Faraday.get(auth.info.image)
    raise 'Unable to download image' unless response.success?

    Tempfile.open(['image', '.jpg']) do |tempfile|
      tempfile.binmode
      tempfile.write(response.body)
      tempfile.rewind

      user.image_url.attach(io: tempfile, filename: 'image.jpg', content_type: response.headers['content-type'])
    end
  rescue StandardError => e
    redirect_to("#{ENV.fetch('CORE_CLIENT_URL')}/oauth/redirect?error=#{e.message}", allow_other_host: true) and return
  end
end
