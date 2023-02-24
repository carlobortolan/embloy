# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.0].define(version: 2023_01_12_113311) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum "application_status", ["-1", "0", "1"]
  create_enum "notify_type", ["0", "1"]
  create_enum "rating_type", ["1", "2", "3", "4", "5"]
  create_enum "user_type", ["company", "private"]

  create_table "applications", primary_key: ["job_id", "applicant_id"], force: :cascade do |t|
    t.integer "job_id", null: false
    t.integer "applicant_id", null: false
    t.datetime "updated_at", default: "2023-02-24 19:10:51", null: false
    t.enum "status", default: "0", null: false, enum_type: "application_status"
    t.string "application_text", limit: 1000
    t.string "application_documents", limit: 100
    t.string "response", limit: 500
    t.index ["applicant_id"], name: "account_id_idx"
    t.index ["job_id", "applicant_id"], name: "index_applications_on_job_id_and_applicant_id", unique: true
  end

  create_table "auth_blacklists", force: :cascade do |t|
    t.string "token", limit: 500, null: false
    t.integer "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["token"], name: "token_UNIQUE", unique: true
  end

  create_table "company_users", id: :serial, force: :cascade do |t|
    t.string "company_name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "currents", force: :cascade do |t|
    t.datetime "created_at", default: "2023-02-24 19:10:52", null: false
    t.datetime "updated_at", default: "2023-02-24 19:10:52", null: false
  end

  create_table "jobs", primary_key: "job_id", id: :serial, force: :cascade do |t|
    t.string "job_type"
    t.integer "job_status", limit: 2, default: 0
    t.integer "user_id", default: 0
    t.integer "duration", default: 0
    t.string "code_lang", limit: 2
    t.string "title", limit: 100
    t.string "position", limit: 100
    t.text "description"
    t.string "key_skills", limit: 100
    t.integer "salary"
    t.string "currency"
    t.string "image_url", limit: 500
    t.datetime "start_slot", precision: nil
    t.float "longitude", null: false
    t.float "latitude", null: false
    t.string "country_code", limit: 45
    t.string "postal_code", limit: 45
    t.string "city", limit: 45
    t.string "address", limit: 45
    t.integer "view_count", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "job_information_account_id_idx"
  end

  create_table "notifications", primary_key: ["employer_id", "job_id"], force: :cascade do |t|
    t.integer "employer_id", null: false
    t.integer "job_id", null: false
    t.enum "notify", default: "0", null: false, enum_type: "notify_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["job_id"], name: "notification_job_id_idx"
  end

  create_table "private_users", id: :serial, force: :cascade do |t|
    t.string "private_attr"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "reviews", primary_key: "user_id", id: :serial, force: :cascade do |t|
    t.enum "rating", default: "1", null: false, enum_type: "rating_type"
    t.text "message"
    t.integer "created_by", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_by"], name: "fk_rails_50d2809d9b"
  end

  create_table "user_blacklists", force: :cascade do |t|
    t.integer "user_id", null: false
    t.integer "reason"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "user_id_UNIQUE", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest"
    t.integer "activity_status", limit: 2, default: 0, null: false
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
    t.enum "user_type", default: "private", null: false, enum_type: "user_type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "account_email_UNIQUE", unique: true
  end

  add_foreign_key "applications", "jobs", primary_key: "job_id"
  add_foreign_key "applications", "users", column: "applicant_id"
  add_foreign_key "company_users", "users", column: "id"
  add_foreign_key "jobs", "users"
  add_foreign_key "notifications", "jobs", primary_key: "job_id"
  add_foreign_key "notifications", "users", column: "employer_id"
  add_foreign_key "private_users", "users", column: "id"
  add_foreign_key "reviews", "users", column: "created_by"
end
