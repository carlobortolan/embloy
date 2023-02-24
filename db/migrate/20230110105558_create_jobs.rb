class CreateJobs < ActiveRecord::Migration[7.0]
  def change
    create_table "jobs", primary_key: "job_id", id: :integer, charset: "unicode", force: :cascade do |t|
      t.string "job_type"
      t.integer "job_status", limit: 1, default: 0
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
      t.timestamps
      t.index ["user_id"], name: "job_information_account_id_idx"
    end
  end
end
