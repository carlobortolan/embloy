# frozen_string_literal: true

require 'net/http/post/multipart'
require 'net/http'
require 'uri'
require 'json'
require 'base64'
require 'mawsitsit'

module Integrations
  module Ashby
    # AshbyController handles Ashby-related actions
    class AshbyController < IntegrationsController
      ASHBY_POST_FORM_URL = 'https://api.ashbyhq.com/applicationForm.submit'
      ASHBY_FETCH_APPLICATION_URL = 'https://api.ashbyhq.com/application.info'
      ASHBY_FETCH_POSTING_URL = 'https://api.ashbyhq.com/jobPosting.info'
      ASHBY_FETCH_POSTINGS_URL = 'https://api.ashbyhq.com/jobPosting.list'

      # Reference: https://developers.ashbyhq.com/reference/applicationformsubmit
      def self.post_form(posting_id, application, application_params, client) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
        url = URI(ASHBY_POST_FORM_URL)
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        api_key = Token.fetch_token(client, 'ashby', 'api_key')
        application_answers = application.application_answers.includes(:application, :application_option, :user, :job, :attachment_attachment).where(version: application.version)

        field_submissions = application_answers.map do |answer|
          if answer.application_option.question_type == 'file'
            file_key = "file_#{answer.application_option_id}"
            { path: answer.application_option.ext_id.split('__').last, value: file_key }
          else
            formatted_answer = format_answer(answer)
            { path: answer.application_option.ext_id.split('__').last, value: formatted_answer }
          end
        end

        form_data = { 'jobPostingId' => posting_id, 'applicationForm' => { fieldSubmissions: field_submissions }.to_json }

        # Add files to form_data
        application_answers.each do |answer|
          next unless answer.application_option.question_type == 'file'

          application_answer_params = application_params[:application_answers].permit!.to_h.find do |_, a|
            a[:application_option_id].to_i == answer.application_option_id
          end&.last

          next unless application_answer_params

          file_param = application_answer_params[:file]
          file_key = "file_#{answer.application_option_id}" # Match the key used in field_submissions

          File.open(file_param.tempfile.path) do |file|
            file_content = file.read
            form_data[file_key] = UploadIO.new(StringIO.new(file_content), file_param.content_type, file_param.original_filename)
          end
        end

        request = Net::HTTP::Post::Multipart.new(url.path, form_data)
        request['Accept'] = 'application/json'
        request['Authorization'] = "Basic #{Base64.strict_encode64("#{api_key}:")}"
        Rails.logger.debug("Posting Ashby application: #{request.body}")

        response = http.request(request)
        Rails.logger.debug("Ashby application submitted: #{response.code}:\n#{response.body}")

        body = JSON.parse(response.body)
        unless response.is_a?(Net::HTTPSuccess) && body['success'] == true
          Rails.logger.error("Error submitting Ashby application: #{body['errors']}")
          return Net::HTTPBadRequest.new('400', 'Bad Request', body['errors'])
        end

        instance_id = body['results']['submittedFormInstance']['id']
        response = make_request(ASHBY_FETCH_APPLICATION_URL, client, 'post', { submittedFormInstanceId: instance_id })
        Rails.logger.debug("Ashby application fetched: #{instance_id} - #{response.code}:\n#{response.body}")

        body = JSON.parse(response.body)
        unless response.is_a?(Net::HTTPSuccess) && body['success'] == true
          Rails.logger.error("Error fetching Ashby application: #{body['errors']}")
          return Net::HTTPBadRequest.new('400', 'Bad Request', body['errors'])
        end

        application.update!(ext_id: "ashby__#{body['results']['id']}")
        Rails.logger.debug("Ashby application updated with ext_id: #{application.ext_id}")

        handle_application_response(response)
      end

      # Reference: https://developers.ashbyhq.com/reference/jobpostinginfo
      def self.fetch_posting(posting_id, client, job)
        response = make_request(ASHBY_FETCH_POSTING_URL, client, 'post', { jobPostingId: posting_id })

        Rails.logger.debug("Ashby job fetched: #{posting_id} - #{response.code}:\n#{response.body}")

        case response
        when Net::HTTPSuccess
          body = JSON.parse(response.body)
          raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed unless body['success'] == true

          config = JSON.parse(File.read('app/controllers/integrations/ashby/ashby_config.json'))
          config['city'].gsub!('ASHBY_SECRET', Token.fetch_token(client, 'ashby', 'api_key').to_s)
          job = Mawsitsit.parse(body, config, true)
          job['job_slug'] = "ashby__#{job['job_slug']}"
          job['user_id'] = client.id.to_i
          handle_internal_job(client, job)
        when Net::HTTPBadRequest
          raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed and return
        when Net::HTTPForbidden
          raise CustomExceptions::InvalidInput::Quicklink::Request::Forbidden and return
        when Net::HTTPUnauthorized
          raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized and return
        end
      end

      # Reference: https://developers.ashbyhq.com/reference/jobpostinglist
      def self.synchronize(client)
        response = make_request(ASHBY_FETCH_POSTINGS_URL, client)
        case response
        when Net::HTTPSuccess
          body = JSON.parse(response.body)
          raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed unless body['success'] == true

          Rails.logger.debug("Ashby jobs fetched: #{body['results'].length}")

          data = JSON.parse(response.body)['results']
          data.each do |job|
            fetch_posting(job['id'], client, job)
          end
        when Net::HTTPBadRequest
          raise CustomExceptions::InvalidInput::Quicklink::Request::Malformed and return
        when Net::HTTPForbidden
          raise CustomExceptions::InvalidInput::Quicklink::Request::Forbidden and return
        when Net::HTTPUnauthorized
          raise CustomExceptions::InvalidInput::Quicklink::ApiKey::Unauthorized and return
        end
      end

      def self.make_request(url, client, method = 'post', body = nil)
        uri = URI.parse(url)
        request = Net::HTTP.const_get(method.capitalize).new(uri)
        api_key = Token.fetch_token(client, 'ashby', 'api_key')
        request['Authorization'] = "Basic #{Base64.strict_encode64("#{api_key}:")}"
        request['Content-Type'] = 'application/json'
        request.body = body.to_json if body

        Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
          http.request(request)
        end
      end

      def self.format_answer(answer)
        case answer.application_option.question_type
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
      end
    end
  end
end
