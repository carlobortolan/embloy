class PrivateUser < User
  validates :private_attr, presence: true
  belongs_to :user
end
