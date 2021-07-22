# frozen_string_literal: true

module Async
  module Hass
    class Client
      def initialize(url, token)
        @token = token
        @endpoint = Async::HTTP::Endpoint.parse(url, alpn_protocols: Async::HTTP::Protocol::HTTP11.names)
        @requests = {}
        @request_queue = ::Async::Queue.new
      end

      def connect # rubocop:disable Metrics/MethodLength
        # TODO: gracefully handle disconnects on every stage of the work
        raise "AlreadyConnectedError" if connected?

        @aithenticated = false
        @authencated_notification = Async::Notification.new

        @client = ::Async::WebSocket::Client.open(@endpoint)
        @connection = @client.connect(@endpoint.authority, @endpoint.path)
        @current_id = 1

        @tasks_barrier = ::Async::Barrier.new(parent: @task)

        @tasks_barrier.async { request_task }
        @tasks_barrier.async { response_task }
        @authencated_notification.wait
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
        raise "ResourceLeakError", "query queue empty: #{@request_queue.count} items" unless @request_queue.empty?
      end

      def connected?
        !@connection.nil?
      end

      def authenticated?
        @authenticated.nil?
      end

      def submit(message, id: next_id)
        if id
          message = message.merge(id: id)
          @requests[id] = Async::Notification.new
        end
        @request_queue << message
        @requests[id] # Returns nil if id is not passed
      end

      private

      def request_task
        @request_queue.each do |request|
          @connection.write(request)
          @connection.flush
        end
      rescue StandardError
        raise "DisconnectError"
      end

      def response_task # rubocop:disable Metrics/MethodLength
        loop do
          message = @connection.read
          case message # TODO: pattern matching?
          in {type: "auth_required"}
            submit({ type: "auth", access_token: @token }, id: nil)
          in {type: "auth_ok"}
            @authenticated = true
            @authencated_notification.signal
          in {type: "auth_invalid"}
            raise "InvalidAuth"
          in {type: "result", success: true, result: result, id: id}
            @requests.delete(id).signal(result)
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
