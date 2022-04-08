module SnapshotArchive
  class Shell
    CODES = {
      red: 31,
      green: 32,
      yellow: 33,
      pink: 35,
    }.freeze

    CommandFailureError = Class.new(StandardError)

    def initialize(verbose: false)
      @verbose = verbose
    end

    def run(cmd)
      debug(cmd)

      `#{cmd}`
        .split("\n")
        .tap { raise CommandFailureError.new(cmd) unless $? == 0 }
    end

    def warn(msg)
      print "#{colorize(msg, :red)}\n"
    end

    def notify(msg)
      print "#{colorize(msg, :yellow)}\n"
    end

    def puts(msg)
      print "#{msg}\n"
    end

    def info(msg)
      puts(msg)
    end

    def debug(msg)
      puts(msg) if @verbose
    end

    private

    # colorization
    def colorize(msg, color)
      color_code = CODES.fetch(color)

      "\e[#{color_code}m#{msg}\e[0m"
    end
  end
end
