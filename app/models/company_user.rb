class CompanyUser < User
  validates :company_name, presence: true
  belongs_to :user
end
