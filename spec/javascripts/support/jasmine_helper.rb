# Prevent PhantomJS auto install, uses PhantomJS already on your path.
Jasmine.configure do |config|
  config.prevent_phantom_js_auto_install = true
end
