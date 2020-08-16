# frozen_string_literal: true

require 'octokit'

module LabelValidator
  # Used to handle calls to VCS
  class Vcs
    def initialize(token:, pull_request:)
      @client = Octokit::Client.new(access_token: token)
      @pull_request = pull_request
      @comment_base = 'LabelValidator: This will be bumped on merge by a'
    end

    def status_check(state:)
      raise ArgumentError, 'State must be pending, success, failure' unless %w(pending success failure).include?(state)

      @client.create_status(@pull_request['head']['repo']['full_name'],
        @pull_request['head']['sha'],
        state,
        { :context => 'Release Label Validator',
          :description => 'Checking this commit has a single "Release: Major|Minor|Patch" label'
        }
      )
    end

    def delete_all_bot_comments()
      bot_comments = get_bot_comments(@comment_base)
      bot_comments.each do |comment|
        delete_comment(comment)
      end
    end

    def bot_comment(release_level)
      @comment_base = 'LabelValidator: This will be bumped on merge by a'
      comment_full = "#{@comment_base} #{release_level} version"

      bot_comments = get_bot_comments(@comment_base)
      if bot_comments.count > 0
          update_bot_comments(bot_comments, comment_full)
      else
        add_bot_comment(comment_full)
      end
    end

    private

    def get_bot_comments(filter)
      user = @client.user[:login]
      all_comments =  @client.issue_comments(@pull_request['head']['repo']['full_name'], @pull_request['number'])
      bot_comments = all_comments.select { |c| c[:user][:login] == user }
      filter_regex = Regexp.new(filter)
      return bot_comments.select { |c| c[:body] =~ filter_regex }
    end

    def add_bot_comment(body)
      @client.add_comment(@pull_request['head']['repo']['full_name'],
        @pull_request['number'],
        body
      )
    end

    def update_bot_comments(comments, body)
      if comments.count > 1
        # Something odd has gone all, delete all these commends
        comments.each do |comment|
          delete_comment(comment)
        end
        add_bot_comment(body)
      else
        unless comments[-1][:body] == body
          delete_comment(comments[0])
          add_bot_comment(body)
        end
      end
    end

    def delete_comment(comment)
      @client.delete_comment(@pull_request['head']['repo']['full_name'],
        comment['id']
      )
    end
  end
end
