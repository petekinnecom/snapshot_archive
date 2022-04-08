require "ostruct"
require "time"
require "json"
require "securerandom"

require "snapshot_archive/stores"
require "snapshot_archive/archives"
require "snapshot_archive/formatters"

module SnapshotArchive
  class Cli
    class << self
      def backup(msg:, stores:)
        if msg.empty?
          Cfg.shell.warn("aborting due to empty message")
        else
          Cfg.repository.add(msg: msg, stores: stores)
        end
      end

      def restore(id:)
        Cfg.repository.restore(id)
      end

      def list
        Cfg.repository.list
      end

      def show(id)
        Cfg.repository.show(id)
      end

      def delete(id)
        Cfg.repository.delete(id)
      end
    end
  end
end
