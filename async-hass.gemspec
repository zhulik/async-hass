# frozen_string_literal: true

require_relative "lib/async/hass/version"

Gem::Specification.new do |spec|
  spec.name          = "async-hass"
  spec.version       = Async::Hass::VERSION
  spec.authors       = ["Gleb Sinyavskiy"]
  spec.email         = ["zhulik.gleb@gmail.com"]

  spec.summary       = "Async ruby client for the home assistant WebSocket API."
  spec.description   = "Async ruby client for the home assistant WebSocket API."
  spec.homepage      = "https://github.com/zhulik/async-hass"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 3.0.0")

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/zhulik/async-hass"
  spec.metadata["changelog_uri"] = "https://github.com/zhulik/async-hass" # TODO: fixme

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "async-websocket"
end
