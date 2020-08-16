# frozen_string_literal: true
require 'sinatra'

require_relative 'labelvalidator/labels'

get '/' do
  "Hello World #{params[:name]}".strip
end

post '/event_handler_comments' do
  payload = JSON.parse(params[:payload])

  case request.env['HTTP_X_GITHUB_EVENT']
  when 'pull_request'
    if payload['action'] == 'labeled'
      puts('*****labelled')
      labels = LabelValidator::Labels.new(pull_request: payload["pull_request"])
      if labels.release_labeled?

        puts(labels.semvar_level)
        return labels.semvar_level
      else
        puts('not release labeled')
        return 'not release labeled'
      end
    end
  end
end
