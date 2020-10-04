# frozen_string_literal: true

require 'spec_helper'

describe LabelValidator::Vcs, :vcr do
  # Check Vcs creates an OctoKit client
  before(:each) do
    pull_request = { 'base' => { 'ref' => 'master', 'repo' => { 'default_branch' => 'master', 'full_name' => 'Xorima/xor_test_cookbook' } },
                     'head' => { 'sha' => '202ae3fd1b76a28c9272372a29ae9b8070a79f48' },
                     'number' => 22 }
    @vcs_client = LabelValidator::Vcs.new({
                                            token: ENV['GITHUB_TOKEN'] || 'temp_token',
                                            pull_request: pull_request,
                                            comments_enabled: true,
                                          })
  end

  it 'creates an octkit client' do
    expect(@vcs_client).to be_kind_of(LabelValidator::Vcs)
  end

  it 'returns true if the pull request is against the default branch' do
    expect(@vcs_client.default_branch_target?).to eq true
  end

  it 'creates a pending status check' do
    expect(@vcs_client.status_check(state: 'pending')[:state]).to eq 'pending'
  end

  it 'creates a failed status check' do
    expect(@vcs_client.status_check(state: 'failure')[:state]).to eq 'failure'
  end

  it 'creates a sucessful status check' do
    expect(@vcs_client.status_check(state: 'success')[:state]).to eq 'success'
  end

  it 'creates a comment' do
    comment = @vcs_client.bot_comment('testing')
    expect(comment[:body]).to eq 'LabelValidator: This will be bumped on merge by a testing version'
    expect(comment[:user][:login]).to eq 'Xorima'
  end
  it 'updates an existing comment' do
    comment = @vcs_client.bot_comment('foobar')
    expect(comment[:body]).to eq 'LabelValidator: This will be bumped on merge by a foobar version'
    expect(comment[:user][:login]).to eq 'Xorima'
  end
end
