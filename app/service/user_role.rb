# # frozen_string_literal: true
# class UserRole < ApplicationController
#   # frozen_string_literal: true
#
#   # =============== User Role Check ===============
#   # ============ WITH DATABASE LOOKUP =============
#   def self.must_be_admin!(id = nil)
#     # method can be called for a specific id or using Current.user from Application Controller
#     set_current_id(id)
#     return admin?(Current.user.user_role)
#   end
#
#   def self.must_be_editor!(id = nil)
#     set_current_id(id)
#     return editor?(Current.user.user_role)
#   end
#
#   def self.must_be_developer!(id = nil)
#     set_current_id(id)
#     return developer?(Current.user.user_role)
#   end
#
#   def self.must_be_moderator!(id = nil)
#     set_current_id(id)
#     return moderator?(Current.user.user_role)
#   end
#
#   def self.must_be_verified!(id = nil)
#     set_current_id(id)
#     return verified?(Current.user.user_role)
#   end
#
#   # =============== User Role Check ===============
#   # ========== WITHOUT DATABASE LOOKUP ============
#   def self.must_be_admin(user_role)
#     return admin?(user_role)
#   end
#
#   def self.must_be_editor(user_role)
#     return editor?(user_role)
#   end
#
#   def self.must_be_developer(user_role)
#     return developer?(user_role)
#   end
#
#   def self.must_be_moderator(user_role)
#     return moderator?(user_role)
#   end
#
#   def self.must_be_verified(user_role)
#     return verified?(user_role)
#   end
#
#   protected
#
#   # ======= Set Current to the user for id  =======
#   def self.set_current_id(id = nil)
#     if id.nil?
#       if Current.user.nil?
#         raise CustomExceptions::InvalidUser::LoggedOut
#       end
#     else
#       Current.user = User.find_by(id: id)
#       if Current.user.nil?
#         raise CustomExceptions::InvalidUser::Unknown
#       end
#     end
#   end
#
#   # ============== Should be raised ===============
#   # ===== when required user_role is to high  =====
#   def self.taboo! #
#     raise CustomExceptions::Unauthorized::InsufficientRole
#   end
#
#   # =============== Helper methods ================
#   # ======== that model the role hierarchy ========
#   def self.admin?(user_role)
#     if user_role == "admin"
#       true
#     else
#       taboo!
#     end
#   end
#
#   def self.editor?(user_role)
#     if user_role == "admin" || user_role == "editor"
#       true
#     else
#       taboo!
#     end
#   end
#
#   def self.developer?(user_role)
#     if user_role == "admin" || user_role == "developer"
#       true
#     else
#       taboo!
#     end
#   end
#
#   def self.moderator?(user_role)
#     if user_role == "admin" || user_role == "editor" || user_role == "moderator"
#       true
#     else
#       taboo!
#     end
#   end
#
#   def self.verified?(user_role)
#     if user_role == "admin" || user_role == "editor" || user_role == "moderator" || user_role == "verified"
#       true
#     else
#       taboo!
#     end
#   end
#
#   class Jobs < JobsController
#     def self.must_be_owner!(job_id = nil, user_id = nil)
#       UserRole.set_current_id(user_id)
#       set_at_job(job_id)
#       return owner?
#     end
#
#     protected
#
#     def self.set_at_job(job_id = nil)
#       unless job_id.nil?
#         @job = Job.find_by(job_id: job_id)
#       end
#
#       if @job.nil?
#         raise CustomExceptions::InvalidJob::Unknown
#       end
#
#     end
#
#
#     def self.owner?
#       puts @job.job_id
#       puts Current.user.id
#       if @job.user_id == Current.user.id
#         true
#       else
#         begin
#           UserRole.taboo!
#         rescue CustomExceptions::Unauthorized::InsufficientRole
#           raise CustomExceptions::Unauthorized::InsufficientRole::NotOwner
#         end
#       end
#     end
#   end
# end
