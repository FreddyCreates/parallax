# frozen_string_literal: true

class WebhookDeliveryJob
  include Sidekiq::Job
  sidekiq_options queue: "webhooks", retry: 3

  def perform(webhook_id, event, payload_json)
    webhook = Webhook.find(webhook_id)
    payload = JSON.parse(payload_json)

    signature = OpenSSL::HMAC.hexdigest("SHA256", webhook.secret, payload_json)

    response = HTTP.headers(
      "Content-Type" => "application/json",
      "X-Parralax-Event" => event,
      "X-Parralax-Signature" => "sha256=#{signature}"
    ).timeout(30).post(webhook.url, json: payload)

    webhook.deliveries.create!(
      event: event,
      status_code: response.status,
      delivered_at: Time.current
    )
  end
end
