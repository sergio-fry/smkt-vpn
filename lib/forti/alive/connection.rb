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

            sleep 30
          end
        end
      end

      def alive?
        return if @job.nil? || @job.status != :running

        Timeout.timeout(5) do
          cmd = TTY::Command.new(printer: :quiet)
          _, err = cmd.run "curl -sSf -H 'PRIVATE-TOKEN: #{ENV.fetch('PRIVATE_TOKEN')}' https://gitlab.samokat.io/api/v4/version > /dev/null"
          logger.error(err) unless err == ''

          err == ''
        end
      rescue Timeout::Error, SocketError, TTY::Command::ExitError => e
        logger.error e

        false
      end

      def up
        @job = Async do
          cmd = TTY::Command.new(pty: true, printer: :null)
          cmd.run 'sudo openfortivpn -c /Users/sergei/.forti'
        end
      end

      def stop
        @job.stop
        @job = nil
      end
    end
  end
end
