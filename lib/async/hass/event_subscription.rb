# frozen_string_literal: true

module Async
  module Hass
    class EventSubscription
      def initialize(id, queue, client)
        @id = id
        @queue = queue
        @client = client
      end

      def each(&block)
        @queue.each(&block)
      end

      def unsubscribe
        # TODO: raise an exception and catch it in Hass#subscribe to gracefully exit the `subscribe` block
        _, queue = @client.submit({ type: "unsubscribe_events", subscription: @id })
        queue.each do # rubocop:disable Lint/UnreachableLoop
          break
        end
      end
    end
  end
end
