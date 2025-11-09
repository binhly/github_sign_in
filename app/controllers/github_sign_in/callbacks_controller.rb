require 'github_sign_in/redirect_protector'

class GithubSignIn::CallbacksController < GithubSignIn::BaseController
  def show
    redirect_to proceed_to_url, flash: { github_sign_in: github_sign_in_response }
    clear_redeemed_flash_keys if valid_request?
  rescue GithubSignIn::RedirectProtector::Violation => error
    logger.error error.message
    head :bad_request
  end

  private
    def proceed_to_url
      flash[:proceed_to].tap { |url| GithubSignIn::RedirectProtector.ensure_same_origin(url, request.url) }
    end

    def github_sign_in_response
      if valid_request? && params[:code].present?
        access_token = client.auth_code.get_token(params[:code])
        identity = GithubSignIn::Identity.new(access_token)
        { identity: identity.as_json }
      else
        { error: error_message_for(params[:error]) }
      end
    rescue OAuth2::Error => error
      { error: error_message_for(error.code) }
    rescue GithubSignIn::Identity::APIError => error
      { error: error.message }
    end

    def valid_request?
      flash[:state].present? && params[:state] == flash[:state]
    end

    def error_message_for(error_code)
      error_code.presence_in(GithubSignIn::OAUTH2_ERRORS) || "invalid_request"
    end

    # Clear keys we don't need anymore to reduce the session size.
    def clear_redeemed_flash_keys
      flash.delete(:proceed_to)
      flash.delete(:state)
    end
end
