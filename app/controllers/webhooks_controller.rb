class WebhooksController < ActionController::Base
  skip_before_action :verify_authenticity_token

  def stripe
    payload = request.body.read
    sig_header = request.env['HTTP_STRIPE_SIGNATURE']
    endpoint_secret = Rails.application.credentials.dig(:stripe, :webhook_secret)

    begin
      event = Stripe::Webhook.construct_event(
        payload, sig_header, endpoint_secret
      )
    rescue JSON::ParserError => e
      Rails.logger.error "Webhook JSON parse error: #{e.message}"
      return head :bad_request
    rescue Stripe::SignatureVerificationError => e
      Rails.logger.error "Webhook signature verification failed: #{e.message}"
      return head :bad_request
    end

    # Handle the event
    case event.type
    when 'checkout.session.completed'
      handle_checkout_completed(event.data.object)
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event.data.object)
    when 'invoice.payment_failed'
      handle_payment_failed(event.data.object)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    head :ok
  end

  private

  def handle_checkout_completed(session)
    user = User.find_by(id: session.client_reference_id)
    return unless user

    unless session.subscription
      Rails.logger.error "❌ Checkout session missing subscription: #{session.id}"
      return
    end

    # Forma correta segundo a documentação oficial
    subscription_data = Stripe::Subscription.retrieve(
      { id: session.subscription, expand: ['latest_invoice'] }
    )

    user.create_subscription!(
      stripe_subscription_id: subscription_data.id,
      stripe_price_id: subscription_data.items.data.first.price.id,
      status: subscription_data.status,
      current_period_end: timestamp_to_time(subscription_data.current_period_end),
      cancel_at: timestamp_to_time(subscription_data.cancel_at)
    )

    Rails.logger.info "✅ Subscription created for user #{user.id}: #{subscription_data.id}"
  rescue => e
    Rails.logger.error "❌ Error in handle_checkout_completed: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
  end

  def handle_subscription_updated(subscription)
    sub = Subscription.find_by(stripe_subscription_id: subscription.id)
    return unless sub

    current_period_end = subscription.current_period_end
    cancel_at = if subscription.cancel_at_period_end
                  subscription.cancel_at || subscription.current_period_end
                else
                  subscription.cancel_at
                end

    sub.update(
      status: subscription.status,
      current_period_end: timestamp_to_time(current_period_end),
      cancel_at: subscription.cancel_at_period_end ? timestamp_to_time(cancel_at) : nil
    )

    Rails.logger.info "✅ Subscription updated: #{sub.id}"
  rescue => e
    Rails.logger.error "❌ Error in handle_subscription_updated: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
  end

  def handle_subscription_deleted(subscription)
    sub = Subscription.find_by(stripe_subscription_id: subscription.id)
    return unless sub

    current_period_end = subscription.current_period_end || subscription.ended_at
    canceled_at = subscription.canceled_at || subscription.cancel_at

    sub.update(
      status: 'canceled',
      current_period_end: timestamp_to_time(current_period_end),
      cancel_at: timestamp_to_time(canceled_at) || sub.cancel_at
    )
    Rails.logger.info "✅ Subscription canceled: #{sub.id}"
  rescue => e
    Rails.logger.error "❌ Error in handle_subscription_deleted: #{e.message}"
    Rails.logger.error "Backtrace: #{e.backtrace.first(5).join("\n")}"
  end

  def handle_payment_succeeded(invoice)
    Rails.logger.info "✅ Payment succeeded for invoice: #{invoice.id}"
  end

  def handle_payment_failed(invoice)
    Rails.logger.error "❌ Payment failed for invoice: #{invoice.id}"
  end

  def timestamp_to_time(timestamp)
    return nil if timestamp.nil?
    return timestamp if timestamp.is_a?(Time)
    return timestamp.to_time if timestamp.respond_to?(:to_time)

    value = timestamp.to_i
    return nil if value.zero?

    Time.zone.at(value)
  end
end
