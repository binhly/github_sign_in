ENV['RAILS_ENV'] = 'test'

FAKE_GITHUB_CLIENT_ID = '1234567890'
FAKE_GITHUB_CLIENT_SECRET = 'abcdefghijklmnopqrstuvwxyz'

require_relative '../test/dummy/config/environment'

require 'rails/test_help'
require 'webmock/minitest'
require 'byebug'

class ActionView::TestCase
  private
    def assert_dom_equal(expected, actual, message = nil)
      super expected.remove(/(\A|\n)\s*/), actual, message
    end
end
