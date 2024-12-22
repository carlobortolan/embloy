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

ActiveRecord::Schema[7.0].define(version: 20_241_220_233_324) do
  # These are extensions that must be enabled in order to support this database
  enable_extension 'pg_trgm'
  enable_extension 'plpgsql'
  enable_extension 'postgis'
  enable_extension 'unaccent'

  # Custom types defined in this database.
  # Note that some types may not work with other database engines. Be careful if changing database.
  create_enum 'application_status', ['-1', '0', '1']
  create_enum 'job_status', %w[listed unlisted archived]
  create_enum 'notify_type', %w[0 1]
  create_enum 'question_type', %w[yes_no short_text long_text number link single_choice multiple_choice location file date]
  create_enum 'rating_type', %w[1 2 3 4 5]
  create_enum 'user_role', %w[admin editor developer moderator verified spectator]

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

  create_table 'admins', force: :cascade do |t|
    t.string 'email', default: '', null: false
    t.string 'encrypted_password', default: '', null: false
    t.string 'reset_password_token'
    t.datetime 'reset_password_sent_at'
    t.datetime 'remember_created_at'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.datetime 'locked_at'
    t.integer 'failed_attempts'
    t.string 'unlock_token'
    t.datetime 'unlocked_at'
    t.datetime 'current_sign_in_at'
    t.datetime 'last_sign_in_at'
    t.string 'current_sign_in_ip'
    t.string 'last_sign_in_ip'
    t.integer 'sign_in_count', default: 0
    t.index ['email'], name: 'index_admins_on_email', unique: true
    t.index ['reset_password_token'], name: 'index_admins_on_reset_password_token', unique: true
  end

  create_table 'application_answers', force: :cascade do |t|
    t.bigint 'job_id', null: false
    t.bigint 'user_id', null: false
    t.bigint 'application_option_id', null: false
    t.text 'answer'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.datetime 'deleted_at'
    t.integer 'version', default: 1, null: false
    t.index ['application_option_id'], name: 'application_answers_on_application_option_id_index'
    t.index ['deleted_at'], name: 'index_application_answers_on_deleted_at'
    t.index ['job_id'], name: 'application_answers_job_id_index'
    t.index ['user_id'], name: 'application_answers_user_id_index'
  end

  create_table 'application_events', force: :cascade do |t|
    t.string 'ext_id', limit: 100
    t.bigint 'job_id', null: false
    t.bigint 'user_id', null: false
    t.string 'event_type', limit: 50
    t.text 'event_details'
    t.bigint 'previous_event_id'
    t.bigint 'next_event_id'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['next_event_id'], name: 'index_application_events_on_next_event_id'
    t.index ['previous_event_id'], name: 'index_application_events_on_previous_event_id'
  end

  create_table 'application_options', force: :cascade do |t|
    t.bigint 'job_id', null: false
    t.string 'ext_id', limit: 100
    t.string 'question', limit: 500, null: false
    t.enum 'question_type', default: 'yes_no', null: false, enum_type: 'question_type'
    t.boolean 'required', default: true
    t.text 'options'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.datetime 'deleted_at'
    t.index ['deleted_at'], name: 'index_application_options_on_deleted_at'
    t.index %w[job_id ext_id], name: 'index_application_options_on_job_id_and_ext_id', unique: true
    t.index ['job_id'], name: 'application_options_job_id_index'
  end

  create_table 'applications', primary_key: %w[job_id user_id], force: :cascade do |t|
    t.integer 'job_id', null: false
    t.integer 'user_id', null: false
    t.string 'ext_id', limit: 100
    t.datetime 'updated_at', null: false
    t.datetime 'created_at', null: false
    t.enum 'status', default: '0', null: false, enum_type: 'application_status'
    t.string 'response', limit: 500
    t.datetime 'deleted_at'
    t.integer 'version', default: 1, null: false
    t.datetime 'submitted_at'
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
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
  end

  create_table 'job_list_items', force: :cascade do |t|
    t.bigint 'job_id', null: false
    t.bigint 'job_list_id', null: false
    t.text 'notes'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index %w[job_id job_list_id], name: 'index_job_list_items_on_job_id_and_job_list_id', unique: true
    t.index ['job_id'], name: 'index_job_list_items_on_job_id'
    t.index ['job_list_id'], name: 'index_job_list_items_on_job_list_id'
  end

  create_table 'job_lists', force: :cascade do |t|
    t.string 'name'
    t.bigint 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'index_job_lists_on_user_id'
  end

  create_table 'jobs', primary_key: 'job_id', id: :serial, force: :cascade do |t|
    t.string 'job_type'
    t.string 'job_slug', limit: 100, null: false
    t.integer 'activity_status', limit: 2, default: 1, null: false
    t.enum 'job_status', default: 'listed', null: false, enum_type: 'job_status'
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
    t.datetime 'deleted_at'
    t.geography 'job_value', limit: { srid: 4326, type: 'st_point', has_z: true, geographic: true }
    t.integer 'application_options_count', default: 0
    t.index "to_tsvector('simple'::regconfig, (((((((((((((((((COALESCE(title, ''::character varying))::text || ' '::text) || (COALESCE(job_type, ''::character varying))::text) || ' '::text) || (COALESCE(\"position\", ''::character varying))::text) || ' '::text) || (COALESCE(key_skills, ''::character varying))::text) || ' '::text) || COALESCE(description, ''::text)) || ' '::text) || (COALESCE(country_code, ''::character varying))::text) || ' '::text) || (COALESCE(city, ''::character varying))::text) || ' '::text) || (COALESCE(postal_code, ''::character varying))::text) || ' '::text) || (COALESCE(address, ''::character varying))::text))",
            name: 'jobs_tsvector_idx', using: :gin
    t.index ['country_code'], name: ' job_country_code_index '
    t.index ['deleted_at'], name: 'index_jobs_on_deleted_at'
    t.index ['job_id'], name: 'job_job_id_index'
    t.index ['job_slug'], name: ' job_job_slug_index '
    t.index ['job_type'], name: 'job_job_type_index '
    t.index ['job_type'], name: 'jobs_job_type_trgm_idx', opclass: :gin_trgm_ops, using: :gin
    t.index ['job_value'], name: 'job_job_value_index', using: :gist
    t.index ['position'], name: 'job_position_index '
    t.index ['postal_code'], name: ' job_postal_code_index '
    t.index ['title'], name: 'jobs_title_trgm_idx', opclass: :gin_trgm_ops, using: :gin
    t.index ['user_id'], name: 'job_user_id_index '
  end

  create_table 'notable_jobs', force: :cascade do |t|
    t.string 'note_type'
    t.text 'note'
    t.text 'job'
    t.string 'job_id'
    t.string 'queue'
    t.float 'runtime'
    t.float 'queued_time'
    t.datetime 'created_at'
  end

  create_table 'notable_requests', force: :cascade do |t|
    t.string 'note_type'
    t.text 'note'
    t.string 'user_type'
    t.bigint 'user_id'
    t.text 'action'
    t.integer 'status'
    t.text 'url'
    t.string 'request_id'
    t.string 'ip'
    t.text 'user_agent'
    t.text 'referrer'
    t.text 'params'
    t.float 'request_time'
    t.datetime 'created_at'
    t.index %w[user_type user_id], name: 'index_notable_requests_on_user'
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

  create_table 'tokens', force: :cascade do |t|
    t.string 'name', null: false
    t.string 'token_type', null: false
    t.string 'issuer'
    t.datetime 'issued_at', precision: nil, null: false
    t.datetime 'expires_at', precision: nil, null: false
    t.datetime 'last_used_at', precision: nil
    t.boolean 'active', default: true, null: false
    t.string 'scopes'
    t.bigint 'user_id', null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.string 'encrypted_token_iv'
    t.string 'encrypted_token'
    t.index ['user_id'], name: 'index_tokens_on_user_id'
  end

  create_table 'user_blacklists', force: :cascade do |t|
    t.integer 'user_id', null: false
    t.integer 'reason'
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['user_id'], name: 'user_id_UNIQUE', unique: true
  end

  create_table 'users', id: :serial, force: :cascade do |t|
    t.string 'email', limit: 150, null: false
    t.string 'password_digest'
    t.integer 'activity_status', limit: 2, default: 0, null: false
    t.string 'first_name', limit: 128, null: false
    t.string 'last_name', limit: 128, null: false
    t.float 'longitude'
    t.float 'latitude'
    t.string 'country_code', limit: 45
    t.string 'postal_code', limit: 45
    t.string 'city', limit: 45
    t.string 'address', limit: 150
    t.datetime 'date_of_birth'
    t.string 'type', default: 'PrivateUser', null: false
    t.integer 'view_count', default: 0, null: false
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.integer 'applications_count', default: 0
    t.integer 'jobs_count', default: 0
    t.enum 'user_role', default: 'spectator', null: false, enum_type: 'user_role'
    t.boolean 'application_notifications', default: true, null: false
    t.boolean 'communication_notifications', default: true, null: false
    t.boolean 'marketing_notifications', default: false, null: false
    t.boolean 'security_notifications', default: true, null: false
    t.string 'twitter_url', limit: 150
    t.string 'facebook_url', limit: 150
    t.string 'instagram_url', limit: 150
    t.string 'linkedin_url', limit: 150
    t.decimal 'phone'
    t.string 'degree', limit: 50
    t.string 'github_url', limit: 150
    t.string 'portfolio_url', limit: 150
    t.string 'company_name', limit: 128
    t.string 'company_slug', limit: 100
    t.string 'company_phone', limit: 20
    t.string 'company_email', limit: 150
    t.jsonb 'company_urls'
    t.string 'company_industry', limit: 150
    t.text 'company_description'
    t.index ['email'], name: 'user_email_index', unique: true
    t.index %w[first_name last_name], name: 'user_name_index'
    t.index ['type'], name: 'user_user_type_index'
  end

  create_table 'webhooks', force: :cascade do |t|
    t.bigint 'user_id', null: false
    t.string 'url', null: false
    t.string 'event', null: false
    t.string 'source', null: false
    t.string 'ext_id', limit: 100
    t.string 'signatureToken'
    t.boolean 'active', default: true
    t.datetime 'created_at', null: false
    t.datetime 'updated_at', null: false
    t.index ['ext_id'], name: 'index_webhooks_on_ext_id', unique: true
    t.index ['user_id'], name: 'index_webhooks_on_user_id'
  end

  add_foreign_key 'active_storage_attachments', 'active_storage_blobs', column: 'blob_id'
  add_foreign_key 'active_storage_variant_records', 'active_storage_blobs', column: 'blob_id'
  add_foreign_key 'application_events', 'application_events', column: 'next_event_id'
  add_foreign_key 'application_events', 'application_events', column: 'previous_event_id'
  add_foreign_key 'application_options', 'jobs', primary_key: 'job_id', on_delete: :cascade
  add_foreign_key 'applications', 'jobs', primary_key: 'job_id', on_delete: :cascade
  add_foreign_key 'applications', 'users', on_delete: :cascade
  add_foreign_key 'company_users', 'users', column: 'id', on_delete: :cascade
  add_foreign_key 'job_list_items', 'job_lists'
  add_foreign_key 'job_list_items', 'jobs', primary_key: 'job_id'
  add_foreign_key 'job_lists', 'users'
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
  add_foreign_key 'tokens', 'users'
  add_foreign_key 'user_blacklists', 'users', on_delete: :cascade
  add_foreign_key 'webhooks', 'users'
end
