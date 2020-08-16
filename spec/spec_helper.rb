# Setup
require 'vcr'
require 'rack/test'
require 'rspec'

# Project
require 'labelvalidator'

# Tests
require_relative 'unit/labelvalidator'
require_relative 'unit/labels'

ENV['RACK_ENV'] = 'test'

module RSpecMixin
  include Rack::Test::Methods
  def app
    Sinatra::Application
  end
end

# For RSpec 2.x and 3.x
RSpec.configure { |c| c.include RSpecMixin }

VCR.configure do |c|
  record_mode =
    if ENV['GITHUB_CI']
      :none
    elsif ENV['OCTOKIT_TEST_VCR_RECORD']
      :all
    else
      :once
    end

  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock

  c.default_cassette_options = {
    preserve_exact_body_bytes: true,
    decode_compressed_response: true,
    record: record_mode
  }

  c.allow_http_connections_when_no_cassette = true
  c.configure_rspec_metadata!
  c.filter_sensitive_data('<GITHUB_TOKEN>') { ENV['GITHUB_TOKEN'] }

  c.filter_sensitive_data('<AUTH_TOKEN>') do |interaction|
    interaction.request.headers['Authorization'].first
  end
end
