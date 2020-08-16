# frozen_string_literal: true

require 'octokit'

module LabelValidator
  # Used to handle calls to VCS
  class Vcs
    def initialize(token:, repository:, pr_number:)
      @client = Octokit::Client.new(access_token: token)
      @pull_request = @client.pull_request(repository, pr_number)
    end

    def merged?
      @pull_request.merged?
    end

    def labelled_release?
      @pull_request.labels.detect { |l| l[:name] =~ /major|minor|patch/i } ? true : false
    end
  end
end
