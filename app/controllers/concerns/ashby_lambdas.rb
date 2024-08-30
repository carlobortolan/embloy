# frozen_string_literal: true

# The AshbyLambdas module contains custom lambda functions the parser.
module AshbyLambdas
  def self.parse_application(data)
    new_data = []
    data.each do |field|
      next if %w[_systemfield_resume _systemfield_email _systemfield_name].include?(field['field']['path'])

      res = {}
      res['required'] = field['isRequired']
      res['question_type'] = type_map(field['field']['type'])
      res['question'] = field['field']['title']
      res['ext_id'] = "ashby__#{field['field']['path']}__#{field['field']['path']}"
      new_data << res
    end
    new_data
  end

  def self.type_map(type)
    return 'text' if %w[String Date Number LongText Phone Score].include?(type)
    return 'yes_no' if %w[Boolean].include?(type)
    return 'link' if %w[SocialLink].include?(type)
    return 'single_choice' if %w[ValueSelect].include?(type)
    return 'multiple_choice' if %w[MultiValueSelect].include?(type)

    'file' if %w[File].include?(type)
  end
end
