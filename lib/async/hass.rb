# frozen_string_literal: true

require "async/websocket/client"
require "async/http/endpoint"
require "async/queue"
require "async/barrier"

require "async/hass/version"
require "async/hass/client"

module Async
  module Hass
    class Error < StandardError; end
    # Your code goes here...
  end
end