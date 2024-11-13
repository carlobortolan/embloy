# frozen_string_literal: true

module Api
  module V0
    # JobListsController handles job list-related actions
    class JobListsController < ApiController
      before_action :set_job_list, only: %i[show update destroy]

      def index
        @job_lists = Current.user.job_lists
        render status: @job_lists.present? ? :ok : :no_content, json: @job_lists
      end

      def create
        @job_list = Current.user.job_lists.new(job_list_params)
        if @job_list.save
          render json: @job_list, status: :created
        else
          render json: @job_list.errors, status: :bad_request
        end
      end

      def show
        render json: @job_list
      end

      def update
        if @job_list.update(job_list_params)
          render json: @job_list
        else
          render json: @job_list.errors, status: :bad_request
        end
      end

      def destroy
        @job_list.destroy
        render status: 200, json: { message: 'Job list deleted!' }
      end

      private

      def set_job_list
        @job_list = Current.user.job_lists.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        not_found_error('job_list')
      end

      def job_list_params
        params.permit(:name)
      end
    end
  end
end
