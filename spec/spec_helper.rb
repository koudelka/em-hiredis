require 'rspec'
require 'em-spec/rspec'

dir = File.dirname(File.expand_path(__FILE__))
require "#{dir}/../lib/em-hiredis"

TEST_HOST = {
  :host => 'redis'
}

RSpec.configure do |config|
  # == Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  config.mock_with :rspec

  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, comment the following line or assign false
  # instead of true.
  #config.use_transactional_fixtures = true
end

EM::Hiredis.logger.level = Logger::WARN

def hiredis_test
  @redis ||= EM::Hiredis::Client.connect(:host => TEST_HOST[:host])
  @redis.flushall
  yield @redis
end

def wait_for_test(num_tests = 1)
  @outstanding_tests ||= 0
  @outstanding_tests += num_tests
end
alias :wait_for_tests :wait_for_test

def finished_test(num_tests = 1)
  @outstanding_tests -= num_tests
  if @outstanding_tests == 0
    done
  elsif @outstanding_tests < 0
    raise "too many tests claimed completion"
  end
end


