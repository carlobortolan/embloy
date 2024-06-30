# frozen_string_literal: true

require 'json'

# input =
#   [
#     { 'question' => 'personalInformation__email', 'answer' => 'carlobortolan@gmail.com' },
#     { 'question' => 'personalInformation__fullName', 'answer' => 'Carlo Bortolan' },
#     { 'question' => 'personalInformation__currentCompany', 'answer' => 'Embloy' },
#     { 'question' => 'personalInformation__currentLocation', 'answer' => 'Munich' },
#     { 'question' => 'personalInformation__phone', 'answer' => '123123123' },
#     { 'question' => 'personalInformation__resume', 'answer' => 'linktofile' },
#     { 'question' => 'personalInformation__additionalInformation', 'answer' => 'linktofile' },
#     { 'question' => 'eeoResponses__gender', 'answer' => 'Female' },
#     { 'question' => 'eeoResponses__race', 'answer' => 'Hispanic' },
#     { 'question' => 'diversitySurvey__b0d26744-60b2-4015-b125-b09fd5b95c1d__CO__62d6bd6a-be74-48d1-a7a5-5b9570b50bf8', 'answer' => 'Male' },
#     { 'question' => 'urls__LinkedIn', 'answer' => 'https://linkedin.com/in/carlobortolan' },
#     { 'question' => 'urls__Twitter', 'answer' => 'https://twitter.com/carlobortolan' },
#     { 'question' => 'urls__GitHub', 'answer' => 'https://github.com/carlobortolan' },
#     { 'question' => 'urls__Portfolio', 'answer' => 'https://carlobortolan.com' },
#     { 'question' => 'customQuestions__911f7ca4-e7a2-4081-9472-0c1f94d9df25__0', 'answer' => 'Short Text' },
#     { 'question' => 'customQuestions__911f7ca4-e7a2-4081-9472-0c1f94d9df25__1', 'answer' => 'Long text' },
#     { 'question' => 'customQuestions__911f7ca4-e7a2-4081-9472-0c1f94d9df25__2', 'answer' => 'Choice 1' },
#     { 'question' => 'customQuestions__911f7ca4-e7a2-4081-9472-0c1f94d9df25__3', 'answer' => 'Somefile' },
#     { 'question' => 'customQuestions__911f7ca4-e7a2-4081-9472-0c1f94d9df25__4', 'answer' => '[\"Option 2\", \"Option 1\"]' },
#     { 'question' => 'customQuestions__911f7ca4-e7a2-4081-9472-0c1f94d9df25__5', 'answer' => 'MC2' }
#   ]
#
# expected_output_json = '{
#   "customQuestions": {
#     "id": "911f7ca4-e7a2-4081-9472-0c1f94d9df25",
#     "fields": [
#       { "value": "Short Text" },
#       { "value": "Long text" },
#       { "value": "Choice 1" },
#       { "value": ["Option1"] },
#       { "value": "MC2" }
#     ]
#   },
#   "eeoResponses": {
#     "gender": "Female",
#     "race": "Hispanic"
#   },
#   "diversitySurvey": {
#     "surveyId": "b0d26744-60b2-4015-b125-b09fd5b95c1d",
#     "candidateSelectedLocation": "CO",
#     "responses": [
#       {
#         "questionId": "62d6bd6a-be74-48d1-a7a5-5b9570b50bf8",
#         "answer": "Male"
#       }
#     ]
#   },
#   "personalInformation": {
#     "email": { "value": "carlobortolan@gmail.com" },
#     "fullName": { "value": "Carlo Bortolan" },
#     "currentCompany": { "value": "Embloy" },
#     "currentLocation": { "value": "Munich" },
#     "phone": { "value": "123123123" }
#   },
#   "urls": {
#     "LinkedIn": { "value": "https://linkedin.com/in/carlobortolan" },
#     "Twitter": { "value": "https://twitter.com/carlobortolan" },
#     "GitHub": { "value": "https://github.com/carlobortolan" },
#     "Portfolio": { "value": "https://carlobortolan.com" }
#   }
# }'
#
# output = {
#   'customQuestions' => [],
#   'eeoResponses' => {},
#   'diversitySurvey' => { 'surveyId' => '', 'candidateSelectedLocation' => '', 'responses' => [] },
#  'personalInformation' => [],
#  'urls' => []
# }
#
# def parse2(input, output)
#   input.each do |entry|
#     question_parts = entry['question'].split('__')
#     section = question_parts[0]
#     case section
#     when 'personalInformation'
#       output['personalInformation'] << { 'name' => question_parts[1], 'value' => entry['answer'] } unless entry['answer'].strip.empty?
#     when 'eeoResponses'
#       output['eeoResponses'][question_parts[1]] = entry['answer']
#     when 'diversitySurvey'
#       if question_parts[2]
#         output['diversitySurvey']['surveyId'] = question_parts[1]
#         output['diversitySurvey']['candidateSelectedLocation'] = question_parts[2]
#         output['diversitySurvey']['responses'] << { 'questionId' => question_parts[3], 'answer' => entry['answer'] }
#       end
#     when 'urls'
#       output['urls'] << { 'name' => question_parts[1], 'value' => entry['answer'] }
#     when 'customQuestions'
#       custom_question = output['customQuestions'].find { |question| question['id'] == question_parts[1] }
#
#       # If custom_question is nil, initialize it
#       unless custom_question
#         custom_question = { 'id' => question_parts[1], 'fields' => [] }
#         output['customQuestions'] << custom_question
#       end
#
#       # Convert question_parts[2] to an integer to use as an index
#       index = question_parts[2].to_i
#
#       # Ensure the fields array is large enough
#       if custom_question['fields'].length <= index
#         # If the index is out of bounds, increase the size of the array
#         (custom_question['fields'].length..index).each { |i| custom_question['fields'][i] = { 'value' => nil } }
#       end
#
#       # Set the value at the specified index
#       unless entry['answer'].strip.empty?
#         custom_question['fields'][index]['value'] = begin
#           JSON.parse(entry['answer'])
#         rescue StandardError
#           entry['answer']
#         end
#       end
#     end
#   end
#
#   output.delete('diversitySurvey') if output['diversitySurvey']['surveyId'].empty?
#   output.to_json
# end
#
# puts parse2(input, output)

module Integrations
  # LeverParser parses Lever API post application request body
  class LeverParser
    def self.parse(input, output) # rubocop:disable Metrics/AbcSize,Metrics/PerceivedComplexity,Metrics/CyclomaticComplexity
      input.each do |entry| # rubocop:disable Metrics/BlockLength
        question_parts = entry['question'].split('__')
        section = question_parts[0]
        case section
        when 'personalInformation'
          output['personalInformation'] << { 'name' => question_parts[1], 'value' => entry['answer'] } unless entry['answer'].blank?
        when 'eeoResponses'
          output['eeoResponses'][question_parts[1]] = entry['answer']
        when 'diversitySurvey'
          if question_parts[2]
            output['diversitySurvey']['surveyId'] = question_parts[1]
            output['diversitySurvey']['candidateSelectedLocation'] = question_parts[2]
            output['diversitySurvey']['responses'] << { 'questionId' => question_parts[3], 'answer' => entry['answer'] }
          end
        when 'urls'
          output['urls'] << { 'name' => question_parts[1], 'value' => entry['answer'] }
        when 'customQuestions'
          custom_question = output['customQuestions'].find { |question| question['id'] == question_parts[1] }

          # If custom_question is nil, initialize it
          unless custom_question
            custom_question = { 'id' => question_parts[1], 'fields' => [] }
            output['customQuestions'] << custom_question
          end

          # Convert question_parts[2] to an integer to use as an index
          index = question_parts[2].to_i

          # Ensure the fields array is large enough
          if custom_question['fields'].length <= index
            # If the index is out of bounds, increase the size of the array
            (custom_question['fields'].length..index).each { |i| custom_question['fields'][i] = { 'value' => nil } }
          end

          # Set the value at the specified index
          unless entry['answer'].blank?
            custom_question['fields'][index]['value'] = begin
              JSON.parse(entry['answer'])
            rescue StandardError
              entry['answer']
            end
          end
        end
      end

      output.delete('diversitySurvey') if output['diversitySurvey']['surveyId'].empty?
      output.to_json
    end
  end
end
