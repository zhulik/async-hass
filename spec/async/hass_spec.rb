# frozen_string_literal: true

RSpec.describe Async::Hass do
  it "has a version number" do
    expect(Async::Hass::VERSION).not_to be nil
  end

  it "does something useful" do
    token = ENV.fetch("HASS_TOKEN")
    url = ENV.fetch("HASS_URL")

    client = Async::Hass::Client.new(url, token)
    client.connect

    client.submit({ type: "get_states" })
    reactor.sleep(1)
    client.disconnect
  end
end
