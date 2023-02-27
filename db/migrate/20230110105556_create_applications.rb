class CreateApplications < ActiveRecord::Migration[7.0]
  def change
    create_enum :application_status, ['-1', '0', '1']
    create_table "applications", primary_key: ["job_id", "applicant_id"], charset: "unicode", force: :cascade do |t|
      t.integer "job_id", null: false
      t.integer "applicant_id", null: false
      #      t.datetime "applied_at", default: -> { DateTime.now }
      #      t.column(:applied_at, :datetime)
      t.datetime "updated_at", default: DateTime.now, null: false
      t.datetime "applied_at", default: -> { DateTime.now }, null: false
      t.enum "status", enum_type: "application_status", default: '0', null: false
      t.string "application_text", limit: 1000
      t.string "application_documents", limit: 100
      t.string "response", limit: 500
      t.index ["applicant_id"], name: "account_id_idx"
      t.index ["job_id", "applicant_id"], name: "index_applications_on_job_id_and_applicant_id", unique: true
    end
  end
end
