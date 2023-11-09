require 'async'
require 'uri'
require 'net/http'
require 'tty/command'

module Forti
  module Alive
    class Connection
      attr_reader :logger

      def initialize(logger:)
        @logger = logger
      end

      def start
        Async do |_task|
          up

          loop do
            if alive?
              logger.info 'alive'
            else
              stop
              logger.error 'down'
              up
            end

            sleep 10
          end
        end
      end

      def alive?
        return if @job.nil? || @job.status != :running

        Timeout.timeout(5) do
          Net::HTTP.get_response(
            URI('https://gitlab.samokat.io/users/sign_in')
          ).code == '200'
        end
      rescue Timeout::Error, SocketError
        false
      end

      def up
        @job = Async do
          cmd = TTY::Command.new(pty: true)
          cmd.run 'sudo openfortivpn -c /Users/sergei/.forti'
        end
      end

      def stop
        @job.stop
      end
    end
  end
end
