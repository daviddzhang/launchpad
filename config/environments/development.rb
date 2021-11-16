Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = false

  # Show full error reports.
  config.consider_all_requests_local = true

  # Enable/disable caching. By default caching is disabled.
  # Run rails dev:cache to toggle caching.
  if Rails.root.join('tmp', 'caching-dev.txt').exist?
    config.action_controller.perform_caching = true

    config.cache_store = :redis_cache_store, { expires_in: 1.day }
    config.public_file_server.headers = {
      'Cache-Control' => "public, max-age=#{2.days.to_i}"
    }
  else
    config.action_controller.perform_caching = false

    config.cache_store = :null_store
  end


  # Store uploaded files on the local file system (see config/storage.yml for options)
  config.active_storage.service = :local

  # NOTE: In development, premailer-rails intercepts the delivery_method, so setting it here does nothing.
  config.action_mailer.delivery_method = :test
  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.perform_caching = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Highlight code that triggered database queries in logs.
  config.active_record.verbose_query_logs = true

  # Debug mode disables concatenation and preprocessing of assets.
  # This option may cause significant delays in view rendering with a large
  # number of complex assets.
  config.assets.debug = false

  # Suppress logger output for asset requests.
  config.assets.quiet = true

  # Disable hash on asset files
  config.assets.digest = false

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  # Use an evented file watcher to asynchronously detect changes in source code,
  # routes, locales, etc. This feature depends on the listen gem.
  config.file_watcher = ActiveSupport::EventedFileUpdateChecker

  # Enable log rotation, keeping only two logs that cap at 10MB
  logger = ActiveSupport::Logger.new(config.paths['log'].first, 2, 10 * 1024 * 1024)
  config.logger = ActiveSupport::TaggedLogging.new(logger)

  # rack-tracker
  config.middleware.use(Rack::Tracker) do
    handler :google_analytics, tracker: ENV['GOOGLE_ANALYTICS_TRACKING_ID']
    handler :facebook_pixel, id: '601720889978592'
  end

  # Without this, Rails won't eager load the single table inheritance subclasses
  # in development mode
  # https://medium.com/@dcordz/single-table-inheritance-using-rails-5-02-6738bdd5101a
  config.eager_load_paths += Dir["app/models/sem/school/content_module/**/*.rb"]
  ActiveSupport::Reloader.to_prepare do
    Dir["app/models/sem/school/content_module/**/*.rb"].each { |f| require_dependency("#{Dir.pwd}/#{f}") }
  end
end

PursProcessor.dev_mode = true
PursProcessor.dev_mode_watch_purs = false # Rely on Purs IDE integration to recompile modules
