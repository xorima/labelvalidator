# frozen_string_literal: true

require_relative '../spec_helper'

describe 'My Hello World App' do
  it 'should allow access to the home page' do
    get '/'
    expect(last_response).to be_ok
  end
end
