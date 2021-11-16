require 'English'
require 'find'
require 'fileutils'
require './lib/node_server'

class PursProcessor
  VERSION = "0.0.2".freeze
  MIME_TYPE = 'text/purescript'.freeze

  class Railtie < ::Rails::Railtie
    initializer :purescript_support do |_|
      Sprockets.tap do |s|
        s.register_mime_type MIME_TYPE, extensions: ['.purs'] unless s.mime_exts['.purs']
        s.register_preprocessor MIME_TYPE, PursProcessor unless s.processors[MIME_TYPE]&.include? PursProcessor
      end

      puts "PursProcessor initialized"
      PursProcessor.ensure_environment force_log: true, only_when_clean: true
    end

    at_exit { PursProcessor.cleanup }
  end

  @purs_root = "app/assets/purs" # Default location, can be configured
  @src_dir = "src"
  @temp_dir = ".temp"
  @dont_watch_dirs = ["node_modules", ".spago", "output", ".cache", @temp_dir]
  @spago_watcher = nil # Stores PID of the Spago watch process
  @mutex = Mutex.new

  # In production we first run `spago bundle-module` for the module in question
  # and then `esbuild bundle` to build the outputs. Then we gather all the
  # source files together and report them back to Rails as "dependencies".
  #
  # In development we run esbuild every time Sprockets asks us to rebuild.
  # Running esbuild is super cheap, so it's ok to do it every time something
  # changes. For Spago, we run a watch process (if enabled; see
  # `development_spago_watch` and `@dev_mode_watch_purs`) to build/watch the
  # whole PureScript project, and then its output would be used as esbuild
  # input.
  @dev_mode = false

  # This is a special QOL setting that is "on" by default. It prevents us
  # from running a Spago watch process. Unfortunately, Spago doesn't have
  # very good support for watching *.purs files: it simply runs the compiler
  # on every change, and this takes forever. So instead we rely on the
  # developer's IDE support to rebuild the individual modules for us. This
  # may sometimes yield incorrect results (i.e. when a module has changed
  # its API and was rebuild, but its consumers weren't), but this is a
  # normal situation, even in JS world. It just means the developer has to
  # rebuild manually - either through IDE support or by running `spago build`.
  @dev_mode_watch_purs = true

  class << self
    attr_accessor :temp_dir, :src_dir, :dev_mode, :dev_mode_watch_purs
    attr_reader :dont_watch_dirs
  end

  # Loads the given module and runs the given JS snippet, which is expected to
  # be a function taking one parameter, which is itself a function that loads
  # the module.
  #
  # Example:
  #
  #      -- PureScript:
  #      module Foo.Bar(helloWorld) where
  #
  #      helloWorld :: String
  #      helloWorld = "Hello, world!"
  #
  #
  #      # Ruby:
  #      result = PursProcessor.server_side_eval(
  #         "src/Foo/Bar",
  #         "loadModule => loadModule().helloWorld"
  #      )
  #      expect(result).to eq "Hello, world!"
  #
  def self.server_side_eval(module_path, js_function_code, timeout: 10.seconds) # rubocop:disable Metrics/MethodLength
    module_name = file_path_to_module_name module_path
    built_module_path = File.expand_path module_targets(module_name)[:node], absolute_purs_root

    unless File.exist? built_module_path
      raise(
        "Output for module #{module_name} is absent (expected to be found at #{built_module_path}). " \
        "You have to trigger asset compilation (e.g. by using `purescript_include_tag` " \
        "or `frontend_component`) before calling `server_side_eval`"
      )
    end

    Dir.mkdir absolute_temp_dir unless Dir.exist? absolute_temp_dir # Tempfile.new crashes if the dir doesn't exist
    output_file = Tempfile.new ["purs_server_side_eval", ".output"], absolute_temp_dir
    begin
      code = "(() => {
        try {
          const loadModule = () => require('#{built_module_path}')
          const output = (#{js_function_code})(loadModule)
          require('fs').writeFileSync('#{output_file.path}', output)
          return 'OK'
        } catch(e) {
          return e.stack || e
        }
      })()"

      log "Executing server-side code in Node with #{module_name}"
      start_time = Time.zone.now
      response = node_server.evaluate(
        code,
        key: built_module_path,
        key_timestamp: File.stat(built_module_path).mtime,
        timeout: timeout
      )
      log "Completed in #{(Time.zone.now - start_time) / 1.second * 1000.0}ms"

      return File.read output_file if response.strip == 'OK'

      raise "Failed to execute server-side code in Node with #{module_name}: #{response}"
    ensure
      output_file.unlink
    end
  end

  # Given a module path, returns timestamp of the last compiled and bundled code
  # of that module. If the module hasn't been compiled yet, returns `nil`. This
  # is used as part of cache key when caching server-side-render output.
  def self.server_side_module_timestamp(module_path)
    module_name = file_path_to_module_name module_path
    built_module_path = File.expand_path module_targets(module_name)[:node], absolute_purs_root

    return nil unless File.exist? built_module_path

    File.stat(built_module_path).mtime
  end

  # Ensures a given module has been built. In some situations - specifically,
  # outside of a web request context, such as in tests or jobs, - we cannot use
  # Sprocket's internal machinery for this, because outside of a web request
  # Sprockets doesn't care for some reason and will not kick off asset
  # recompilation. This is only relevant in development because in production
  # all assets are precompiled anyway.
  def self.ensure_module_built(module_path)
    development_esbuild_bundle file_path_to_module_name(module_path) if dev_mode
  end

  # Entry point called by Sprockets when an assets needs compiling
  def self.call(input)
    ensure_correct_root(input[:load_path])
    env = input[:environment]
    ensure_environment

    mod = file_path_to_module_name input[:name]
    log "Building module #{mod}"

    result, dep_files =
      if dev_mode
        development_build env, mod
      else
        production_build env, mod
      end

    ctx = env.context_class.new(input)
    ctx.metadata.merge(data: result, dependencies: dep_files)
  end

  # See comments on `@dev_mode`
  def self.production_build(env, module_name)
    bundle = "#{absolute_temp_dir}/bundles/#{module_name}.js"

    sh "npx", "spago", "bundle-module", "--main", module_name, "--to", bundle, "--no-psa"
    targets = esbuild_bundle module_name, entry_point: bundle, production: true

    result = File.read targets[:browser]

    # In production we declare _all_ files under the root as dependencies, to
    # make sure that Sprockets will recompile assets if any PURS or JS or
    # whatever else files change.
    skip_deps = dont_watch_dirs.map { |d| File.expand_path d, absolute_purs_root }
    deps = Find.find(absolute_purs_root).map do |f|
      next Find.prune if skip_deps.include?(f)
      next nil if File.directory? f

      env.build_file_digest_uri(f)
    end

    [result, deps.compact]
  end

  # See comments on `@dev_mode`
  def self.development_build(env, module_name)
    development_spago_watch
    targets = development_esbuild_bundle module_name

    result = File.read targets[:browser]

    # In development we gather actual dependencies, as seen and reported by
    # esbuild, and report them as dependencies. This is because in development
    # we also have the IDE rebuilding the files, so we want to make sure the
    # outputs are watched.
    deps =
      targets
      .flat_map do |(_, out_path)|
        json = JSON.parse File.read("#{out_path}.dependencies")
        inputs = json.dig("outputs")&.first&.second&.dig("inputs")&.keys
        raise "Unexpected JSON format of esbuild metafile in #{out_path}.dependencies" unless inputs

        inputs
      end # rubocop:disable Style/MultilineBlockChain
      .uniq
      .map { |f| env.build_file_digest_uri File.expand_path(f.strip, absolute_purs_root) }


    [result, deps]
  end

  # Launches a Spago watch process for building/watching the whole PureScript
  # project. See comments on `@dev_mode` and `@dev_mode_watch_purs`.
  def self.development_spago_watch # rubocop:disable Metrics/MethodLength
    return if @spago_watcher

    @mutex.synchronize do
      next if @spago_watcher

      # See comments on `@dev_mode_watch_purs`
      unless dev_mode_watch_purs
        # Even though we're not starting a watcher, we still need to run the build
        # once in order to support the "clone and start" scenario
        sh "npx", "spago", "build", "--no-psa"

        log ""
        log "-----------------------------------------------------------"
        log "\033[91mNOTE: NOT WATCHING PURESCRIPT SOURCE CODE\033[39m"
        log "Make sure your IDE integration is recompiling the modules"
        log "-----------------------------------------------------------"
        log ""

        @spago_watcher = :not_used
        return
      end

      flag_file = "#{absolute_temp_dir}/.spagodone"
      FileUtils.rm_f flag_file
      pid = spawn(
        "npx", "spago", "build", "--watch",
        "--then", "echo . > #{flag_file}",
        "--else", "echo . > #{flag_file}",
        "--no-psa",
        chdir: absolute_purs_root
      )

      log "Started Spago Watch PID = #{pid}, waiting for it to finish..."
      if wait_file_or_process flag_file, pid
        log(
          "Spago is done building. If it failed, that's all right, "\
          "it will continue watching the code and rebuilding."
        )
      else
        Process.kill("HUP", pid)
        raise "Spago Watch stopped for some reason 🤷‍♀️"
      end

      @spago_watcher = pid
    end
  end

  def self.development_esbuild_bundle(module_name)
    entry_point_file = "output/#{module_name}/index.js"
    unless File.exist? File.expand_path(entry_point_file, absolute_purs_root)
      raise "Cannot build module #{module_name} because #{entry_point_file} does not exist"
    end

    esbuild_bundle module_name, entry_point: entry_point_file, production: false
  end

  def self.esbuild_bundle(module_name, entry_point:, production:)
    targets = module_targets(module_name)
    deps_file = ->(out_path) { "#{out_path}.dependencies" }

    targets.each do |(target, out_path)|
      sh(
        "npx", "esbuild",
        entry_point,
        "--bundle",
        "--outfile=#{out_path}",
        "--global-name=Purs_#{module_name.gsub('.', '_')}",
        "--platform=#{target}",
        "--define:process.env.NODE_ENV=\"#{production ? 'production' : 'development'}\"",
        "--loader:.css=text",
        "--metafile=#{deps_file.call(out_path)}",
        ("--minify" if production),
        "--target=node10"
        # ^ --target=node10 is essential to prevent esbuild from generating JS
        # syntax that isn't understood by this version of Node. This probably
        # should be a config parameter of PursProcessor.
      )
    end

    targets
  end

  # Spin-wait for a given file to appear on the file system OR the given process
  # to exit, whichever happens first. This is used for monitoring completion of
  # the build/watch processes (i.e. Spago).
  def self.wait_file_or_process(file, pid)
    sleep 1 until (file_exists = File.exist? file) || Process.waitpid(pid, Process::WNOHANG)

    file_exists
  end

  def self.module_targets(module_name)
    {
      browser: "#{absolute_temp_dir}/.out/#{module_name}.js",
      node: "#{node_output_root}/#{module_name}.js"
    }
  end

  def self.file_path_to_module_name(file_path)
    src_dir_canonical = src_dir.delete_suffix("/") + "/"
    unless file_path.starts_with? src_dir_canonical
      raise PursCompileError, "PureScript file #{file_path} was expected to be under #{src_dir_canonical}"
    end

    file_path[src_dir_canonical.length, file_path.length].gsub('/', '.')
  end

  def self.ensure_correct_root(root)
    return if absolute_purs_root == root

    raise("
      Attempt to load a PureScript module from a root directory other than the configured one.
      The configured directory is '#{absolute_purs_root}'
      The attempted directory is '#{root}'
      To configure the root directory add `PursProcessor.purs_root = 'app/assets/whatever'` to your initializers.
    ")
  end

  def self.absolute_purs_root
    @absolute_purs_root ||= File.expand_path(@purs_root, Rails.root)
  end

  def self.absolute_temp_dir
    @absolute_temp_dir ||= File.expand_path(temp_dir, absolute_purs_root)
  end

  def self.node_output_root
    # We keep these files under `public/assets` in order to ensure that they are
    # kept during whatever caching/rebuilding operations the hosting provider
    # (e.g. Heroku) may perform. We know that the `public/assets` folder is
    # definitely kept, because that's where Rails itself stores precompiled
    # assets, so we just piggy-back on that.
    File.expand_path("public/assets/purs_ssr", Rails.root)
  end

  def self.cache_key
    "#{self.class.name}::#{VERSION}"
  end

  def self.ensure_environment(force_log: false, only_when_clean: false)
    node_modules_exists = Dir.exist? "#{absolute_purs_root}/node_modules"

    # Skip the initialization if node_modules is already there, AND the
    # only_when_clean flag is set. It turns out that `npm install` is kinda slow
    # on Heroku for some reason (i.e. can take up to 20-30 seconds sometimes),
    # AND Heroku loads the Rails environment multiple times during a deploy,
    # which means the overhead can add up to minutes of wasted time. So we try
    # to work around that by not running it every single time a Rails
    # environment is loaded.
    if node_modules_exists && only_when_clean
      log "Skipping environment initialization, because node_modules exists in #{absolute_purs_root}", force: true
      return
    end

    @mutex.synchronize do
      return if @environment_initialized

      log "Initializing PureScript environment in #{absolute_purs_root}", force: force_log
      log "node_modules was missing in #{absolute_purs_root}", force: force_log unless node_modules_exists

      FileUtils.mkdir_p "#{absolute_temp_dir}/.out"
      sh "npm", "install", "--silent", "--no-progress", "--no-audit"

      @environment_initialized = true
    end
  end

  def self.node_server
    @node_server ||= NodeServer.new(cwd: absolute_purs_root, tmp_dir: absolute_temp_dir, log: ->(s) { log s })
  end

  def self.cleanup
    log "Cleaning up..."
    Process.kill("HUP", @spago_watcher) if @spago_watcher.is_a?(Integer)
    @node_server&.cleanup
    log "Closed"
  end

  def self.log(msg, force: false)
    text = "\033[35m[purs]\033[39m #{msg}"
    force ? puts(text) : Rails.logger&.info(text) # rubocop:disable Rails/Output
  end

  def self.sh(*cmd)
    log "Running: #{cmd}"
    start_time = Time.zone.now

    _, stderr, status = Open3.capture3(*cmd.compact, chdir: absolute_purs_root)
    unless status.success?
      raise PursCompileError, "PureScript support: '#{cmd.join(' ')}' returned code #{$CHILD_STATUS}.\n#{stderr}"
    end

    log "Completed in #{(Time.zone.now - start_time) * 1000.0}ms : #{cmd}"
  end
end

class PursCompileError < StandardError
end
