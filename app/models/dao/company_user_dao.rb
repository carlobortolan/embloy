# frozen_string_literal: true

# company_user_dao.rb
module Dao
  # The CompanyUserDao class is responsible for defining the serialization rules for a CompanyUser object. This includes specifying which attributes should be included in the serialized output.
  module CompanyUserDao
    extend ActiveSupport::Concern
    def dao(include_user: false)
      company = {}
      company.merge!(super()) if include_user
      company[:company] = {
        id: id,
        company_name: company_name,
        company_phone: company_phone,
        company_email: company_email,
        company_urls: company_urls,
        company_industry: company_industry,
        company_description: company_description,
        company_logo: company_logo&.url || '',
        company_slug: company_slug
      }
      company
    end
  end
end
