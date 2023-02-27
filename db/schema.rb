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

ActiveRecord::Schema[7.0].define(version: 2023_02_27_201122) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"
  create_enum :notify_type, ['0', '1']
  create_enum :user_type, ["company", "private"]
  create_enum :application_status, ['-1', '0', '1']
  create_enum :job_status, ['public', 'private', 'archieved']
  create_enum :rating_type, ["1", "2", "3", "4", "5"]

  create_table :job_notifications, primary_key: [:employer_id, :job_id], charset: "unicode", force: :cascade do |t|
    t.integer :employer_id, null: false
    t.integer :job_id, null: false
    t.enum :notify, enum_type: "notify_type", default: '0', null: false
    t.index [:job_id], name: "notification_job_id_index"
    t.timestamps
  end
  create_table :users, id: :integer, charset: "unicode", force: :cascade do |t|
    t.string :email, null: false
    t.string :password_digest
    t.integer :activity_status, limit: 1, default: 0, null: false
    t.string :image_url, limit: 500
    t.string :first_name, null: false
    t.string :last_name, null: false
    t.float :longitude, null: true
    t.float :latitude, null: true
    t.string :country_code, limit: 45
    t.string :postal_code, limit: 45
    t.string :city, limit: 45
    t.string :address, limit: 45
    t.datetime :date_of_birth, null: true
    t.enum :user_type, enum_type: "user_type", default: "private", null: false
    t.integer :view_count, default: 0, null: false
    t.index [:email], name: "user_email_index", unique: true
    t.index [:first_name, :last_name], name: "user_name_index", unique: false
    t.index [:user_type], name: "user_user_type_index", unique: false
    t.timestamps
  end
  create_table :applications, primary_key: [:job_id, :user_id], charset: "unicode", force: :cascade do |t|
    t.integer :job_id, null: false
    # t.integer "applicant_id", null: false
    #      t.datetime "applied_at", default: -> { DateTime.now }
    #      t.column(:applied_at, :datetime)
    t.integer :user_id, null: false
    t.datetime :updated_at, default: DateTime.now, null: false
    t.datetime :applied_at, default: DateTime.now, null: false
    t.enum :status, enum_type: "application_status", default: '0', null: false
    t.string :application_text, limit: 1000
    t.string :application_documents, limit: 100
    t.string :response, limit: 500
    t.index [:user_id], name: "application_user_id_index"
    t.index [:job_id], name: "application_job_id_index"
    t.index [:job_id, :user_id], name: "application_job_id_user_id_index", unique: true
  end
  create_table :currents, charset: "unicode", force: :cascade do |t|
    t.datetime :created_at, default: DateTime.now, null: false
    t.datetime :updated_at, default: DateTime.now, null: false
  end
  create_table :jobs, primary_key: :job_id, id: :integer, charset: "unicode", force: :cascade do |t|
    t.string :job_type
    t.integer :job_status, limit: 1, default: 0
    t.enum :status, enum_type: "job_status", default: 'public', null: false
    t.integer :user_id, default: 0
    t.integer :duration, default: 0
    t.string :code_lang, limit: 2
    t.string :title, limit: 100
    t.string :position, limit: 100
    t.text :description
    t.string :key_skills, limit: 100
    t.integer :salary
    t.string :currency
    t.string :image_url, limit: 500
    t.datetime :start_slot, precision: nil
    t.float :longitude, null: false
    t.float :latitude, null: false
    t.string :country_code, limit: 45
    t.string :postal_code, limit: 45
    t.string :city, limit: 45
    t.string :address, limit: 45
    t.integer :view_count, default: 0, null: false
    t.timestamps
    t.index [:job_id], name: "job_job_id_index"
    t.index [:user_id], name: "job_user_id_index "
    t.index [:country_code], name: " job_country_code_index "
    t.index [:postal_code], name: " job_postal_code_index "
  end
  create_table :reviews, primary_key: :user_id, id: :integer, charset: "unicode", force: :cascade do |t|
    t.enum :rating, enum_type: "rating_type", default: "1", null: false
    t.text :message
    t.integer :created_by, null: false
    t.timestamps
    t.index [:created_by], name: "reviews_created_by_index"
  end
  create_table :private_users, id: :integer, charset: "unicode", force: :cascade do |t|
    t.string :private_attr
    t.timestamps
  end
  create_table :company_users, id: :integer, charset: "unicode", force: :cascade do |t|
    t.string :company_name
    t.timestamps
  end
  create_table :auth_blacklists do |t|
    t.string :token, null: false, limit: 500
    t.integer :reason, null: true
    t.timestamps
    t.index [:token], name: "token_UNIQUE", unique: true
  end
  create_table :user_blacklists do |t|
    t.integer :user_id, null: false
    t.integer :reason
    t.timestamps
    t.index [:user_id], name: "user_id_UNIQUE", unique: true
  end
  create_table :notifications do |t|
    t.references :recipient, polymorphic: true, null: false
    t.string :type, null: false
    t.jsonb :params
    t.datetime :read_at
    t.timestamps
  end
  add_index :notifications, :read_at

  add_foreign_key :private_users, :users, column: :id, primary_key: :id, on_delete: :cascade
  add_foreign_key :company_users, :users, column: :id, primary_key: :id, on_delete: :cascade

  add_foreign_key :jobs, :users, column: :user_id, primary_key: :id, on_delete: :cascade

  add_foreign_key :applications, :users, column: :user_id, primary_key: :id, on_delete: :cascade
  add_foreign_key :applications, :jobs, column: :job_id, primary_key: :job_id, on_delete: :cascade

  add_foreign_key :job_notifications, :users, column: :employer_id, primary_key: :id, on_delete: :cascade
  add_foreign_key :job_notifications, :jobs, column: :job_id, primary_key: :job_id, on_delete: :cascade

  add_foreign_key :reviews, :users, column: :created_by, primary_key: :id

end
