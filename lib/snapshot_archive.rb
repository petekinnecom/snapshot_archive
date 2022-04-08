# frozen_string_literal: true

require_relative "snapshot_archive/version"
require_relative "snapshot_archive/cfg"

module SnapshotArchive
  class Error < StandardError; end

  DESCRIPTION = <<~TEXT.chomp
    Save and restore snapshots of stateful services to a central archive. The
    default action is to backup all databases for the current rails apps,
    however, custom actions can easily be configured.

    See https://github.com/petekinnecom/snapshot_archive for the full README.
  TEXT

  class << self
    def configure
      yield(Cfg.instance)
    end
  end
end

require_relative "snapshot_archive/cli"
