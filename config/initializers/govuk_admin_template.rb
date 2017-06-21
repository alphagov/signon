# We were setting app_title here, but we needed to use the department.name from
# localisations, which aren't available in initializers. Our solution was to move
# it to app/views/application.html.erb.
# config/initializers/govuk_admin_template.rb
GovukAdminTemplate.configure do |c|
  c.disable_google_analytics = false
end
