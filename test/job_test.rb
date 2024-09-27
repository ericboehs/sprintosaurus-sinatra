# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
require './environment'
require './job'

require 'minitest/autorun'
require 'mocha/minitest'

describe Github::Project do
  describe '#handle_rate_limit' do
    it 'handles rate limit correctly' do
      mock_client = mock 'Octokit::Client'
      mock_rate_limit = mock 'RateLimit'
      mock_client.expects(:rate_limit).returns mock_rate_limit

      mock_rate_limit.expects(:remaining).returns 5
      mock_rate_limit.expects(:resets_in).returns 60

      Github::Project.any_instance.stubs(:client).returns mock_client
      project = Github::Project.new token: 'test_token', organization: 'test_org', number: 1

      $logger.expects(:info).with 'Rate limit almost exceeded, sleeping for 60 seconds...' # rubocop:disable Style/GlobalVars
      project.expects(:sleep).with 60

      project.send :handle_rate_limit
    end
  end
end
