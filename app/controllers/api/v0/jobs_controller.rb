require_relative '../../../../lib/feed_generator.rb'
module Api
  module V0
    class JobsController < ApiController
      before_action :verify_access_token

      def create
        begin
          verified!(@decoded_token["typ"])
          @job = Job.new(job_params)
          @job.user_id = @decoded_token["sub"]

          if @job.save
            render status: 200, json: { "message": "Job created!" }
          else
            render status: 400, json: { "error": @job.errors.details }
          end

        rescue ActionController::ParameterMissing
          blank_error('job')

        end
      end

      def update
        begin
          verified!(@decoded_token["typ"])
          must_be_owner!(params[:id], @decoded_token["sub"])
          @job.assign_attributes(job_params)
          if @job.save
            render status: 200, json: { "message": "Job updated!" }
          else
            render status: 400, json: { "error": @job.errors.details }
          end

        rescue ActionController::ParameterMissing # just relevant for strong parameters
          blank_error('job')

        end

      end

      def destroy
          begin
            verified!(@decoded_token["typ"])
            must_be_owner!(params[:id], @decoded_token["sub"])
            @job.destroy!
            render status: 200, json: { "message": "Job deleted!" }
        end
      end

      # parse_inputs isn't implemented because job_feed will be completly revised and then will this will be implemented accordingly

=begin
      def find
        @jobs = Job.all.where("status = 'public'").first(100)
      end

      def parse_inputs
        @my_args = { "longitude" => params[:longitude].to_f, "latitude" => params[:latitude].to_f, "radius" => params[:radius].to_f, "time" => Time.parse(params[:time]), "limit" => params[:limit].to_i }
        # TODO: REMOVE 'first(100)'
        @result = FeedGenerator.initialize_feed(Job.all.where("status = 'public'").first(100).as_json, @my_args)
      end
=end

      private

      def job_params
        params.require(:job).permit(:title, :description, :start_slot, :status, :longitude, :latitude)
      end

      # mark_notifications_as_read is not implemented because i dont understand how it works
=begin
      def mark_notifications_as_read
        if Current.user
          notifications_to_mark_as_read = @job.notifications_as_job.where(recipient: Current.user)
          notifications_to_mark_as_read.update_all(read_at: Time.zone.now)
        end
      end
=end
    end
  end
end