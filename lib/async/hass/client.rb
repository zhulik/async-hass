# frozen_string_literal: true

module Async
  module Hass
    class Client
      def initialize(url, token)
        @token = token
        @endpoint = Async::HTTP::Endpoint.parse(url, alpn_protocols: Async::HTTP::Protocol::HTTP11.names)
        @requests = {}
        @query_queue = ::Async::Queue.new
      end

      def connect
        raise "AlreadyConnectedError" if connected?

        @client = ::Async::WebSocket::Client.open(@endpoint)
        @connection = @client.connect(@endpoint.authority, @endpoint.path)
        @current_id = 1

        @tasks_barrier = ::Async::Barrier.new(parent: @task)

        @tasks_barrier.async { query_task }
        @tasks_barrier.async { response_task }
      rescue StandardError
        raise "ConnectionError"
      end

      def disconnect # rubocop:disable Metrics/MethodLength
        raise NotConnectedError unless connected?

        @tasks_barrier.tasks.each(&:stop)
        @tasks_barrier.wait

        @connection.close
        @client.close

        @client = nil
        @connection = nil
        @tasks_barrier = nil
        @next_id = nil
        @authenticated = false

        unless @requests.empty?
          raise "ResourceLeakError",
                "ongoing requests list is not empty: #{@requests.count} items"
        end
        raise "ResourceLeakError", "query queue empty: #{@query.count} items" unless @query_queue.empty?
      end

      def connected?
        !@connection.nil?
      end

      def authenticated?
        @@authenticated.nil?
      end

      def submit(message, add_id: true)
        message = message.merge(id: next_id) if add_id
        @query_queue << message
      end

      private

      def query_task
        @query_queue.each do |query|
          @connection.write(query)
          @connection.flush
        end
      rescue StandardError
        raise "DisconnectError"
      end

      def response_task # rubocop:disable Metrics/MethodLength
        loop do
          message = @connection.read
          case message[:type] # TODO: pattern matching?
          when "auth_required"
            submit({ type: "auth", access_token: @token }, add_id: false)
          when "auth_ok"
            @authenticated = true
            next
          when "auth_invalid"
            raise "InvalidAuth"
          else
            p message
          end
        end
      rescue StandardError
        raise "DisconnectError"
      end

      def next_id
        @current_id + +
        @current_id
      end
    end
  end
end
