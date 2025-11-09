Rails.application.configure do
  config.github_sign_in.client_id = FAKE_GITHUB_CLIENT_ID
  config.github_sign_in.client_secret = FAKE_GITHUB_CLIENT_SECRET

  # Default changed to basic auth. Use old :request_body for the sake of our test stubs.
  config.github_sign_in.oauth2_client_options = { auth_scheme: :request_body }
end
