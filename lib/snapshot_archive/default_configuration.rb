SnapshotArchive.configure do |config|
  config.register_store(
    "mysql",
    SnapshotArchive::Stores::Mysql,
    active_by_default: false
  )

  config.register_store("mysql_rails") do |store|
    store.backup do |*args, **opts|
      existing_databases = (
        config
          .shell
          .run("mysql --execute 'show databases' --silent --skip-column-names")
      )

      db_names = (
        config
          .shell
          .run("sh -c 'cd $(git rev-parse --show-toplevel) && git grep database:.*_development *database.yml || exit 0'")
          .map { |line| line.match(/database:\s+(.*_development)\s*$/) }
          .compact
          .map { |match| match[1] }
          .select { |db| existing_databases.include?(db) }
          .reject { |db| db.match(/_tmp_/)}
      )

      next if db_names.empty?

      SnapshotArchive::Cfg.bind_backup("mysql", db_names).backup(*args, **opts)
    end

    store.restore do |metadata|
      SnapshotArchive::Cfg.store("mysql").restore(metadata: metadata)
    end
  end

  config.storage_path = File.join(ENV["HOME"], ".snapshot_archive")
end
