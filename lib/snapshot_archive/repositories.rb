module SnapshotArchive
  module Repositories
    class FileSystem
      SCHEMA = "0"
      attr_reader :path
      def initialize(path:)
        @path = path
      end

      def add(msg:, stores:)
        id = SecureRandom.uuid
        timestamp = Time.now
        dir = mkdir(id)

        archive_metadata = Archives::Builder.call(id: id, dir: dir, stores: stores)

        Cfg.shell.debug("Using stores: #{stores.keys.join(", ")}")

        if archive_metadata.fetch(:stores).empty?
          Cfg.shell.warn("no data to save")
        else
          metadata = {
            __schema__: SCHEMA,
            __gem_version__: SnapshotArchive::VERSION,
            id: id,
            message: msg,
            timestamp: timestamp.utc.iso8601,
            dir: dir,
            archive: archive_metadata
          }

          Cfg.shell.debug("writing metadata: #{metadata.to_json}")
          Cfg.shell.info("Saved snapshot: #{id}")
          File.write(File.join(dir, "metadata.json"), JSON.pretty_generate(metadata))
        end
      end

      def restore(id)
        metadata = JSON.parse(File.read(File.join(path, id, "metadata.json")))

        Archives::Restore.call(metadata.dig("archive"))
        Cfg.shell.info("Restored snapshot: #{id}")
      end

      def list
        snapshots = (
          Dir
            .glob(File.join(path, "**/metadata.json"))
            .map { |metadata| JSON.parse(File.read(metadata)) }
            .sort_by { |metadata| metadata.fetch("timestamp") }
            .reverse
        )

        if snapshots.count > 0
          snapshots.each do |metadata|
            Formatters::List.call(metadata)
          end
        else
          Cfg.shell.info("No snapshots in archive")
        end
      end

      def show(id)
        Formatters::Show.call(
          JSON.parse(File.read(File.join(path, id, "metadata.json")))
        )
      end

      def delete(id)
        dir = File.join(path, id)
        md_path = File.join(dir, "metadata.json")
        raise ArgumentError.new("unknown snapshot: #{id}") unless File.exist?(md_path)
        metadata = JSON.parse(File.read(md_path))

        Cfg.shell.info("Running delete hooks: #{id}")
        Archives::Delete.call(metadata.dig("archive"))

        Cfg.shell.info("Removing snapshot: #{id}")
        FileUtils.rm_rf(dir)
        Cfg.shell.info("Removed snapshot: #{id}")
      end

      private

      def timestamp
        @timestamp ||= Time.now
      end

      def mkdir(id)
        dir = File.join(path, id)
        FileUtils.mkdir_p(dir)
        dir
      end
    end
  end
end
