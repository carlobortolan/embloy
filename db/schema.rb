# frozen_string_literal: true

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

ActiveRecord::Schema[7.0].define(version: 20_240_114_012_806) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_trgm'
  enable_extension 'plpgsql'
  enable_extension 'postgis'
  enable_extension 'unaccent'

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum 'allowed_cv_format', ['.pdf', '.docx', '.txt', '.xml']
  create_enum 'application_status', ['-1', '0', '1']
  create_enum 'job_status', %w[public private archived]
  create_enum 'notify_type', %w[0 1]
  create_enum 'rating_type', %w[1 2 3 4 5]
  create_enum 'user_role', %w[admin editor developer moderator verified spectator]
  create_enum 'user_type', %w[company private]
  create_enum 'question_type', %w[yes_no text link single_choice multiple_choice]

  create_table 'action_text_rich_texts', force: :cascade do |t|
    t.string 'name', null: false
    t.text 'body'
    t.string 'record_type', null: false
    t.bigint 'record_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[record_type record_id name], name: 'index_action_text_rich_texts_uniqueness', unique: true
  end

  create_table 'active_storage_attachments', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'record_type', null: false
    t.bigint 'record_id', null: false
    t.bigint 'blob_id', null: false
    t.datetime 'created_at', null: false
    t.index ['blob_id'], name: 'index_active_storage_attachments_on_blob_id'
    t.index %w[record_type record_id name blob_id], name: 'index_active_storage_attachments_uniqueness', unique: true
  end

  create_table 'active_storage_blobs', force: :cascade do |t|
    t.string 'key', null: false
    t.string 'filename', null: false
    t.string 'content_type'
    t.text 'metadata'
    t.string 'service_name', null: false
    t.bigint 'byte_size', null: false
    t.string 'checksum'
    t.datetime 'created_at', null: false
    t.index ['key'], name: 'index_active_storage_blobs_on_key', unique: true
  end

  create_table 'active_storage_variant_records', force: :cascade do |t|
    t.bigint 'blob_id', null: false
    t.string 'variation_digest', null: false
    t.index %w[blob_id variation_digest], name: 'index_active_storage_variant_records_uniqueness', unique: true
  end

  create_table 'application_attachments', id: :serial, force: :cascade do |t|
    t.integer 'user_id', null: false
    t.integer 'job_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[job_id user_id], name: 'application_attachment_job_id_user_id_index', unique: true
    t.index ['job_id'], name: 'application_attachment_job_id_index'
    t.index ['user_id'], name: 'application_attachment_user_id_index'
  end

  create_table 'applications', primary_key: %w[job_id user_id], force: :cascade do |t|
    t.integer 'job_id', null: false
    t.integer 'user_id', null: false
    t.datetime 'updated_at', default: '2023-02-27 23:06:10', null: false
    t.datetime 'created_at', default: '2023-02-27 23:06:10', null: false
    t.enum 'status', default: '0', null: false, enum_type: 'application_status'
    t.string 'application_text', limit: 1000
    t.string 'application_documents', limit: 150
    t.string 'response', limit: 500
    t.datetime 'deleted_at'
    t.index ['deleted_at'], name: 'index_applications_on_deleted_at'
    t.index %w[job_id user_id], name: 'application_job_id_user_id_index', unique: true
    t.index ['job_id'], name: 'application_job_id_index'
    t.index ['user_id'], name: 'application_user_id_index'
  end

  create_table 'auth_blacklists', force: :cascade do |t|
    t.string 'token', limit: 500, null: false
    t.integer 'reason'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['token'], name: 'token_UNIQUE', unique: true
  end

  create_table 'company_users', id: :serial, force: :cascade do |t|
    t.string 'company_name'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'currents', force: :cascade do |t|
    t.datetime 'created_at', default: '2023-02-27 23:06:11', null: false
    t.datetime 'updated_at', default: '2023-02-27 23:06:11', null: false
  end

  create_table 'jobs', primary_key: 'job_id', id: :serial, force: :cascade do |t|
    t.string 'job_type'
    t.string 'job_slug', null: false, limit: 100
    t.integer 'job_type_value'
    t.integer 'job_status', limit: 2, default: 0
    t.enum 'status', default: 'public', null: false, enum_type: 'job_status'
    t.integer 'user_id', default: 0
    t.string 'referrer_url'
    t.integer 'duration', default: 0
    t.string 'code_lang', limit: 2
    t.string 'title', limit: 100
    t.string 'position', limit: 100
    t.text 'description'
    t.string 'key_skills', limit: 100
    t.integer 'salary'
    t.integer 'euro_salary'
    t.float 'relevance_score'
    t.string 'currency'
    t.string 'image_url', limit: 500
    t.datetime 'start_slot', precision: nil
    t.float 'longitude', null: false
    t.float 'latitude', null: false
    t.string 'country_code', limit: 45
    t.string 'postal_code', limit: 45
    t.string 'city', limit: 45
    t.string 'address', limit: 150
    t.integer 'view_count', default: 0, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'applications_count', default: 0, null: false
    t.integer 'employer_rating', default: 0, null: false
    t.text 'job_notifications', default: '1', null: false
    t.integer 'boost', default: 0, null: false
    t.boolean 'cv_required', null: false, default: false
    t.string 'allowed_cv_formats', default: ['.pdf', '.docx', '.txt', '.xml'], null: false, array: true
    t.datetime 'deleted_at'
    t.index ['job_slug'], name: ' job_job_slug_index '
    t.index ['country_code'], name: ' job_country_code_index '
    t.index ['job_id'], name: 'job_job_id_index'
    t.index ['postal_code'], name: ' job_postal_code_index '
    t.index ['user_id'], name: 'job_user_id_index '
    t.index ['position'], name: 'job_position_index '
    t.index ['job_type'], name: 'job_job_type_index '
    t.index ['deleted_at'], name: 'index_jobs_on_deleted_at'
  end

  execute('ALTER TABLE jobs ADD COLUMN job_value public.geography(PointZ,4326);CREATE INDEX IF NOT EXISTS job_job_value_index ON public.jobs USING gist(job_value)TABLESPACE pg_default;')
  execute("CREATE INDEX jobs_tsvector_idx ON jobs USING gin(to_tsvector('simple', coalesce(title,'') || ' ' || coalesce(job_type,'') || ' ' || coalesce(position,'') || ' ' || coalesce(key_skills,'') || ' ' || coalesce(description,'') || ' ' || coalesce(country_code,'') || ' ' || coalesce(city,'') || ' ' || coalesce(postal_code,'') || ' ' || coalesce(address,'')));")
  execute('CREATE EXTENSION IF NOT EXISTS pg_trgm;')
  execute('CREATE INDEX IF NOT EXISTS jobs_title_trgm_idx ON jobs USING gin(title gin_trgm_ops);CREATE INDEX IF NOT EXISTS jobs_job_type_trgm_idx ON jobs USING gin(job_type gin_trgm_ops);')
  execute('CREATE EXTENSION IF NOT EXISTS unaccent;')

  create_table 'application_options', force: :cascade do |t|
    t.bigint 'job_id', null: false
    t.string 'question', null: false, limit: 200
    t.enum 'question_type', default: 'yes_no', null: false, enum_type: 'question_type'
    t.boolean 'required', default: true
    t.text 'options'
    t.datetime 'created_at', precision: 6, null: false
    t.datetime 'updated_at', precision: 6, null: false
    t.datetime 'deleted_at'
    t.index ['job_id'], name: 'application_options_job_id_index'
    t.index ['deleted_at'], name: 'index_application_options_on_deleted_at'
  end

  create_table 'notifications', force: :cascade do |t|
    t.string 'recipient_type', null: false
    t.bigint 'recipient_id', null: false
    t.string 'type', null: false
    t.jsonb 'params'
    t.datetime 'read_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['read_at'], name: 'index_notifications_on_read_at'
    t.index %w[recipient_type recipient_id], name: 'index_notifications_on_recipient'
  end

  create_table 'pay_charges', force: :cascade do |t|
    t.bigint 'customer_id', null: false
    t.bigint 'subscription_id'
    t.string 'processor_id', null: false
    t.integer 'amount', null: false
    t.string 'currency'
    t.integer 'application_fee_amount'
    t.integer 'amount_refunded'
    t.jsonb 'metadata'
    t.jsonb 'data'
    t.string 'stripe_account'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[customer_id processor_id], name: 'index_pay_charges_on_customer_id_and_processor_id', unique: true
    t.index ['subscription_id'], name: 'index_pay_charges_on_subscription_id'
  end

  create_table 'pay_customers', force: :cascade do |t|
    t.string 'owner_type'
    t.bigint 'owner_id'
    t.string 'processor', null: false
    t.string 'processor_id'
    t.boolean 'default'
    t.jsonb 'data'
    t.string 'stripe_account'
    t.datetime 'deleted_at', precision: nil
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[owner_type owner_id deleted_at], name: 'pay_customer_owner_index', unique: true
    t.index %w[processor processor_id], name: 'index_pay_customers_on_processor_and_processor_id', unique: true
  end

  create_table 'pay_merchants', force: :cascade do |t|
    t.string 'owner_type'
    t.bigint 'owner_id'
    t.string 'processor', null: false
    t.string 'processor_id'
    t.boolean 'default'
    t.jsonb 'data'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[owner_type owner_id processor], name: 'index_pay_merchants_on_owner_type_and_owner_id_and_processor'
  end

  create_table 'pay_payment_methods', force: :cascade do |t|
    t.bigint 'customer_id', null: false
    t.string 'processor_id', null: false
    t.boolean 'default'
    t.string 'type'
    t.jsonb 'data'
    t.string 'stripe_account'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[customer_id processor_id], name: 'index_pay_payment_methods_on_customer_id_and_processor_id', unique: true
  end

  create_table 'pay_subscriptions', force: :cascade do |t|
    t.bigint 'customer_id', null: false
    t.string 'name', null: false
    t.string 'processor_id', null: false
    t.string 'processor_plan', null: false
    t.integer 'quantity', default: 1, null: false
    t.string 'status', null: false
    t.datetime 'current_period_start', precision: nil
    t.datetime 'current_period_end', precision: nil
    t.datetime 'trial_ends_at', precision: nil
    t.datetime 'ends_at', precision: nil
    t.boolean 'metered'
    t.string 'pause_behavior'
    t.datetime 'pause_starts_at', precision: nil
    t.datetime 'pause_resumes_at', precision: nil
    t.decimal 'application_fee_percent', precision: 8, scale: 2
    t.jsonb 'metadata'
    t.jsonb 'data'
    t.string 'stripe_account'
    t.string 'payment_method_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[customer_id processor_id], name: 'index_pay_subscriptions_on_customer_id_and_processor_id', unique: true
    t.index ['metered'], name: 'index_pay_subscriptions_on_metered'
    t.index ['pause_starts_at'], name: 'index_pay_subscriptions_on_pause_starts_at'
  end

  create_table 'pay_webhooks', force: :cascade do |t|
    t.string 'processor'
    t.string 'event_type'
    t.jsonb 'event'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'pg_search_documents', force: :cascade do |t|
    t.text 'content'
    t.string 'searchable_type'
    t.bigint 'searchable_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[searchable_type searchable_id], name: 'index_pg_search_documents_on_searchable'
  end

  create_table 'preferences', id: :serial, force: :cascade do |t|
    t.integer 'user_id', null: false
    t.string 'interests', limit: 100
    t.string 'experience', limit: 100
    t.string 'degree', limit: 100
    t.integer 'num_jobs_done', default: 0
    t.string 'gender', limit: 10
    t.float 'spontaneity'
    t.jsonb 'job_types', default: { '1' => 0, '2' => 0, '3' => 0 }
    t.jsonb 'key_skills'
    t.float 'salary_range', default: [0.0, 0.0], array: true
    t.string 'cv_url', limit: 500
    t.datetime 'deleted_at'
    t.index ['deleted_at'], name: 'index_preferences_on_deleted_at'
  end

  create_table 'private_users', id: :serial, force: :cascade do |t|
    t.string 'private_attr'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'reviews', primary_key: 'review_id', id: :serial, force: :cascade do |t|
    t.enum 'rating', default: '1', null: false, enum_type: 'rating_type'
    t.integer 'user_id', null: false
    t.integer 'created_by', null: false
    t.text 'message'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'job_id'
    t.integer 'subject', null: false
    t.datetime 'deleted_at'
    t.index ['created_by'], name: 'reviews_created_by_index'
    t.index ['deleted_at'], name: 'index_reviews_on_deleted_at'
  end

  create_table 'user_blacklists', force: :cascade do |t|
    t.integer 'user_id', null: false
    t.integer 'reason'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'user_id_UNIQUE', unique: true
  end

  create_table 'users', id: :serial, force: :cascade do |t|
    t.string 'email', null: false
    t.string 'password_digest'
    t.integer 'activity_status', limit: 2, default: 0, null: false
    t.string 'image_url', limit: 500
    t.string 'first_name', null: false
    t.string 'last_name', null: false
    t.float 'longitude'
    t.float 'latitude'
    t.string 'country_code', limit: 45
    t.string 'postal_code', limit: 45
    t.string 'city', limit: 45
    t.string 'address', limit: 150
    t.datetime 'date_of_birth'
    t.enum 'user_type', default: 'private', null: false, enum_type: 'user_type'
    t.integer 'view_count', default: 0, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'applications_count', default: 0
    t.integer 'jobs_count', default: 0
    t.enum 'user_role', default: 'spectator', null: false, enum_type: 'user_role'
    t.boolean 'application_notifications', default: true, null: false
    t.string 'twitter_url', limit: 500
    t.string 'facebook_url', limit: 500
    t.string 'instagram_url', limit: 500
    t.decimal 'phone'
    t.string 'degree', limit: 50
    t.string 'linkedin_url', limit: 500
    t.index ['email'], name: 'user_email_index', unique: true
    t.index %w[first_name last_name], name: 'user_name_index'
    t.index ['user_type'], name: 'user_user_type_index'
  end

  add_foreign_key 'active_storage_attachments', 'active_storage_blobs', column: 'blob_id'
  add_foreign_key 'active_storage_variant_records', 'active_storage_blobs', column: 'blob_id'
  add_foreign_key 'applications', 'jobs', primary_key: 'job_id', on_delete: :cascade
  add_foreign_key 'applications', 'users', on_delete: :cascade
  add_foreign_key 'company_users', 'users', column: 'id', on_delete: :cascade
  add_foreign_key 'jobs', 'users', on_delete: :cascade
  add_foreign_key 'pay_charges', 'pay_customers', column: 'customer_id'
  add_foreign_key 'pay_charges', 'pay_subscriptions', column: 'subscription_id'
  add_foreign_key 'pay_payment_methods', 'pay_customers', column: 'customer_id'
  add_foreign_key 'pay_subscriptions', 'pay_customers', column: 'customer_id'
  add_foreign_key 'preferences', 'users', on_delete: :cascade
  add_foreign_key 'private_users', 'users', column: 'id', on_delete: :cascade
  add_foreign_key 'reviews', 'jobs', primary_key: 'job_id'
  add_foreign_key 'reviews', 'users'
  add_foreign_key 'reviews', 'users', column: 'created_by'
  add_foreign_key 'user_blacklists', 'users', on_delete: :cascade
end
