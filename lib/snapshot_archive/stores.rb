module SnapshotArchive
  module Stores
    class BoundBackup
      attr_reader :store, :args
      def initialize(store, args)
        raise ArgumentError.new("double bound backup") if store.is_a?(BoundBackup)

        @store = store
        @args = args
      end

      def backup(**opts)
        store.backup(args: args, **opts)
      end

      def restore(...)
        store.restore(...)
      end

      def delete(...)
        store.delete(...)
      end
    end

    module Mysql
      class << self
        def backup(...)
          Backup.call(...)
        end

        def restore(...)
          Restore.call(...)
        end
      end

      class Backup
        def self.call(...)
          new(...).call
        end

        attr_reader :dir, :names, :id
        def initialize(dir:, id:, args:, **)
          @dir = dir
          @id = id
          @names = args
        end

        def call
          Cfg.shell.debug("backing up #{names} into #{dir}")

          path = File.join(dir, "mysql.sql.gz")

          Cfg.shell.run(<<~SH)
            mysqldump \
              --add-drop-database \
              --databases #{names.join(" ")} \
              | gzip > #{path}
          SH

          {
            type: "mysql",
            path: path,
            databases: names
          }
        end
      end

      class Restore
        def self.call(...)
          new(...).call
        end

        attr_reader :metadata
        def initialize(metadata:)
          @metadata = metadata
        end

        def call
          dump_path = metadata.dig("path")
          Cfg.shell.debug("restoring #{metadata.to_json}")
          Cfg.shell.run("bash -ec 'zcat < #{dump_path} | mysql -uroot'")
        end
      end
    end
  end
end
