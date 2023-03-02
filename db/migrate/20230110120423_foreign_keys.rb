class ForeignKeys < ActiveRecord::Migration[7.0]
  def change
    add_foreign_key "applications", "jobs", primary_key: "job_id", on_delete: :cascade, on_update: :cascade
    add_foreign_key "applications", "users", on_delete: :cascade, on_update: :cascade
    add_foreign_key "company_users", "users", column: "id", on_delete: :cascade, on_update: :cascade
    add_foreign_key "jobs", "users", on_delete: :cascade, on_update: :cascade
    add_foreign_key "private_users", "users", column: "id", on_delete: :cascade, on_update: :cascade
    add_foreign_key "reviews", "users", column: "created_by", on_delete: :cascade, on_update: :cascade
  end
end
