require 'rails/engine'
require 'github_sign_in' unless defined?(GithubSignIn)

module GithubSignIn
  class Engine < ::Rails::Engine
    isolate_namespace GithubSignIn

    # Set default config so apps can modify rather than starting from nil, e.g.
    #
    #   config.github_sign_in.authorize_url += "?disallow_webview=true"
    #
    config.github_sign_in = ActiveSupport::OrderedOptions.new.update \
      authorize_url: GithubSignIn.authorize_url,
      token_url: GithubSignIn.token_url

    initializer 'github_sign_in.config' do |app|
      config.after_initialize do
        GithubSignIn.client_id     = config.github_sign_in.client_id || app.credentials.dig(:github_sign_in, :client_id)
        GithubSignIn.client_secret = config.github_sign_in.client_secret || app.credentials.dig(:github_sign_in, :client_secret)
        GithubSignIn.authorize_url = config.github_sign_in.authorize_url
        GithubSignIn.token_url     = config.github_sign_in.token_url

        GithubSignIn.oauth2_client_options = config.github_sign_in.oauth2_client_options
      end
    end

    config.to_prepare do
      ActionController::Base.helper GithubSignIn::Engine.helpers
    end

    initializer 'github_sign_in.mount' do |app|
      app.routes.prepend do
        mount GithubSignIn::Engine, at: app.config.github_sign_in.root || 'github_sign_in'
      end
    end

    initializer 'github_sign_in.parameter_filters' do |app|
      app.config.filter_parameters << :code
    end
  end
end
