# Github Sign-In for Rails

This gem allows you to add Github sign-in to your Rails app. You can let users sign up for and sign in to your service with their Github accounts.

## Installation

Add `github_sign_in` to your Rails app’s Gemfile and run `bundle install`:

```ruby
gem 'github_sign_in'
```

Github Sign-In for Rails requires Rails 6.1 or newer.

## Configuration

First, set up an OAuth App on Github:

1.  Go to your Github settings and navigate to "Developer settings".
2.  Click on "OAuth Apps" and then "New OAuth App".
3.  Enter your application's name.
4.  Set the "Homepage URL" to your application's homepage.
5.  This gem adds a single OAuth callback to your app at `/github_sign_in/callback`. Under **Authorization callback URL**, add that callback for your application’s domain: for example, `https://example.com/github_sign_in/callback`.
6.  To use Github sign-in in development, you’ll need to add another redirect URI for your local environment, like `http://localhost:3000/github_sign_in/callback`. For security reasons, we recommend using a separate OAuth app for local development.
7.  Click "Register application". You’ll be presented with a client ID and client secret. Save these.

With your client ID set up, configure your Rails application to use it. Run `bin/rails credentials:edit` to edit your app’s [encrypted credentials](https://guides.rubyonrails.org/security.html#custom-credentials) and add the following:

```yaml
github_sign_in:
  client_id: [Your client ID here]
  client_secret: [Your client secret here]
```

You’re all set to use Github sign-in now. The gem automatically uses the client ID and client secret in your credentials.

Alternatively, you can provide the client ID and client secret using ENV variables. Add a new initializer that sets `config.github_sign_in.client_id` and `config.github_sign_in.client_secret`:

```ruby
# config/initializers/github_sign_in.rb
Rails.application.configure do
  config.github_sign_in.client_id     = ENV['github_sign_in_client_id']
  config.github_sign_in.client_secret = ENV['github_sign_in_client_secret']
end
```

**⚠️ Important:** Take care to protect your client secret from disclosure to third parties.

(Optional) The callback route can be configured using:

```ruby
# config/initializers/github_sign_in.rb
Rails.application.configure do
  config.github_sign_in.root = "my_own/github_sign_in_route"
end
```

Which would make the callback `/my_own/github_sign_in_route/callback`.

## Usage

This gem provides a `github_sign_in_button` helper to generate a button that initiates Github sign-in:

```erb
<%= github_sign_in_button 'Sign in with my Github account', proceed_to: create_login_url %>

<%= github_sign_in_button image_tag('github_logo.png', alt: 'Github'), proceed_to: create_login_url %>

<%= github_sign_in_button proceed_to: create_login_url do %>
  Sign in with my <%= image_tag('github_logo.png', alt: 'Github') %> account
<% end %>
```

When using with Hotwire and Turbo, add the "turbo=false" HTML data attribute to the button to prevent Turbo from executing it asynchonously. For example:

```erb
<%= github_sign_in_button 'Sign in with my Github account',
      proceed_to: create_login_url,
      data: { turbo: "false" } %>
```

The `proceed_to` argument is required. After authenticating with Github, the gem redirects to `proceed_to`, providing the user's identity information in `flash[:github_sign_in][:identity]` or an [OAuth authorizaton code grant error](https://tools.ietf.org/html/rfc6749#section-4.1.2.1) in `flash[:github_sign_in][:error]`. Your application decides what to do with it:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # ...
  get 'login', to: 'logins#new'
  get 'login/create', to: 'logins#create', as: :create_login
end
```

```ruby
# app/controllers/logins_controller.rb
class LoginsController < ApplicationController
  def new
  end

  def create
    if user = authenticate_with_github
      cookies.signed[:user_id] = user.id
      redirect_to user
    else
      redirect_to new_session_url, alert: 'authentication_failed'
    end
  end

  private
    def authenticate_with_github
      if identity = flash[:github_sign_in][:identity]
        User.find_by github_id: identity['id']
      elsif error = flash[:github_sign_in][:error]
        logger.error "Github authentication error: #{error}"
        nil
      end
    end
end
```

(The above example assumes the user has already signed up for your service and that you’re storing their Github user ID in the `User#github_id` attribute.)

For security reasons, the `proceed_to` URL you provide to `github_sign_in_button` is required to reside on the same origin as your application. This means it must have the same protocol, host, and port as the page where `github_sign_in_button` is used. We enforce this before redirecting to the `proceed_to` URL to guard against [open redirects](https://www.owasp.org/index.php/Unvalidated_Redirects_and_Forwards_Cheat_Sheet).

### `GithubSignIn::Identity`

The `GithubSignIn::Identity` class fetches and exposes the profile information from the Github API. It exposes the profile information via the following instance methods:

*   `name`
*   `email_address`
*   `user_id`: A string that uniquely identifies a single Github user. Use this, not `email_address`, to associate a Github user with an application user.
*   `email_verified?`
*   `avatar_url`
*   `given_name`
*   `family_name`

## Security

For information on our security response procedure, see [SECURITY.md](SECURITY.md).

## Development

To set up dependencies locally:

``` sh
bin/setup
```

To run the tests against multiple versions of Rails:

``` sh
bin/test
```

## License

Github Sign-In for Rails is released under the [MIT License](https://opensource.org/licenses/MIT).

This is a derivative work of `github_sign_in` by Happybuild.