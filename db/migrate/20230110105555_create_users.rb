class CreateUsers < ActiveRecord::Migration[7.0]
  def change
    create_enum :user_type, ["company", "private"]
    create_table "users", id: :integer, charset: "unicode", force: :cascade do |t|
      t.string "email", null: false
      t.string "password_digest"
      t.integer "activity_status", limit: 1, default: 0, null: false
      t.string "image_url", limit: 500
      t.string "first_name", null: false
      t.string "last_name", null: false
      t.float "longitude", null: false
      t.float "latitude", null: false
      t.string "country_code", limit: 45
      t.string "postal_code", limit: 45
      t.string "city", limit: 45
      t.string "address", limit: 45
      t.datetime "date_of_birth", null: false
      t.enum "user_type", enum_type: "user_type", default: "private", null: false
      t.index ["email"], name: "account_email_UNIQUE", unique: true
      t.timestamps
    end
  end
end
