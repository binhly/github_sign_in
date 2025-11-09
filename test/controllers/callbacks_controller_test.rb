require 'test_helper'

class GithubSignIn::CallbacksControllerTest < ActionDispatch::IntegrationTest
  test "receiving an authorization code" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
    assert_response :redirect

    stub_token_for 'the-code', access_token: 'the-access-token'
    stub_user_info_request 'the-access-token', id: '12345', name: 'John Doe', email: 'john.doe@example.com'

    get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
    assert_redirected_to 'http://www.example.com/login'

    identity = flash[:github_sign_in][:identity]
    assert_equal '12345', identity['id']
    assert_equal 'John Doe', identity['name']
    assert_equal 'john.doe@example.com', identity['email']
    assert_nil flash[:github_sign_in][:error]
    assert_nil flash[:state]
    assert_nil flash[:proceed_to]
  end

  # Authorization request errors: https://tools.ietf.org/html/rfc6749#section-4.1.2.1
  %w[ invalid_request unauthorized_client access_denied unsupported_response_type invalid_scope server_error temporarily_unavailable ].each do |error|
    test "receiving an authorization code grant error: #{error}" do
      post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
      assert_response :redirect

      get github_sign_in.callback_url(error: error, state: flash[:state])
      assert_redirected_to 'http://www.example.com/login'
      assert_nil flash[:github_sign_in][:identity]
      assert_equal error, flash[:github_sign_in][:error]
    end
  end

  test "receiving an invalid authorization error" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
    assert_response :redirect

    get github_sign_in.callback_url(error: 'unknown error code', state: flash[:state])
    assert_redirected_to 'http://www.example.com/login'
    assert_nil flash[:github_sign_in][:identity]
    assert_equal "invalid_request", flash[:github_sign_in][:error]
  end

  test "receiving neither code nor error" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
    assert_response :redirect

    get github_sign_in.callback_url(state: flash[:state])
    assert_redirected_to 'http://www.example.com/login'
    assert_nil flash[:github_sign_in][:identity]
    assert_equal 'invalid_request', flash[:github_sign_in][:error]
  end

  # Access token request errors: https://docs.github.com/en/developers/apps/authorizing-oauth-apps#error-codes-for-the-device-flow
  %w[ invalid_request invalid_client invalid_grant unauthorized_client unsupported_grant_type ].each do |error|
    test "receiving an access token request error: #{error}" do
      post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
      assert_response :redirect

      stub_token_error_for 'the-code', error: error

      get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
      assert_redirected_to 'http://www.example.com/login'
      assert_nil flash[:github_sign_in][:identity]
      assert_equal error, flash[:github_sign_in][:error]
    end
  end

  test "protecting against CSRF without flash state" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
    assert_response :redirect

    get github_sign_in.callback_url(code: 'the-code', state: 'invalid')
    assert_redirected_to 'http://www.example.com/login'
    assert_nil flash[:github_sign_in][:identity]
    assert_equal 'invalid_request', flash[:github_sign_in][:error]
  end

  test "protecting against CSRF with invalid state" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
    assert_response :redirect
    assert_not_nil flash[:state]

    get github_sign_in.callback_url(code: 'the-code', state: 'invalid')
    assert_redirected_to 'http://www.example.com/login'
    assert_nil flash[:github_sign_in][:identity]
    assert_equal 'invalid_request', flash[:github_sign_in][:error]
  end

  test "protecting against CSRF with missing state" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com/login' }
    assert_response :redirect
    assert_not_nil flash[:state]

    get github_sign_in.callback_url(code: 'the-code')
    assert_redirected_to 'http://www.example.com/login'
    assert_nil flash[:github_sign_in][:identity]
    assert_equal 'invalid_request', flash[:github_sign_in][:error]
  end

  test "protecting against open redirects" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://malicious.example.com/login' }
    assert_response :redirect

    get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
    assert_response :bad_request
  end

  test "protecting against open redirects given a malformed URI" do
    post github_sign_in.authorization_url, params: { proceed_to: 'http://www.example.com\n\r@\n\revil.example.org/login' }
    assert_response :redirect

    get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
    assert_response :bad_request
  end

  test "rejects proceed_to paths if they are relative" do
    post github_sign_in.authorization_url, params: { proceed_to: 'login' }
    assert_response :redirect

    get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
    assert_response :bad_request
  end

  test "accepts proceed_to paths if they are absolute" do
    post github_sign_in.authorization_url, params: { proceed_to: '/login' }
    assert_response :redirect

    stub_token_for 'the-code', access_token: 'the-access-token'
    stub_user_info_request 'the-access-token', id: '12345'

    get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
    assert_redirected_to 'http://www.example.com/login'
  end

  test "protecting against open redirects given a double-slash net path" do
    post github_sign_in.authorization_url, params: { proceed_to: '//evil.example.org' }
    assert_response :redirect

    get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
    assert_response :bad_request
  end

  test "protecting against open redirects given a triple-slash net path" do
    post github_sign_in.authorization_url, params: { proceed_to: '///evil.example.org' }
    assert_response :redirect

    get github_sign_in.callback_url(code: 'the-code', state: flash[:state])
    assert_response :bad_request
  end

  test "receiving no proceed_to URL" do
    get github_sign_in.callback_url(code: 'the-code', state: 'invalid')
    assert_response :bad_request
  end

  private
    def stub_token_for(code, access_token:)
      stub_token_request(code, status: 200, response: { access_token: access_token })
    end

    def stub_token_error_for(code, error:)
      stub_token_request(code, status: 418, response: { error: error })
    end

    def stub_token_request(code, status:, response:)
      stub_request(:post, 'https://github.com/login/oauth/access_token').with(
        body: {
          grant_type: 'authorization_code',
          code: code,
          client_id: FAKE_GITHUB_CLIENT_ID,
          client_secret: FAKE_GITHUB_CLIENT_SECRET,
          redirect_uri: 'http://www.example.com/github_sign_in/callback'
        }
      ).to_return(
        status: status,
        headers: { 'Content-Type' => 'application/json' },
        body: JSON.generate(response)
      )
    end

    def stub_user_info_request(access_token, **user_info)
      stub_request(:get, "https://api.github.com/user").with(
        headers: { 'Authorization' => "Bearer #{access_token}" }
      ).to_return(
        status: 200,
        headers: { 'Content-Type' => 'application/json' },
        body: JSON.generate(user_info)
      )
    end
end
