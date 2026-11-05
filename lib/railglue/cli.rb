# frozen_string_literal: true

module Railglue
  # Command-line entry point: bin/railglue [--config FILE] COMMAND [ARGS].
  class CLI
    USAGE = <<~TEXT
      Usage: bin/railglue [--config FILE] COMMAND [ARGS]

      Commands:
        generate          Write the compose and nginx files from the config
        rspec APP [ARGS]  Run an app's rspec suite inside its container
        urls              Print the URL of each app
        help              Show this message
        anything else     Regenerate, then pass to docker compose
                          (e.g. up -d --build, logs -f, ps, down)

      FILE defaults to $RAILGLUE_CONFIG, then railglue.yml.
    TEXT

    COMMANDS = {
      'generate' => :generate,
      'rspec' => :rspec,
      'urls' => :urls,
      'help' => :help
    }.freeze

    def initialize(out: $stdout, err: $stderr,
                   runner: Kernel.method(:system),
                   output_root: DEFAULT_OUTPUT_ROOT)
      @out = out
      @err = err
      @runner = runner
      @output_root = output_root
    end

    def run(argv)
      config_path, args = split_config_option(argv)
      command = args.shift || 'help'
      return help if command == 'help'

      @config = ConfigLoader.load(config_path, output_root: @output_root)
      dispatch(command, args)
    rescue ConfigError => e
      @err.puts("railglue: #{e.message}")
      1
    end

    def split_config_option(argv)
      default = ENV.fetch('RAILGLUE_CONFIG', DEFAULT_CONFIG)
      return [default, argv.dup] unless argv.first == '--config'
      raise ConfigError, '--config needs a file' if argv.size < 2

      [File.expand_path(argv[1]), argv.drop(2)]
    end

    def dispatch(command, args)
      method_name = COMMANDS[command]
      return compose(command, *args) unless method_name

      send(method_name, *args)
    end

    def compose_argv(*args)
      ['docker', 'compose', '-f', @config.compose_path, *args]
    end

    def compose(*args)
      generate
      @runner.call(*compose_argv(*args)) ? 0 : 1
    end

    def generate
      Generator.write(@config)
      0
    end

    def rspec(app_name = nil, *args)
      unless app_name && @config.find_app(app_name)
        raise ConfigError, "rspec needs an app: #{app_names}"
      end

      compose('run', '--rm', app_name, 'railglue-rspec', *args)
    end

    def urls
      @config.apps.each { |app| @out.puts("#{app.name}\t#{@config.url(app)}") }
      0
    end

    def help
      @out.puts(USAGE)
      0
    end

    def app_names
      @config.apps.map(&:name).join(', ')
    end
  end
end
