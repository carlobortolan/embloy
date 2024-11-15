# frozen_string_literal: true

# user_dao.rb
module Dao
  # The UserDao class is responsible for defining the serialization rules for a User object. This includes specifying which attributes should be included in the serialized output.
  module UserDao
    extend ActiveSupport::Concern

    def dao(*) # rubocop:disable Metrics/AbcSize
      user = {}
      user[:user] = {
        id: id,
        email: email,
        first_name: first_name,
        last_name: last_name,
        date_of_birth: date_of_birth,
        longitude: longitude,
        latitude: latitude,
        country_code: country_code,
        postal_code: postal_code,
        city: city,
        address: address,
        activity_status: activity_status,
        user_role: user_role,
        type: type,
        view_count: view_count,
        applications_count: applications_count,
        jobs_count: jobs_count,
        linkedin_url: linkedin_url,
        instagram_url: instagram_url,
        twitter_url: twitter_url,
        facebook_url: facebook_url,
        github_url: github_url,
        portfolio_url: portfolio_url,
        phone: phone,
        application_notifications: application_notifications,
        communication_notifications: communication_notifications,
        marketing_notifications: marketing_notifications,
        security_notifications: security_notifications,
        image_url: image_url&.url || '',
        created_at: created_at,
        updated_at: updated_at
      }
      user[:preferences] = preferences if preferences
      user
    end
  end
end
