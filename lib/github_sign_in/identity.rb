require 'active_support/core_ext/module/delegation'

module GithubSignIn
  class Identity
    class APIError < StandardError; end

    def initialize(access_token)
      @access_token = access_token
      set_payload
    end

    def user_id
      @payload["id"]
    end

    def name
      @payload["name"]
    end

    def email_address
      @payload["email"]
    end

    def email_verified?
      # GitHub doesn't provide email verification status in the user profile.
      # We can get user emails and check for `verified: true` but that's another API call.
      # For now, we'll consider the primary email as verified if it exists.
      !@payload["email"].nil?
    end

    def avatar_url
      @payload["avatar_url"]
    end

    def given_name
      name.to_s.split.first
    end

    def family_name
      name.to_s.split.last
    end

    def as_json(options = {})
      @payload
    end

    private
      def set_payload
        response = @access_token.get('https://api.github.com/user')
        if response.status == 200
          @payload = response.parsed
        else
          raise APIError, "Failed to fetch user information from GitHub API. Status: #{response.status}"
        end
      rescue OAuth2::Error => error
        raise APIError, error.message
      end
  end
end
