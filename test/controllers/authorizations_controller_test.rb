require 'test_helper'

class GithubSignIn::AuthorizationsControllerTest < ActionDispatch::IntegrationTest
  default_authorize_url = GithubSignIn.authorize_url

  teardown do
    GithubSignIn.authorize_url = default_authorize_url
  end

  setup do
    @proceed_to = "http://www.example.com/login"
  end

  test "redirecting to Github for authorization" do
    post github_sign_in.authorization_url, params: { proceed_to: @proceed_to }

    assert_redirected_to_authorize
  end

  test "configuring Github authorization URL including query param" do
    GithubSignIn.authorize_url = "https://example.com/auth?param=value"

    post github_sign_in.authorization_url, params: { proceed_to: @proceed_to }

    assert_redirected_to_authorize do |params|
      assert_equal "value", params[:param]
    end
  end

  private
    def assert_redirected_to_authorize(proceed_to: @proceed_to)
      assert_response :redirect

      authorize_url = URI(GithubSignIn.authorize_url).tap { _1.query = nil }.to_s
      assert_match authorize_url, redirect_to_url

      params = extract_query_params_from(redirect_to_url)
      assert_equal FAKE_GITHUB_CLIENT_ID, params[:client_id]
      assert_equal "code", params[:response_type]
      assert_equal github_sign_in.callback_url, params[:redirect_uri]
      assert_equal "user:email read:user", params[:scope]
      assert_match /[A-Za-z0-9+\/]{32}/, params[:state]

      assert_equal proceed_to, flash[:proceed_to]
      assert_equal params[:state], flash[:state]

      yield params if block_given?
    end

    def extract_query_params_from(url)
      query = URI(url).query
      Rack::Utils.parse_query(query).symbolize_keys
    end
end
