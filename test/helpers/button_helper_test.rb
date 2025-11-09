require "test_helper"

class GithubSignIn::ButtonHelperTest < ActionView::TestCase
  test "generating a login button with text content" do
    assert_dom_equal <<-HTML, github_sign_in_button("Log in with Github", proceed_to: "https://www.example.com/login")
      <form action="/github_sign_in/authorization" accept-charset="UTF-8" method="post">
        <input name="proceed_to" type="hidden" value="https://www.example.com/login" autocomplete="off" />
        <button type="submit">Log in with Github</button>
      </form>
    HTML
  end

  test "generating a login button with HTML content" do
    assert_dom_equal <<-HTML, github_sign_in_button(proceed_to: "https://www.example.com/login") { image_tag("github.png") }
      <form action="/github_sign_in/authorization" accept-charset="UTF-8" method="post">
        <input name="proceed_to" type="hidden" value="https://www.example.com/login" autocomplete="off" />
        <button type="submit"><img src="/images/github.png"></button>
      </form>
    HTML
  end

  test "generating a login button with custom attributes" do
    button = github_sign_in_button("Log in with Github", proceed_to: "https://www.example.com/login",
      class: "login-button", data: { disable_with: "Loading Github login…" })

    assert_dom_equal <<-HTML, button
      <form action="/github_sign_in/authorization" accept-charset="UTF-8" method="post">
        <input name="proceed_to" type="hidden" value="https://www.example.com/login" autocomplete="off" />
        <button type="submit" class="login-button" data-disable-with="Loading Github login…">Log in with Github</button>
      </form>
    HTML
  end
end
