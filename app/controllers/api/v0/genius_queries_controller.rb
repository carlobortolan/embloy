# frozen_string_literal: true

module Api
  module V0
    # GeniusQueriesController handles genius query-related actions
    class GeniusQueriesController < ApiController
      skip_before_action :set_current_user,
                         only: :query

      def create
        must_be_verified!
        res = GeniusQueryService::Encoder.call(
          Current.user.id, create_params
        )
        render status: 200,
               json: { 'query_token' => res }
      end

      def query
        token = params[:genius]
        res = GeniusQueryService::Decoder.call(token)
        render status: 200,
               json: { 'query_result' => res }
      rescue ActiveRecord::RecordNotFound
        not_found_error('genius_query')
      end

      private

      def create_params
        params.permit(:job_id, :user_id,
                      :expires_at)
      end
    end
  end
end
