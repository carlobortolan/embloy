# frozen_string_literal: true

module Api
  module V0
    # NotificationsController handles user-related actions
    class NotificationsController < ApiController
      def show
        notifications = Notification.where(recipient: User.first).newest_first.limit(9)
        if notifications.empty?
          render(status: 204, json: { notifications: [] })
        else
          render(status: 200, json: { notifications: })
        end
      end

      def unread_applications
        notifications = Notification.where(recipient: User.first, read_at: nil, type: 'ApplicationStatusNotification')
        if notifications.empty?
          render(status: 204, json: [])
        else
          job_ids = notifications.map { |n| n.params[:application][:job] }
          render(status: 200, json: { job_ids: })
        end
      end

      def mark_as_read
        notification = Notification.find(mark_as_read_params[:id])
        if mark_as_read_params[:read] == '1'
          notification.update(read_at: Time.current)
        elsif mark_as_read_params[:read] == '0'
          notification.update(read_at: nil)
        end
        render json: { success: true }
      rescue ActiveRecord::RecordNotFound
        not_found_error
      end

      private

      def mark_as_read_params
        params.except(:format).permit(:read, :id)
      end
    end
  end
end
