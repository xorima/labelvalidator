# frozen_string_literal: true

require 'sinatra'

require_relative 'labelvalidator/labels'
require_relative 'labelvalidator/vcs'
require_relative 'labelvalidator/hmac'

get '/' do
  "Hello World #{params[:name]}".strip
end

get '/hello' do
  "Hello World"
end

post '/event_handler_comments' do
  return halt 500, "Signatures didn't match!" unless validate_request(request)
  put('Passed signature check')
  payload = JSON.parse(params[:payload])

  case request.env['HTTP_X_GITHUB_EVENT']
  when 'pull_request'
    put('Is PR')
    if %w[labeled unlabeled opened reopened].include?(payload['action'])
      put(payload['action'])
      labels = LabelValidator::Labels.new(pull_request: payload['pull_request'])
      vcs = LabelValidator::Vcs.new(token: ENV['GITHUB_TOKEN'], pull_request: payload['pull_request'])
      put(vcs.default_branch_target?)
      return 'Only runs on Default branch' unless vcs.default_branch_target?
      put('Setting status check')
      vcs.status_check(state: 'pending')
      if labels.release_labeled?
        put('Processing labeled release')
        process_labeled_release(labels, vcs, payload)
        put('labels.semvar_level')
        return labels.semvar_level
      else
        put('Processing unlabeled release')
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
  put('Validating hmac signature')
  verify_signature(payload_body)
  put('Valid')
end

def process_labeled_release(labels, vcs, payload)
  put('Status seting to success')
  vcs.status_check(state: 'success')
  # There can be a race condition if labels are swapped so only comment
  # on added labels
  put('Adding comment for new label')
  vcs.bot_comment(labels.semvar_level) if payload['action'] == 'labeled'
end

def process_unlabeled_release(vcs)
  put('Setting status to failed')
  vcs.status_check(state: 'failure')
  put('Deleting all bot comments')
  vcs.delete_all_bot_comments
end
