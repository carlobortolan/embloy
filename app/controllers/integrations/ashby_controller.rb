# frozen_string_literal: true

require 'net/http/post/multipart'
require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'mawsitsit'

module Integrations
  # AshbyController handles Ashby-related actions
  class AshbyController < IntegrationsController
    ASHBY_POST_FORM_URL = 'https://api.ashbyhq.com/applicationForm.submit'
    ASHBY_FETCH_POSTING_URL = 'https://api.ashbyhq.com/jobPosting.info'

    # Reference: https://developers.ashbyhq.com/reference/applicationformsubmit
    def self.post_form(posting_id, application, application_params, client) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
      url = URI(ASHBY_POST_FORM_URL)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      api_key = fetch_token(client, 'ashby', 'api_key')
      field_submissions = application.application_answers.map do |answer|
        if answer.application_option.question_type == 'file'
          file_key = "file_#{answer.application_option_id}"
          { path: answer.application_option.ext_id.split('__').last, value: file_key }
        else
          formatted_answer = case answer.application_option.question_type
                             when 'yes_no'
                               answer.answer == 'Yes'
                             when 'number', 'score'
                               answer.answer.to_i
                             when 'multiple_choice'
                               begin
                                 JSON.parse(answer.answer)
                               rescue JSON::ParserError
                                 []
                               end
                             else
                               answer.answer
                             end

          { path: answer.application_option.ext_id.split('__').last, value: formatted_answer }
        end
      end

      form_data = { 'jobPostingId' => posting_id, 'applicationForm' => { fieldSubmissions: field_submissions }.to_json }

      # Add files to form_data
      application.application_answers.each do |answer|
        next unless answer.application_option.question_type == 'file'

        application_answer_params = application_params[:application_answers].permit!.to_h.find do |_, a|
          a[:application_option_id].to_i == answer.application_option_id
        end&.last

        next unless application_answer_params

        file = application_answer_params[:file]
        file_key = "file_#{answer.application_option_id}" # Match the key used in field_submissions
        form_data[file_key] = UploadIO.new(file.tempfile, file.content_type, file.original_filename)
      end

      request = Net::HTTP::Post::Multipart.new(url.path, form_data)

      request['Accept'] = 'application/json'
      request['Authorization'] = "Basic #{api_key}"

      response = http.request(request)

      body = JSON.parse(response.body)
      response = Net::HTTPBadRequest.new('1.1', '400', 'Bad Request', body['errors']) if response == Net::HTTPSuccess && body['success'] == false
      handle_application_response(response)
    end

    # rubocop:disable Metrics/AbcSize
    # Reference: https://developers.ashbyhq.com/reference/jobpostinginfo
    def self.fetch_posting(posting_id, client, job)
      # Build request
      url = URI(ASHBY_FETCH_POSTING_URL)
      http = Net::HTTP.new(url.host, url.port)
      http.use_ssl = true
      request = Net::HTTP::Post.new(url)
      request['accept'] = 'application/json'
      request['content-type'] = 'application/json'
      request['authorization'] = "Basic #{fetch_token(client, 'ashby', 'api_key')}"
      request.body = "{\"jobPostingId\":\"#{posting_id}\"}"

      # Make request to Ashby API
      response = http.request(request)
      body = JSON.parse(response.body)

      case response
      when Net::HTTPSuccess
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed unless body['success'] == true

        config = JSON.parse(File.read('app/controllers/integrations/ashby_config.json'))
        config['city'].gsub!('ASHBY_SECRET', fetch_token(client, 'ashby', 'api_key').to_s)
        resp = JSON.parse(response.body)
        job = Mawsitsit.parse(resp, config, true)
        job['job_slug'] = "ashby__#{job['job_slug']}"
        job['user_id'] = client.id.to_i
        handle_internal_job(client, job)
      when Net::HTTPBadRequest
        raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed and return
      when Net::HTTPUnauthorized
        raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized and return
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
