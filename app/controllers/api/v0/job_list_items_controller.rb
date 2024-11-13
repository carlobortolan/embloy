# frozen_string_literal: true

module Api
  module V0
    # JobListItemsController handles job list item-related actions
    class JobListItemsController < ApiController
      before_action :set_job_list

      def create
        @job_list_item = @job_list.job_list_items.new(job_list_item_params)
        if @job_list_item.save
          render json: @job_list_item, status: :created
        else
          render json: @job_list_item.errors, status: :bad_request
        end
      end

      def destroy
        begin
          @job_list_item = @job_list.job_list_items.find(params[:id])
        rescue ActiveRecord::RecordNotFound
          return not_found_error('job_list_item')
        end

        @job_list_item.destroy
        render status: 200, json: { message: 'Job list item deleted!' }
      end

      private

      def set_job_list
        @job_list = Current.user.job_lists.find(params[:job_list_id])
      rescue ActiveRecord::RecordNotFound
        not_found_error('job_list')
      end

      def job_list_item_params
        params.permit(:job_id, :notes)
      end
    end
  end
end
