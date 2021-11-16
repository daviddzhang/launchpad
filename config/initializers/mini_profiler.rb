if ENV['DISABLE_MINI_PROFILER'].blank?
  require 'rack-mini-profiler'

  # See https://github.com/MiniProfiler/rack-mini-profiler#configuration-options for
  # a description of the available settings

  c = Rack::MiniProfiler.config
  # not let rack-mini-profiler disable caching
  c.disable_caching = false
  c.enable_advanced_debugging_tools = true
  c.position = 'top-right'
  c.pre_authorize_cb = lambda { |_|
    Rails.env.development? || Rails.env.production?
  }
end
