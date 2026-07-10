# frozen_string_literal: true

class KafkaDeliveryJob
  include Sidekiq::Job
  sidekiq_options queue: "kafka", retry: 5

  def perform(topic, payload_json)
    # In production: deliver to Kafka via rdkafka
    Rails.logger.info("[KafkaDeliveryJob] Delivered to #{topic}")
  end
end
