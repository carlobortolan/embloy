# frozen_string_literal: true

# Represents a special User class used for company users
class CompanyUser < User
  validates :company_name, presence: true
  belongs_to :user
end
