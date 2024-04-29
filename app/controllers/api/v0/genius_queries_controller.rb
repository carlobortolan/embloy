# frozen_string_literal: true

module Api
  module V0
    # GeniusQueriesController handles genius query-related actions
    class GeniusQueriesController < ApiController
      skip_before_action :set_current_user, only: :query
      before_action :must_be_verified!, only: :create
      before_action :must_be_subscribed!, only: :create

      def create
        params = validate_params(create_params)
        if params[:qr] == '1' && !params[:job_id].present?
          job = create_job(params)
          render status: 400, json: job.errors.details if job.errors.present?
        end

        render status: 200, json: { 'query_token' => GeniusQueryService::Encoder.call(Current.user.id, params) }
      end

      def query
        render status: 200, json: GeniusQueryService::Decoder.call(query_params[:genius])
      rescue ActiveRecord::RecordNotFound
        not_found_error('genius_query')
      end

      private

      def create_job(params)
        job = Job.new(job_status: 'unlisted', user_id: Current.user.id)
        params[:job_id] = job.id.to_i if job.save && job.update(title: "Generated QR ##{job.job_slug}")
        job
      end

      def validate_params(params)
        raise CustomExceptions::InvalidInput::GeniusQuery::Blank if params[:job_id].blank? && params[:user_id].blank? && params[:qr].blank?

        validate_time(params)
      end

      def validate_time(params)
        params[:exp] = Time.parse(params[:exp]).to_i
        params
      rescue ArgumentError, TypeError
        params.delete(:exp)
        params
      end

      def create_params
        params.except(:format).permit(:job_id, :user_id, :exp, :qr)
      end

      def query_params
        params.except(:format).permit(:genius)
      end
    end
  end
end
