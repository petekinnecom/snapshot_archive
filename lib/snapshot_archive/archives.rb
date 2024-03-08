module SnapshotArchive
  module Archives
    class Builder
      def self.call(dir:, stores:)
        new(dir, stores).call
      end

      attr_reader :dir, :stores
      def initialize(dir, stores)
        @dir = dir
        @stores = stores
      end

      def call
        stores_metadata = (
          stores
            .map { |name, store|
              File
                .join(dir, name)
                .tap { FileUtils.mkdir(_1) }
                .then { store.backup(_1)&.merge(type: name) }
            }
            .compact
        )

        {
          stores: stores_metadata
        }
      end
    end

    class Restore
      def self.call(metadata)
        new(metadata).call
      end

      attr_reader :metadata
      def initialize(metadata)
        @metadata = metadata
      end

      def call
        metadata.fetch("stores").reverse.each do |store_metadata|
          store = Cfg.instance.store(store_metadata.fetch("type"))
          store.restore(store_metadata)
        end
      end
    end

    class Delete
      def self.call(metadata)
        new(metadata).call
      end

      attr_reader :metadata
      def initialize(metadata)
        @metadata = metadata
      end

      def call
        metadata.fetch("stores").each do |store_metadata|
          store = Cfg.instance.store(store_metadata.fetch("type"))
          if store.respond_to?(:delete)
            store.delete(store_metadata)
          end
        end
      end
    end


    class Presenter
      def self.call(metadata)
        new(metadata).call
      end

      attr_reader :metadata
      def initialize(metadata)
        @metadata = metadata
      end
    end
  end
end
