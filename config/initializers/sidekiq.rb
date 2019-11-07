# frozen_string_literal: true

Sidekiq.configure_server do |config|
  config.redis = {url: ENV["REDIS_URL"]}
  config.on(:startup) do
    ActiveRecord::Base.logger = nil if Rails.env.production?
  end
end

Sidekiq.configure_client do |config|
  config.redis = {url: ENV["REDIS_URL"]}
  config.on(:startup) do
    ActiveRecord::Base.logger = nil if Rails.env.production?
  end
end

Sidekiq::Extensions.enable_delay!
