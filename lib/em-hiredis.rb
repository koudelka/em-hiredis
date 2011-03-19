require 'eventmachine'

module EM
  module Hiredis
    class << self
      attr_writer :logger

      def logger
        @logger ||= begin
          require 'logger'
          log = Logger.new(STDOUT)
          log.level = Logger::INFO
          log
        end
      end
    end
  end
end

#
# make sure we're reading from this directory before any installed versions
#
$:.unshift File.dirname(File.expand_path(__FILE__))

require 'hiredis/reader'
require 'em-hiredis/event_emitter'
require 'em-hiredis/connection'
require 'em-hiredis/client'
