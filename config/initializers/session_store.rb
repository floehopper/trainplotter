# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_trainplotter_session',
  :secret      => '6d2bfae420c17f56518d0ba81feecbf1ed89db93425ab5a16f05fcad33f39db7d57601b2e404f868ba2349fdbe89b7ff6dc06a09ceaf9e484e043c887095b3df'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
