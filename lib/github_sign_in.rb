require 'active_support'
require 'active_support/rails'
require 'oauth2'

module GithubSignIn
  mattr_accessor :client_id
  mattr_accessor :client_secret
  mattr_accessor :authorize_url, default: "https://github.com/login/oauth/authorize"
  mattr_accessor :token_url, default: "https://github.com/login/oauth/access_token"
  mattr_accessor :oauth2_client_options, default: nil

  # https://tools.ietf.org/html/rfc6749#section-4.1.2.1
  authorization_request_errors = %w[
    invalid_request
    unauthorized_client
    access_denied
    unsupported_response_type
    invalid_scope
    server_error
    temporarily_unavailable
  ]

  # https://tools.ietf.org/html/rfc6749#section-5.2
  access_token_request_errors = %w[
    invalid_request
    invalid_client
    invalid_grant
    unauthorized_client
    unsupported_grant_type
    invalid_scope
  ]

  # Authorization Code Grant errors from both authorization requests
  # and access token requests.
  OAUTH2_ERRORS = authorization_request_errors | access_token_request_errors

  def self.oauth2_client(redirect_uri:)
    OAuth2::Client.new \
      GithubSignIn.client_id,
      GithubSignIn.client_secret,
      authorize_url: GithubSignIn.authorize_url,
      token_url: GithubSignIn.token_url,
      redirect_uri: redirect_uri,
      **GithubSignIn.oauth2_client_options.to_h
  end
end

require 'github_sign_in/identity'
require 'github_sign_in/engine' if defined?(Rails) && !defined?(GithubSignIn::Engine)
