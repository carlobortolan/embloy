# frozen_string_literal: true

module AshbyLambdas

  def self.parse_application (data)
    new_data = []
    data.each do |field|
      res = {}
      res["required"] = field["isRequired"]
      res["question_type"] = "text"
      res["question"] = field["field"]["title"]
      res["ext_id"] = field["field"]["id"]
      new_data << res
    end
    new_data
  end


  private
  def self.type_map (type)
    return "text" if %w[String Email].include?(type)
  end
end
