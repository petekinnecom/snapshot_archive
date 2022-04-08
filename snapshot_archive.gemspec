# frozen_string_literal: true

require_relative "lib/snapshot_archive/version"

Gem::Specification.new do |spec|
  spec.name          = "snapshot_archive"
  spec.version       = SnapshotArchive::VERSION
  spec.authors       = ["Pete Kinnecom"]
  spec.email         = ["git@k7u7.com"]

  spec.summary       = <<~TEXT.chomp
    Save and restore snapshots of stateful services to a central archive. The
    default action is to backup all databases for the current rails apps,
    however, custom actions can easily be configured.
  TEXT

  spec.homepage      = "https://github.com/petekinnecom/snapshot_archive"
  spec.license       = "WTFPL"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.4.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency("commander", "~> 4.5")
end
