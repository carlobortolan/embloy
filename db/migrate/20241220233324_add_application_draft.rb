# frozen_string_literal: true

class AddApplicationDraft < ActiveRecord::Migration[7.0]
  def change
    add_column :applications, :submitted_at, :datetime
  end
end
