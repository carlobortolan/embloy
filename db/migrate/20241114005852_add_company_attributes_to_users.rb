# frozen_string_literal: true

class AddCompanyAttributesToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :company_name, :string, limit: 128
    add_column :users, :company_slug, :string, limit: 100
    add_column :users, :company_phone, :string, limit: 20
    add_column :users, :company_email, :string, limit: 150
    add_column :users, :company_url, :string, limit: 150
    add_column :users, :company_industry, :string, limit: 150
    add_column :users, :company_description, :text
  end
end
