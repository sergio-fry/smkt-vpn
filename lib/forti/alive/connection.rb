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
          cmd = TTY::Command.new(printer: :quiet)
          _, err = cmd.run 'curl https://gitlab.samokat.io/users/sign_in'
          logger.error(err) if err
        end
      rescue Timeout::Error, SocketError, TTY::Command::ExitError => ex
        logger.error ex

        false
      end

      def up
        @job = Async do
          cmd = TTY::Command.new(pty: true)
          cmd.run 'openfortivpn -c /Users/sergei/.forti'
        end
      end

      def stop
        @job.stop
        @job = nil
      end
    end
  end
end
