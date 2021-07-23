# frozen_string_literal: true

require "async/websocket/client"
require "async/http/endpoint"
require "async/queue"
require "async/barrier"
require "async/notification"

require "async/hass/version"
require "async/hass/client"
require "async/hass/api"
require "async/hass/hass"
require "async/hass/event_subscription"

module Async
  # TODO: rename to HASS
  module Hass
    class Error < StandardError; end
    # Your code goes here...
  end
end
