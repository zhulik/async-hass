# frozen_string_literal: true

RSpec.describe Async::Hass do
  it "has a version number" do
    expect(Async::Hass::VERSION).not_to be nil
  end

  it "does something useful" do
    token = ENV.fetch("HASS_TOKEN")
    url = ENV.fetch("HASS_URL")

    api = Async::Hass::API.new(url, token)
    api.get_states

    reactor.with_timeout(5) do
      api.subscribe("state_changed") do |subscription, _event|
        break subscription.unsubscribe
      end
    end
    api.disconnect
  end
end
