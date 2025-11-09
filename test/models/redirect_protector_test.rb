require 'test_helper'
require 'github_sign_in/redirect_protector'

class GithubSignIn::RedirectProtectorTest < ActiveSupport::TestCase
  test "disallows URL target with different host than source" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin 'https://malicious.example.com', 'https://happybuild.com'
    end
  end

  test "disallows URL target that is not a valid URL" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin 'https://happybuild.com\\n\\r@\\n\\revil.com', 'https://happybuild.com'
    end
  end

  test "disallows URL target that is blank" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin '', 'https://happybuild.com'
    end
  end

  test "disallows URL target with different port than source" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin 'https://happybuild.com:10443', 'https://happybuild.com'
    end
  end

  test "disallows URL target with different protocol than source" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin 'http://happybuild.com', 'https://happybuild.com'
    end
  end

  test "disallows empty URL target" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin nil, 'https://happybuild.com'
    end
  end

  test "allows URL target with same origin as source" do
    assert_nothing_raised do
      GithubSignIn::RedirectProtector.ensure_same_origin 'https://happybuild.com', 'https://happybuild.com'
    end
  end

  test "disallows relative path target" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin 'callback', 'https://happybuild.com'
    end
  end

  test "allows absolute path target" do
    assert_nothing_raised do
      GithubSignIn::RedirectProtector.ensure_same_origin '/callback', 'https://happybuild.com'
    end
  end

  test "disallows double-slash path target" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin '//evil.example.org', 'https://happybuild.com'
    end
  end

  test "disallows triple-slash path target" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin '///evil.example.org', 'https://happybuild.com'
    end
  end

  test "disallows invalid paths" do
    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin '/a path with spaces is invalid', 'https://happybuild.com'
    end

    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin '/path#with-fragment', 'https://happybuild.com'
    end

    assert_raises GithubSignIn::RedirectProtector::Violation do
      GithubSignIn::RedirectProtector.ensure_same_origin '/path?with=query', 'https://happybuild.com'
    end
  end
end
