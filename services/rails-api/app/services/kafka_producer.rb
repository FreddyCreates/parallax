# frozen_string_literal: true

# Kafka event producer for async event streaming.
class KafkaProducer
  KAFKA_BROKERS = ENV.fetch("KAFKA_BROKERS", "localhost:9092").split(",")

  class << self
    def publish(topic, payload)
      # In production: uses karafka/rdkafka to publish to Confluent Kafka
      Rails.logger.info("[Kafka] Publishing to #{topic}: #{payload.to_json}")

      # Async delivery via Sidekiq for non-blocking
      KafkaDeliveryJob.perform_async(topic, payload.to_json)
    end
  end
end
