# frozen_string_literal: true

require 'sinatra'

require_relative 'labelvalidator/labels'
require_relative 'labelvalidator/vcs'
require_relative 'labelvalidator/hmac'

get '/' do
  "Hello World #{params[:name]}".strip
end

get '/hello' do
  'Hello World'
end

post '/event_handler_comments' do
  return halt 500, "Signatures didn't match!" unless validate_request(request)

  payload = JSON.parse(params[:payload])

  case request.env['HTTP_X_GITHUB_EVENT']
  when 'pull_request'
    if %w[labeled unlabeled opened reopened].include?(payload['action'])
      labels = LabelValidator::Labels.new(pull_request: payload['pull_request'])
      vcs = LabelValidator::Vcs.new(token: ENV['GITHUB_TOKEN'], pull_request: payload['pull_request'])
      return 'Only runs on Default branch' unless vcs.default_branch_target?

      vcs.status_check(state: 'pending')
      if labels.release_labeled?
        process_labeled_release(labels, vcs, payload)
        return labels.semvar_level
      else
        process_unlabeled_release(vcs)
        return 'not release labeled'
      end
    end
  end
end

def validate_request(request)
  true unless ENV['SECRET_TOKEN']
  request.body.rewind
  payload_body = request.body.read
  verify_signature(payload_body)
end

def process_labeled_release(labels, vcs, payload)
  vcs.status_check(state: 'success')
  # There can be a race condition if labels are swapped so only comment
  # on added labels
  vcs.bot_comment(labels.semvar_level) if payload['action'] == 'labeled'
end

def process_unlabeled_release(vcs)
  vcs.status_check(state: 'failure')
  vcs.delete_all_bot_comments
end
