# frozen_string_literal: true

require 'spec_helper'

describe LabelValidator::Labels do
  # Check Vcs creates an OctoKit client
  before(:all) do
    @bad_result = {
      'labels' => [
        {
          'id' => 1_767_273_436,
          'node_id' => 'MDU6TGFiZWwxNzY3MjczNDM2',
          'url' => 'https://api.github.com/repos/Xorima/xor_test_cookbook/labels/Bug',
          'name' => 'Bug',
          'color' => 'bc2d2d',
          'default' => false,
          'description' => "Something isn't working"
        }
      ]
    }
    @good_result = {
      'labels' => [
        {
          'id' => 1_767_273_436,
          'node_id' => 'MDU6TGFiZWwxNzY3MjczNDM2',
          'url' => 'https://api.github.com/repos/Xorima/xor_test_cookbook/labels/Bug',
          'name' => 'Release: Major',
          'color' => 'bc2d2d',
          'default' => false,
          'description' => "Something isn't working"
        }
      ]
    }
  end

  it 'Creates a Labels instance' do
    labels_negative_client = LabelValidator::Labels.new({
                                                          pull_request: @bad_result
                                                        })
    labels_positive_client = LabelValidator::Labels.new({
                                                          pull_request: @good_result
                                                        })

    expect(labels_negative_client).to be_kind_of(LabelValidator::Labels)
    expect(labels_positive_client).to be_kind_of(LabelValidator::Labels)
  end

  it 'returns true if the pull request is release labeled' do
    labels_client = LabelValidator::Labels.new({
                                                 pull_request: @good_result
                                               })
    expect(labels_client.release_labeled?).to eq true
  end

  it 'returns false if the pull request is not release labeled' do
    labels_client = LabelValidator::Labels.new({
                                                 pull_request: @bad_result
                                               })
    expect(labels_client.release_labeled?).to eq false
  end

  it 'returns the correct semvar level lowercase when labeled' do
    labels_client = LabelValidator::Labels.new({
                                                 pull_request: @good_result
                                               })
    expect(labels_client.semvar_level).to eq 'major'
  end
end
