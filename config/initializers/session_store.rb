Launchpad::Application.config.session_store(
  :redis_store,
  servers: [ENV['REDIS_URL']],
  expire_after: 14.days,
  key: "_#{Rails.application.class.parent_name.downcase}_session",
  domain: Rails.env.test? ? nil : ENV['SESSION_COOKIE_DOMAIN']
)
