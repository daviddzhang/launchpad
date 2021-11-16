const SEVERITY_CONSOLE_LEVEL_MAP = {
  info: "info",
  warning: "warn",
  error: "error",
}

// Severity: https://airbrake.io/docs/airbrake-faq/what-is-severity/
exports.notify = severity => message => params => a => {
  const consoleLevel = SEVERITY_CONSOLE_LEVEL_MAP[severity]

  if (typeof console !== "undefined" && console[consoleLevel]) {
    console[consoleLevel](message, params)
  }

  if (typeof window !== "undefined") {
    const error = new Error(message)

    if (typeof window.Sentry !== "undefined") {
      window.Sentry.captureException(error, { extra: params })
    }
  }

  return a()
}
