# frozen_string_literal: true

require 'json'

module Integrations
  module Lever
    # Parser parses Lever API post application request body
    class Parser
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
end
