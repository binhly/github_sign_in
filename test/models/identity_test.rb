require 'test_helper'

class GithubSignIn::IdentityTest < ActiveSupport::TestCase
  test "extracting user information" do
    stub_user_info_request 'test_token', id: '12345', name: 'John Doe', email: 'john.doe@example.com', avatar_url: 'https://github.com/avatar.png'
    identity = GithubSignIn::Identity.new(access_token('test_token'))

    assert_equal '12345', identity.user_id
    assert_equal 'John Doe', identity.name
    assert_equal 'john.doe@example.com', identity.email_address
    assert_equal 'https://github.com/avatar.png', identity.avatar_url
    assert_equal 'John', identity.given_name
    assert_equal 'Doe', identity.family_name
    assert identity.email_verified?
  end

  test "handling missing email" do
    stub_user_info_request 'test_token', id: '12345', name: 'John Doe', email: nil
    identity = GithubSignIn::Identity.new(access_token('test_token'))
    assert_not identity.email_verified?
  end

  test "handling API errors" do
    stub_request(:get, "https://api.github.com/user").to_return(status: 500)
    assert_raises GithubSignIn::Identity::APIError do
      GithubSignIn::Identity.new(access_token('test_token'))
    end
  end

  private
    def access_token(token)
      client = OAuth2::Client.new('test_client_id', 'test_client_secret', site: 'https://api.github.com')
      OAuth2::AccessToken.new(client, token)
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
