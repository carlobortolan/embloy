# CustomExceptions INTERNAL Documentation

> This document provides further information for the [custom_exceptions.rb](./custom_exceptions.rb) class.
***

### 1. InvalidUser

You should only expect the following subclasses of ``::InvalidUser``

+ ``::Unknown``: When there is no record for a given ``<user_id>``
+ ``::CredentialsWrong``: When the user's credentials are not valid and the authentication process failed
+ ``::LoggedOut``: > (non-api-only) When the session token is invalid / nil  (``Current.user`` is nil)
+ ``::Inactive``: ``Current.user`` is deactivated (``activity_status = 0``)

***

### 2. Unauthorized

You should only expect the following subclasses of ``::Unauthorized``

+ ``::NotOwner``: ``Current.user`` is not owner of resource that he is trying to access
+ ``::InsufficientRole``: User does not have the required role to access the resource
    + ``::NotAdmin``
    + ``::NotEditor``
    + ``::NotDeveloper``
    + ``::NotModerator``
    + ``::NotVerified``
+ ``::Blocked``: User is blacklisted

####

***

### 3. InvalidInput

You should only expect the following subclasses of ``::InvalidInput``

+ ``::Token``: When the``<refresh_token>`` is invalid
+ ``::SUB``: When the ``<refresh_token>`` is malformed (e.g., ``user_id`` not an Integer)
+ ``::CustomEXP``: When the ``<refresh_token>`` expired
  ####

***

### 4. Additional ideas ... 
