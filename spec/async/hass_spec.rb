# frozen_string_literal: true

RSpec.describe Async::Hass do
  it "has a version number" do
    expect(Async::Hass::VERSION).not_to be nil
  end

  it "does something useful" do
    token = ENV.fetch("HASS_TOKEN")
    url = ENV.fetch("HASS_URL")

    hass = Async::Hass::Hass.new(url, token)
    hass.get_states

    reactor.with_timeout(5) do
      hass.subscribe("state_changed") do |subscription, _event|
        break subscription.unsubscribe
      end
    end
    hass.disconnect
  end
end
