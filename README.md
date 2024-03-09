# SnapshotArchive

Save and restore snapshots of stateful services to a central archive. Have a
development database that you want to restore to a prior state? Just take a
snapshot and restore it later! Build your own snapshotting behavior in a
configuration file so that you can snapshot any stateful service you use during
development.

By default will make mysql backups for any development databases for the rails
app in your CWD.

## Installation

```
gem install snapshot_archive
```

## Example

Snapshot and restore mysql databases named `db_1` and `db_2`:

```bash
$ snap backup mysql:db_1,db_2 -m "snapshot description"
#=> Saved snapshot: a4758dbe-6f26-4365-9d3a-6962a96557b5

$ snap show a4758dbe-6f26-4365-9d3a-6962a96557b5
#=> id: a4758dbe-6f26-4365-9d3a-6962a96557b5
#=> time: 2022-04-15 22:30
#=> ----------------------
#=> snapshot description

$ snap restore a4758dbe-6f26-4365-9d3a-6962a96557b5
#=> Restored snapshot: a4758dbe-6f26-4365-9d3a-6962a96557b5
```

## Backup

Save a snapshot that can be restored later.

By default, will use the active stores that have been configured. The
stores used for the snapshot can be overridden by passing them as args
to the command. Each store can also be passed arguments for
snapshotting from the CLI. Examples below:

See the "Configure" section for how add a custom store.

```bash
# Uses your EDITOR to add details for the snapshot.
# Uses the default configured "stores" for creating the snapshot
snap backup

# Add a message from the command line:
snap backup --message "Add message from command line"
snap backup -m "Add message from command line"

# Override which stores are used for the snapshot
snap backup store_1 store_2

# Pass arguments to a store
snap backup mysql:db_1,db_2
```
## Show

```bash
# Show the full details for a given snapshot
snap show {id}
```

## Restore

```bash
# Restore the given snapshot
snap restore {id}
```

## List

```bash
# list all snapshots (pipe to `less` if you like)
snap list
```

## Delete

```bash
# Delete the given snapshot
snap rm {id}
```

## Configure

A custom configuration can be written at the location `$HOME/.config/snapshot_archive.rb`. It is written in ruby. Here is an example config:

```ruby

SnapshotArchive.configure do |config|

  # Configure where the snapshots are stored. Defaults to `$HOME/.snapshot_archive`
  config.storage_path = "/path/to/snapshot_dir"

  # Configure which stores are active by default (can be overridden with --store
  # option on command line). The default store is "mysql_rails" which saves a
  # snapshot of all databases for the Rails app found in the CWD.
  config.active_stores = ["store_1", "store_2"]

  # Creating a custom store:
  #
  # Stores must implement two methods:
  #
  #   backup: accepts a directory for data and returns a JSON hash (with string
  #     keys) for use in restoring.
  #
  #  restore: accepts the metadata JSON data created when making the backup. No
  #    return value.
  #
  # Stores can optionally define:
  #
  #  delete: accepts the metadata JSON data created when making the backup. No
  #    return value. Invoked when the snapshot is deleted. If your backup method
  #    stores all of its data inside the snapshot directory, then no delete
  #    method is needed because the snapshot directory will be deleted. However,
  #    if your backup stores data in a different directory, then this hook can
  #    be used to cleanup that data. Eg, your method might write some data to
  #    an external or synced directory. In that case, you probably want to save
  #    the path to the file in the metadata, and try to delete it in this hook.
  #
  # Stores can either be defined as objects/classes/modules or a builtin store
  # builder can be used.

  # Using an object:

  class MyCustomStore
    def backup(dir:, id:, name:, args: [])
      path = File.join(dir, "my_custom_store.txt")
      File.write(path, "received args: #{args}")

      { "path" => path }
    end

    def restore(metadata:)
      puts(File.read(metadata.fetch("path")))
    end
  end

  config.register_store("my_custom_store", MyCustomStore.new)


  # Using the store builder:

  config.register_store("my_custom_store") do |store|
    store.backup do |dir:, id:, name:, args: []|
      path = File.join(dir, "my_custom_store.txt")
      File.write(path, "received args: #{args}")

      { "path" => path }
    end

    store.restore do |metadata:|
      puts(File.read(metadata.fetch("path")))
    end
  end

  # Making an alias for a store with arguments. This makes the following
  # invocations the same:
  #   snap backup my_backup
  #   snap backup mysql:db_1,db_2

  config.register_store("my_backup", "mysql:db_1,db_2")

  # You can also alias an array of stores:
  config.register_store("my_backup_2", ["mysql:db_1,db_2", "other_stuff"])
end
```
