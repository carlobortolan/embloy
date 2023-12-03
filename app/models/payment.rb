class Payment < ApplicationRecord
    belongs_to :subscription

    validates :payment_method, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, inclusion: { in: %w[credit_card debit_card bank_transfer paypal], "error": "ERR_INVALID", "description": "Attribute is invalid" }
    validates :payment_status, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }, inclusion: { in: %w[pending paid failed cancelled], "error": "ERR_INVALID", "description": "Attribute is invalid" }
    validates :payment_date, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
    validates :payment_amount, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
    validates :payment_currency, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
    validates :payment_description, presence: { "error": "ERR_BLANK", "description": "Attribute can't be blank" }
end