# To deliver this notification:
#
# ApplicationNotification.with(post: @post).deliver_later(current_user)
# ApplicationNotification.with(post: @post).deliver(current_user)

class ApplicationNotification < Noticed::Base
  # Add your delivery methods
  #
  deliver_by :database
  # deliver_by :action_cable, format: :to_action_cable
  # deliver_by :email, mailer: "UserMailer"
  # deliver_by :slack
  # deliver_by :custom, class: "MyDeliveryMethod"

  def to_database
    puts "T-5"
    {
      type: self.class.name,
      params: params,
      account: Current.account,
    }
    puts "T-6"
  end

  # Add required params
  #
  # param :application, :job

  # Define helper methods to make rendering easier.
  #
  # def message
  #   t(".message")
  # end
  #
  def url
    job_path(params[:job])
  end
end
