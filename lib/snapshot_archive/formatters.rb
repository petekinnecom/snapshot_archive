module SnapshotArchive
  module Formatters
    class List
      def self.call(metadata)
        new(metadata).call
      end

      attr_reader :metadata
      def initialize(metadata)
        @metadata = metadata
      end

      def call
        id = metadata.fetch("id")
        timestamp = Time.parse(metadata.fetch("timestamp")).strftime("%F %H:%M")
        message = metadata.fetch("message")

        short_message = message.split("\n").first
        Cfg.shell.puts([id, timestamp, short_message].join(" : "))
      end
    end

    class Show
      def self.call(metadata)
        new(metadata).call
      end

      attr_reader :metadata
      def initialize(metadata)
        @metadata = metadata
      end

      def call
        id = metadata.fetch("id")
        timestamp = Time.parse(metadata.fetch("timestamp")).strftime("%F %H:%M")
        message = metadata.fetch("message")
        dir = metadata.fetch("dir")

        Cfg.shell.puts(<<~TXT)
          id: #{id}
          time: #{timestamp}
          path: #{dir}
          ----------------------
          #{message}

          Full metadata:
          #{JSON.pretty_generate(metadata.dig("archive", "stores"))}
        TXT
      end
    end
  end
end
