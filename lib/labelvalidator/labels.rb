# frozen_string_literal: true

module LabelValidator
  # Used to handle calls to VCS
  class Labels
    def initialize(pull_request:)
      @pull_request = pull_request
      @label = release_label
    end

    attr_reader :label

    def release_labeled?
      return true if @label

      false
    end

    def semvar_level
      @label.downcase.gsub('release: ', '')
    end

    protected

    def release_label
      release_labels = @pull_request['labels'].select { |l| l['name'] =~ /^release:\s(major|minor|patch)/i }
      release_labels[0]['name'] if release_labels.count == 1
    end
  end
end
