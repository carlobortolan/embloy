# frozen_string_literal: true

module Api
  module V0
    # NotificationsController handles user-related actions
    class NotificationsController < ApiController
      before_action :verify_path_notification_id, only: %i[mark_as_read]

      def show
        notifications = Notification.where(recipient: Current.user).newest_first.limit(9)
        if notifications.empty?
          render(status: 204, json: { notifications: [] })
        else
          render(status: 200, json: { notifications: })
        end
      end

      def unread_applications
        notifications = Notification.where(recipient: Current.user, read_at: nil, type: 'ApplicationStatusNotification')
        if notifications.empty?
          render(status: 204, json: [])
        else
          job_ids = notifications.map { |n| n.params[:application][:job] }
          render(status: 200, json: { job_ids: })
        end
      end

      def mark_as_read
        mark_as_read_params[:read] == '0' ? @notification.update(read_at: Time.current) : @notification.update(read_at: nil)
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
