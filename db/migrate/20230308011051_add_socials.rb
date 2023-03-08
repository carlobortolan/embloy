class AddSocials < ActiveRecord::Migration[7.0]
  change_table :users do |t|
    r t.string :twitter_url, limit: 500
    t.string :facebook_url, limit: 500
    t.string :instagram_url, limit: 500
    t.string :linkedin_url, limit: 500
  end
end
