# frozen_string_literal: true

module Api
  module V0
    # GeniusQueriesController handles genius query-related actions
    class GeniusQueriesController < ApiController
      skip_before_action :set_current_user, only: :query
      before_action :must_be_verified!, only: :create
      before_action :must_be_subscribed!, only: :create

      def create
        raise CustomExceptions::InvalidInput::GeniusQuery::Blank if create_params[:job_id].blank? && create_params[:user_id].blank?

        render status: 200, json: { 'query_token' => GeniusQueryService::Encoder.call(Current.user.id, create_params) }
      end

      def query
        render status: 200, json: GeniusQueryService::Decoder.call(query_params[:genius])
      rescue ActiveRecord::RecordNotFound
        not_found_error('genius_query')
      end

      private

      def create_params
        params.except(:format).permit(:job_id, :user_id, :exp)
      end

      def query_params
        params.except(:format).permit(:genius)
      end
    end
  end
end
