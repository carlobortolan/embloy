class Subscription < ApplicationRecord
    belongs_to :user
    has_many :payments, dependent: :delete_all

    validates :tier, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, 
                     inclusion: { in: %w[basic premium enterprise_1 enterprise_2 enterprise_3], "error": "ERR_INVALID", "description": "Attribute is invalid" }
    validates :active, inclusion: { in: [true, false], message: "ERR_NOT_BOOL" }
    validates :expiration_date, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
    validates :start_date, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
    validates :auto_renew, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }

    def activate
        # TODO: Check if payment was successful
        self.active = true
        self.save
    end

    def cancel
        # TODO: Cancel payment if possible
        self.active = false
        self.save!
    end

    def renew
        # TODO: Check if payment was successful
        self.active = true
        self.expiration_date = self.expiration_date + 6.month
        self.save
    end

    private

    def valid_subscription?
        self.expiration_date > Time.now.utc.to_date && active
    end
end
