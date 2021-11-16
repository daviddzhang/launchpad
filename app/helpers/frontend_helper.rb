# Rubocop doesn't like the `.html_safe` call
# rubocop:disable Rails/OutputSafety, Rails/HelperInstanceVariable
module FrontendHelper # rubocop:disable Metrics/ModuleLength
  def include_react
    return if @view_helper_react_included

    @view_helper_react_included = true
    content_for :page_scripts do
      infix = Rails.env.production? ? "production.min" : "development"
      concat javascript_include_tag "/assets/react@16.11.0/umd/react.#{infix}.js"
      concat javascript_include_tag "/assets/react-dom@16.11.0/umd/react-dom.#{infix}.js"
    end
  end

  def purescript_include_tag(purs_file)
    javascript_include_tag(purs_file, extname: false)
  end

  def frontend_component( # rubocop:disable Metrics/ParameterLists
    name,
    props: {},
    html_class: "",
    server_side_render: false,
    server_side_render_only: false,
    server_side_render_cache: nil
  )
    include_react
    unique_id = SecureRandom.uuid.to_s[0..7]

    if server_side_render_only
      # The return value of this call is dropped on purpose. When
      # server_side_render_only is specified, we don't want to include the JS
      # bundle in the page, but we still need to call this method in order to
      # trigger PureScript compilation (if required), so that SSR can use the
      # resulting JS bundle.
      purescript_include_tag("src/EntryPoints/#{name}.purs")
    else
      content_for :page_scripts do
        @view_helper_frontend_included ||= {}
        concat purescript_include_tag("src/EntryPoints/#{name}.purs") unless @view_helper_frontend_included[name]
        @view_helper_frontend_included[name] = true
      end
    end

    client_script, container_contents =
      if server_side_render || server_side_render_only
        [
          __frontend_client_script_hydrate(name, unique_id, props),
          __frontend_server_side_render(name, props, cache: server_side_render_cache)
        ]
      else
        [
          __frontend_client_script_mount(name, unique_id, props),
          ''
        ]
      end

    unless server_side_render_only
      content_for :page_scripts do
        concat(content_tag(:script, "(function() { #{client_script} })()".html_safe))
      end
    end

    content_tag :div, container_contents.html_safe, id: unique_id, class: html_class
  end

  def __frontend_client_script_mount(module_name, container_id, props)
    # The module is expected to export a value called `boot`, which is either a
    # function or a "boot record" - i.e. a hash with a function field `mount`
    "
    var boot = Purs_EntryPoints_#{module_name.gsub('/', '_')}.boot
    var mount = boot && (boot.mount || boot)
    if (typeof mount === 'function') {
      mount('#{container_id}')(#{props.to_json})()
    }
    else {
      throw new Error('Expected module #{module_name} to export a value `boot` ' +
        'which is either a function or has a function field `mount`, but got `' + boot + '`')
    }
    "
  end

  def __frontend_client_script_hydrate(module_name, container_id, props)
    # The module is expected to export a value called `boot`, which is a
    # "boot record" - i.e. a hash with a function field `hydrate`
    "
    var boot = Purs_EntryPoints_#{module_name.gsub('/', '_')}.boot
    if (boot && typeof boot.hydrate === 'function') {
      boot.hydrate('#{container_id}')(#{props.to_json})()
    }
    else {
      #{__frontend_expected_boot_record_error(module_name)}
    }
    "
  end

  def __frontend_server_side_render(module_name, props, cache: nil)
    module_path = "src/EntryPoints/#{module_name}"

    render = lambda do |_|
      # The module is expected to export a value called `boot`, which is a "boot
      # record" - i.e. a hash with function fields `renderToString` and
      # `hydrate`.
      js_code =
        "function serverSideRender(loadModule) {
          global.CV = {
            apiEndpoints: #{(@client_api_endpoints || {}).to_json},
            pathInfo: name => ({ path: global.CV.apiEndpoints[name] || '', token: '#{form_authenticity_token}' }),
            apiEndpoint: ({ name, continuation }) => continuation(global.CV.pathInfo(name)),
            assetsRoot: '#{asset_path('/img/cv-logo.svg').sub('/img/cv-logo.svg', '/')}'
          };

          const boot = loadModule().boot
          if (boot && typeof boot.renderToString === 'function' && typeof boot.hydrate === 'function') {
            return boot.renderToString(#{props.to_json})
          }
          else {
            #{__frontend_expected_boot_record_error(module_name)}
          }
        }"

      PursProcessor.server_side_eval(module_path, js_code)
    end

    if cache
      module_timestamp = PursProcessor.server_side_module_timestamp module_path
      key = "#{cache[:key]}/#{module_path}:#{module_timestamp&.to_i}"
      Rails.cache.fetch(key, expires_in: cache[:expires_in], &render)
    else
      render.call 0
    end
  end

  def __frontend_expected_boot_record_error(module_name)
    "
    throw new Error('Expected module #{module_name} to export a hash ' +
      '`boot` with function fields `renderToString` and `hydrate`, but got `' + boot + '`. ' +
      'To create such boot record from PureScript, use `Utils.SSR.boot`')
    "
  end
end
# rubocop:enable Rails/OutputSafety, Rails/HelperInstanceVariable
