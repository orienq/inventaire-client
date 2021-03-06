exports.config =
  # See http://brunch.io/#documentation for docs.
  notifications: yes
  sourceMaps: true
  paths:
    # doc: https://github.com/brunch/brunch/blob/master/docs/config.md#paths
    watched: ['app', 'vendor']
  files:
    javascripts:
      joinTo:
        # foundation js is included in vendor as a normal bower component
        'javascripts/vendor.js': /^(vendor\/scripts|bower_components)/
        'javascripts/app.js': /^app/
      order:
        before: [
          "bower_components/jquery/dist/jquery.js"
          "bower_components/underscore/underscore.js"
          "bower_components/backbone/backbone.js"
        ],
        after: [
          "bower_components/leaflet.markercluster/dist/leaflet.markercluster-src.js"
          "vendor/*"
        ]

    stylesheets:
      joinTo:
        # /!\ foundation is joined to app.css as its scss '!default'ed properties requires to be after app
        # but in the same compiled file! (thus the failing attemps to extract foundation in its own file)
        'stylesheets/vendor.css': /^(vendor\/stylesheets|bower_components\/(?!foundation))/
        'stylesheets/app.css': /^app/

    templates:
      joinTo: 'javascripts/app.js'

  plugins:
    autoReload:
      enabled: true
  # modules:
  #   nameCleaner: (path) ->
  #     path.replace /.*app\//, ''
  overrides:
    production:
      sourceMaps: true
      optimize: true
      plugins: autoReload: enabled: false