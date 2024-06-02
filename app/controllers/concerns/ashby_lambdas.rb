# frozen_string_literal: true

module AshbyLambdas

  def self.parse_application (data)
    new_data = []
    data.each do |field|
      res = {}
      res["required"] = field["isRequired"]
      res["question_type"] = "text"
      res["question"] = field["field"]["humanReadablePath"]
      res["ext_id"] = field["field"]["id"]
      new_data << res
    end
    puts "NEW DATA: #{new_data}"
    new_data
  end
end
