source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.6'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.4.5'

# Rails/Rack extensions
gem 'activeresource', '5.1.1'
gem 'hashid-rails', '~> 1.0' # obfuscate incremental IDs in URLs
gem 'kaminari', '1.2.1'
gem 'rack-cors', '1.1.0'
gem 'rails_autoscale_agent', '>= 0.9.1'

# Rails has a dependency on 0.3.4, which was yanked due to confusing legal stuff
# (see https://github.com/rails/rails/issues/41750), but 0.3.7 is still up and
# is MIT-licensed.
gem 'mimemagic', '0.3.7'

# We picked `rinku` over `linkify-it-rb` despite smaller feature set.
# `linkify-it-rb` supports linking implicit URLs, e.g. example.com (without
# protocol). However, it has <15k downloads vs 10.5M+ for `rinku`. We correlate
# higher usage with smaller security risk, despite its use of C:
gem 'rinku', '2.0.6' # autolinking text

gem 'sendgrid-actionmailer', '2.6.0'
gem 'sendgrid-ruby', '6.2.1'
gem 'validate_url', '1.0.13'

# Storage
gem 'pg', '1.2.3'
gem 'redis-rails', '5.0.2'
gem 'connection_pool', '2.2.3'
gem 'activerecord5-redshift-adapter', '1.0.1'
gem 'activerecord-import', '1.0.3'
# Use Puma as the app server
gem 'puma', '4.3.8'
# View rendering stuff
gem 'sass-rails', '6.0.0' # wraps sassc-rails
gem 'haml-rails', '2.0.1'
gem 'uglifier', '4.2.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', ' 2.9.1'

# General tooling
gem 'bootsnap', ' 1.4.4', require: false
gem 'dotenv-rails', '>= 2.7.6', groups: [:development, :test]
# When run on Windows, Ruby said:
# Please add the following to your Gemfile to avoid polling for changes:
gem 'wdm', '>= 0.1.0', platforms: [:mingw, :mswin, :x64_mingw]

# Inlines CSS for emails
# Custom fork enables dropping CSS for unused styles:
gem 'premailer', git: 'https://github.com/collegevine/premailer.git', ref: 'c1db3fb6f2decf81d7cb35f78351d005a4ba2dc7'
# https://github.com/fphilipe/premailer-rails
gem 'premailer-rails'

###########################
#
# Image Processing
#
###########################

# Responsive Images via Imagix
gem 'imgix-rails'

# OCR
gem 'rtesseract', '3.0.4'

# General manipulation
gem 'mini_magick', '4.10.1'

###########################

group :development, :test, :staging do
  gem 'factory_bot_rails', '5.1.1'
  gem 'faker', '2.10.1'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '11.0.1', platforms: [:mri, :mingw, :x64_mingw]
  gem 'rails-controller-testing', '1.0.5'
  gem 'rspec-rails', '3.8.2'
  gem 'rspec_junit_formatter', '0.4.1'
  gem 'rubocop-rspec', '1.33.0'
  gem 'brakeman', '5.0.1'
  gem 'capybara', '3.25'
  gem 'geckodriver-helper', git: 'https://github.com/collegevine/geckodriver-helper.git'
  gem 'selenium-webdriver', '3.142.7'
  gem 'rspec-parameterized', '~> 0.4.2'
  gem 'parallel_tests', '2.29.2'
  gem 'simplecov', '0.17.0', require: false
  gem 'timecop', '0.9.1'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '3.7.0'
  gem 'pry-rails', '0.3.9'
  gem 'listen', '3.1.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '2.1.0'
  gem 'spring-watcher-listen', '2.0.1'
  gem 'rubocop-rails', '2.1.0'
  gem 'derailed_benchmarks', '1.4.1'
  gem 'annotate', git: 'https://github.com/ctran/annotate_models.git', ref: '8666d8934748466446cf8a630536f9ea1196cf92'
  gem 'pusher-fake', '2.0.0'
end

#####################
###  Profiling
#####################
gem 'rack-mini-profiler', '1.1.4'

# For memory profiling
gem 'memory_profiler', '0.9.14'

# For call-stack profiling flamegraphs
gem 'flamegraph', '0.9.5'
gem 'stackprof', '0.2.14'

#####################



# Rack tracker, for tracking services like GA and Hotjar
gem 'rack-tracker', '1.11.1'
gem 'launchdarkly-server-sdk', '5.5.7'
gem 'hubspot-ruby', '0.8.1'
gem 'meta-tags', '2.13.0'
gem 'sitemap_generator', '6.1.0'

# Auth stuff
gem 'devise', '4.7.1'
gem 'omniauth-auth0', '2.2.0'
gem 'omniauth-rails_csrf_protection', '0.1.2'

gem 'cancancan'

# Utilities
gem 'validates_zipcode', '0.3.3'
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
gem 'browser', '3.0.3'
gem 'geocoder', '1.6.3'
gem 'indefinite_article', '0.2.4'
gem 'damerau-levenshtein', '~> 1.3', '>= 1.3.2'

# Rails Admin
gem 'rails_admin'
gem 'paper_trail'

# Auth0, to query user information
gem 'auth0', '4.8.0'

gem 'aws-sdk-cloudfront', '1.29'
gem 'aws-sdk-mediaconvert', '1.50'
gem 'aws-sdk-medialive', '1.46'
gem 'aws-sdk-mediapackage', '1.28'
gem 'aws-sdk-s3', '1.67.1'

# ActiveJob backend
gem 'delayed_job_active_record', '4.1.4'
gem 'delayed_job', '4.1.8'
gem 'resque', '2.0.0'
gem 'resque-scheduler', '4.4.0'
gem 'resque-lifecycle', '0.1.2'
gem 'resque-retry'

gem 'sys-proctable', '1.2.2', platforms: [:mingw, :mswin, :x64_mingw]

gem "wicked", "~> 1.3"

# Simple http request gem, used for slack messages
gem 'rest-client', '~> 2.1.0'

gem "possessive", "~> 1.0"

gem "deep_cloneable", "~> 3.0"

gem "local_time", "2.1.0"

gem 'rails_autolink'

gem 'discard', '1.1.0'

gem 'pg_search', '2.3.5'

gem 'airrecord', '1.0.1'

# Error Management/ Debugging
#
# NOTE: please keep airbrake at the end of this file.
# the order gems are defined in a Gemfile is the order in which Rails
# requires them. And, of course, there are dependencies between some of these
# gems.
#
# Airbrake for example, will automatically log errors in delayed_job, but only
# if its loaded after `delayed_job`. Placing it at the end of the file ensures
# this happens.

# Scout - App monitoring
gem 'scout_apm', '2.6.8'

gem 'airbrake', '11.0.3'
gem 'health_check', '3.0.0'

# Pusher - provides realtime messaging functionality via pub/sub
gem 'pusher', '1.3.3'

# m3u8 - allows us to generate HLS manifests for livestream recordings, so users
# can watch them.
gem 'm3u8', '0.8.2'

# Bulk insert - insert multiple records in a single query via ActiveRecord
gem 'bulk_insert', '1.8.1'

# Charting
gem 'chartkick', '3.4.0'

gem 'email_reply_parser', '0.5.10'

gem 'rack-brotli', '1.0.0'

# Allows including svg via asset pipeline
gem 'inline_svg', '1.7.2'

gem 'calendly', '0.8.0'

gem 'stripe', '5.38.0'

gem 'google_drive', '3.0.7'

# Provides support for creating docx files
gem 'caracal', '1.4.1'

# Easier import of CSV in migrations
gem 'smarter_csv', '1.2.8'

# Addresses bug with installation on macOS 11+
gem 'thin', '1.8.1'
