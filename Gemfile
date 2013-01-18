source 'https://rubygems.org'

ruby '1.9.3'

gem 'rails', '3.2.9'
gem 'jquery-rails'
gem "thin"
gem "bootstrap-sass", ">= 2.2.2.0"
gem "simple_form", ">= 2.0.4"
gem "figaro", ">= 0.5.0"
gem 'mysql2'
gem 'hirb'
gem 'devise'
gem 'newrelic_rpm'

group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

group :development do
  gem 'sqlite3'
  gem "better_errors", ">= 0.3.2"
  gem "binding_of_caller", ">= 0.6.8"
  gem "hub", ">= 1.10.2", :require => nil

  gem "factory_girl_rails", ">= 4.1.0"
end

group :test do
  gem "email_spec", ">= 1.4.0"
  gem "factory_girl_rails", ">= 4.1.0"
  gem "database_cleaner", ">= 0.9.1"
  gem "capybara", ">= 2.0.1"
  gem "rspec-rails", ">= 2.11.4"
end

group :production do
  gem "pg"
end