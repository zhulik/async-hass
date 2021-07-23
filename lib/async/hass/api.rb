# frozen_string_literal: true

module Async
  module Hass
    class API
      extend Forwardable

      def_delegators :@client, :connect, :disconnect, :requests

      def initialize(url, token, task: Task.current, autoconnect: true)
        @client = Client.new(url, token, task: task)
        @client.connect if autoconnect
      end

      def get_states # rubocop:disable Naming/AccessorMethodName
        _, queue = @client.submit({ type: "get_states" })
        queue.each do |response| # rubocop:disable Lint/UnreachableLoop
          return response
        end
      end

      def subscribe(event_type)
        # TODO: unsubscribe from all subscriptions on disconnect
        id, queue = @client.submit({ type: "subscribe_events", event_type: event_type })
        EventSubscription.new(id, queue, @client)
      end
    end
  end
end
