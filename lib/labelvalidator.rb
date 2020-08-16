# frozen_string_literal: true
require 'sinatra'

require_relative 'labelvalidator/labels'
require_relative 'labelvalidator/vcs'

get '/' do
  "Hello World #{params[:name]}".strip
end

post '/event_handler_comments' do
  payload = JSON.parse(params[:payload])

  case request.env['HTTP_X_GITHUB_EVENT']
  when 'pull_request'
    if payload['action'] == 'labeled' || payload['action'] == 'unlabeled'
      labels = LabelValidator::Labels.new(pull_request: payload['pull_request'])
      vcs = LabelValidator::Vcs.new(token: ENV['GITHUB_TOKEN'], pull_request: payload['pull_request'])
      vcs.status_check(state: 'pending')
      if labels.release_labeled?
        vcs.status_check(state: 'success')
        # There can be a race condition if labels are swapped so only comment
        # on added labels
        vcs.bot_comment(labels.semvar_level) if payload['action'] == 'labeled'
        return labels.semvar_level
      else
        vcs.status_check(state: 'failure')
        vcs.delete_all_bot_comments()
        return 'not release labeled'
      end
    end
  end
end
