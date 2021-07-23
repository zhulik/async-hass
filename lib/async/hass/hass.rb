# frozen_string_literal: true

module Async
  module Hass
    class HASS
      # TODO: add reconnects with retries
      # TODO: extract State
      def initialize(url, token, task: Task.current)
        @api = API.new(url, token, task: task)
        @task = task
        connect
      end

      def wait
        @tasks_barrier.wait
      end

      def disconnect
        @tasks_barrier.tasks.each(&:stop)
        @tasks_barrier.wait
        @tasks_barrier = nil
        @api.disconnect
      end

      private

      def connect
        @tasks_barrier = ::Async::Barrier.new(parent: @task)
        @tasks_barrier.async { update_states_task }
        @states = @api.get_states.group_by { |state| state[:entity_id] }.transform_values { |v| v[0] }
        p("States received")
      end

      def update_states_task
        subscription = @api.subscribe("state_changed")
        subscription.each do |event|
          if @states[event[:entity_id]] != event[:old_state] && !@states[event[:entity_id]].nil?
            raise "InconsistentLocalState"
          end

          @states[event[:entity_id]] = event[:new_state]
          p("State updated")
        end
      rescue Async::Stop
        subscription.unsubscribe
      end
    end
  end
end
