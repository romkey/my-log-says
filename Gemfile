# frozen_string_literal: true

source 'https://rubygems.org'

ruby '3.3.11'

gem 'bootsnap', require: false
gem 'dotenv-rails', groups: %i[development test]
gem 'excon', '~> 1.2'
gem 'pg', '~> 1.6'
gem 'puma', '>= 6.0'
gem 'rails', '8.1.3'
gem 'redis', '~> 5.4'
gem 'sidekiq', '8.1.3'
gem 'sidekiq-cron', '~> 2.3'

group :development, :test do
  gem 'debug', platforms: %i[mri windows]
  gem 'rubocop-rails', require: false
end

group :test do
  gem 'capybara'
  gem 'selenium-webdriver'
end

group :development do
  gem 'web-console'
end
