class AddPhoneAndDegree < ActiveRecord::Migration[7.0]
  def change
    change_table :users do |t|
      t.numeric :phone, limit: 16
      t.string :degree, limit: 50
    end
  end
end
