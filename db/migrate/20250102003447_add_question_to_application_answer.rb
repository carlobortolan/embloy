# frozen_string_literal: true

class AddQuestionToApplicationAnswer < ActiveRecord::Migration[7.0]
  def change
    add_column :application_answers, :question, :string, limit: 500
  end
end
