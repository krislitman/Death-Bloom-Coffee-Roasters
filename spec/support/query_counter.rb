module QueryCounter
  IGNORED_QUERY_NAMES = ["SCHEMA", "TRANSACTION"].freeze

  def count_queries(&block)
    count = 0
    counter = ->(_name, _start, _finish, _id, payload) do
      count += 1 unless IGNORED_QUERY_NAMES.include?(payload[:name])
    end

    ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
    count
  end
end

RSpec.configure { |config| config.include QueryCounter }

RSpec::Matchers.define :issue_queries do |expected|
  supports_block_expectations
  include QueryCounter

  match do |block|
    @count = count_queries(&block)
    @count == expected
  end

  failure_message do
    "expected the block to issue #{expected} #{'query'.pluralize(expected)}, but it issued #{@count}"
  end
end
