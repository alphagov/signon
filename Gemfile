source 'http://rubygems.org'

gem 'rails', '3.1.1'
             
gem 'sqlite3'
gem 'json'
gem 'jquery-rails'   

gem "ri_cal", "~> 0.8.8"   
             
if ENV['SLIMMER_DEV']
  gem 'slimmer', :path => '../slimmer'
else
  gem 'slimmer', :git => 'git@github.com:alphagov/slimmer.git'
end                

group :assets do
  gem 'sass-rails', "  ~> 3.1.0"
  gem 'coffee-rails', "~> 3.1.0"
  gem "therubyracer", "~> 0.9.4"
  gem 'uglifier'
end