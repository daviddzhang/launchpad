require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
require "sprockets/railtie"
require_relative '../lib/purs_processor'
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Launchpad
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    config.before_initialize do
      # check if file exists
      dotenv_fallback_file = Rails.root.join('.env')
      if File.exist?(dotenv_fallback_file)
        raise(<<~MESSAGE
          \n
          ERROR: Cannot start up with '.env' file present.

          Please remove '#{dotenv_fallback_file}' file.
          Its presence can be dangerous due to potential access to production database.

          For more details, see:

          - https://www.notion.so/collegevine/2021-11-01-Production-database-clobbering-9bb80c154bc44c749c945aa432337ddc
          - https://collegevine.atlassian.net/browse/APP-8976

        MESSAGE
             )
      end
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    config.autoload_paths += %W[#{config.root}/lib]

    # Don't generate system test files.
    config.generators.system_tests = nil

    config.redis = Redis.new url: ENV['REDIS_URL']

    base_url = URI(ENV['BASE_URL'] || "http://localhost:3000")
    # Known side-effect: this will cause directives of the form `redirect_to
    # action: :my_action` in a controller to start failing tests since it is
    # implying `url_for`. As a result, we remove these settings in the test
    # environment.
    config.action_controller.default_url_options = {
      host: base_url.host,
      port: base_url.port,
      protocol: base_url.scheme
    }
    # Allow the usage of _url helpers by including `Rails.application.routes.url_helpers` in controllers
    self.default_url_options = config.action_controller.default_url_options
  end
end
