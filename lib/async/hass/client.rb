# frozen_string_literal: true

module Async
  module Hass
    class Client
      def initialize(url, token, task: Task.current)
        @task = task
        @token = token
        @endpoint = Async::HTTP::Endpoint.parse(url, alpn_protocols: Async::HTTP::Protocol::HTTP11.names)
      end

      def connect # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        # TODO: gracefully handle disconnects on every stage of the work
        raise "AlreadyConnectedError" if connected?

        @requests = {}
        @request_queue = ::Async::Queue.new

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

        @requests_queue = nil
        @requests = nil
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
          @requests[id] = { queue: Async::Queue.new, message: message }
        end
        @request_queue << message
        [id, @requests.dig(id, :queue)] # Returns nils if id is nil
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

      def response_task # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        loop do
          message = @connection.read
          case message
          in {type: "auth_required"}
            submit({ type: "auth", access_token: @token }, id: nil)
          in {type: "auth_ok"}
            @authenticated = true
            @authencated_notification.signal
          in {type: "auth_invalid"}
            raise "InvalidAuth"
          in {type: "result", success: true, result: result, id: id}
            request = @requests[id]
            next if request.dig(:message, :type) == "subscribe_events"

            @requests.delete(request.dig(:message, :subscription)) if request.dig(:message,
                                                                                  :type) == "unsubscribe_events"
            @requests.delete(id)[:queue] << result
          in {type: "event", event: {data: data}, id: id}
            @requests.dig(id, :queue) << data
          end
        end
      rescue StandardError
        raise "DisconnectError"
      end

      def next_id
        @current_id += 1
        @current_id
      end
    end
  end
end
