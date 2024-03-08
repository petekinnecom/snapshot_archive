require "snapshot_archive/shell"
require "snapshot_archive/repositories"

module SnapshotArchive
  class StoreBuilder
    class CustomStore
      def initialize(backup:, restore:, delete:)
        @backup = backup
        @restore = restore
        @delete = delete
      end

      def backup(dir)
        @backup&.call(dir)
      end

      def restore(metadata)
        @restore&.call(metadata)
      end

      def delete(metadata)
        @delete&.call(metadata)
      end
    end

    def backup(&block)
      @backup = block
    end

    def restore(&block)
      @restore = block
    end

    def delete(&block)
      @delete = block
    end

    def to_store
      CustomStore.new(backup: @backup, restore: @restore, delete: @delete)
    end
  end

  class Cfg
    class << self
      def instance
        @instance ||= Cfg.new
      end

      [
        :bind_backup,
        :load,
        :resolve_alias,
        :parse_store,
        :pwd,
        :repository,
        :shell,
        :store,
        :stores,
      ].each do |meth|
        define_method(meth) do |*args|
          instance.public_send(meth, *args)
        end
      end
    end

    attr_accessor :pwd, :storage_path, :active_stores, :shell
    def initialize
      self.active_stores = []
    end

    def load(path = ".config/snapshot_archive.rb")
      config_path = File.join(ENV["HOME"], path)

      require("snapshot_archive/default_configuration")
      Kernel.load(config_path) if File.exist?(config_path)
    end

    def resolve_alias(name)
      if store_registry[name].is_a?(Array)
        store_registry[name]
      else
        name
      end
    end

    def register_store(name, klass_or_alias=nil, active_by_default: true, &block)
      store = (
        if klass_or_alias.is_a?(String)
          parse_store(klass_or_alias)[1]
        elsif klass_or_alias
          klass_or_alias
        else
          builder = StoreBuilder.new
          yield(builder)
          builder.to_store
        end
      )

      store_registry[name] = store
      if active_by_default
        active_stores << name
      end
    end

    def repository
      Repositories::FileSystem.new(path: storage_path)
    end

    def parse_store(str)
      name, *store_args = str.split(/[:,]/)

      store = (
        if store_args.count > 0
          bind_backup(name, store_args)
        else
          store_registry.fetch(name)
        end
      )

      [name, store]
    rescue KeyError
      raise "Store not found: '#{str}'"
    end

    def bind_backup(name, args)
      SnapshotArchive::Stores::BoundBackup.new(store_registry.fetch(name), args)
    end

    def store(name)
      store_registry.fetch(name)
    end

    def stores
      unknown_keys = active_stores - store_registry.keys

      if !unknown_keys.empty?
        raise ArgumentError.new("invalid store(s): #{unknown_keys.join(",")}")
      end

      store_registry.slice(*active_stores)
    end

    def shell
      @shell ||= Shell.new
    end

    private

    def store_registry
      @store_registry ||= {}
    end
  end
end
