# frozen_string_literal: true

#########################################################
################# CUSTOM EXCEPTIONS #####################
#########################################################
class CustomExceptions < StandardError
  # ============== User Format and Authentication - Exceptions =============
  class InvalidUser < StandardError
    # Should be risen when there is no record in users for a given id
    class Unknown < StandardError
    end

    # User credentials not correct -> Authentication failed
    class CredentialsWrong < StandardError
    end

    # (NON-API-ONLY) Current.user is nil (= session token expired)
    class LoggedOut < StandardError
    end

    # Current.user is deactivated (activity_status = 0)
    class Inactive < StandardError
    end
  end

  # ============== User Authorization - Exceptions =============
  class Unauthorized < StandardError
    # Current.user is not owner of resource that he is trying to access
    class NotOwner < StandardError
    end

    # User does not have the required role to access the resource
    class InsufficientRole < StandardError
      # TODO: Subklassen können je nach dem wie genau die Error message sein soll auch weggelassen werden
      # User does not have the 'admin' role
      class NotAdmin < StandardError
      end

      # User does not have the 'admin' role
      class NotEditor < StandardError
      end

      # User does not have the 'developer' role
      class NotDeveloper < StandardError
      end

      # User does not have the 'moderator' role
      class NotModerator < StandardError
      end

      # User is not 'verified' yet
      class NotVerified < StandardError
      end
    end

    # User is blacklisted
    class Blocked < StandardError
    end
  end

  # ============== JWT-Token - Exceptions =============
  class InvalidInput < StandardError
    # Invalid token?
    class Token < StandardError
    end

    # Token has wrong format?
    class SUB < StandardError
    end

    # Token expired?
    class CustomEXP < StandardError
    end

    # Blank email || password
    class BlankCredentials < StandardError
    end

    # Invalid token?
    class GeniusQuery < StandardError
      class Blank < StandardError
      end

      class Malformed < StandardError
      end
    end

    class Quicklink < StandardError
      # Invalid token?
      class Client < StandardError
        class Blank < StandardError
        end

        class Malformed < StandardError
        end
      end

      # Invalid token?
      class Request < StandardError
        class Blank < StandardError
        end

        class Malformed < StandardError
        end
      end

      class Mode < StandardError
        class Malformed < StandardError
        end
      end
    end
  end

  # ============== Job - Exceptions =============
  class InvalidJob < StandardError
    # Should be risen when there is no record in jobs for a given job_id
    class Unknown < StandardError
    end
  end

  # ============== Subscription - Exceptions =============
  class Subscription < StandardError
    # Subscription is either expired or not existent
    class ExpiredOrMissing < StandardError
    end
  end
end
