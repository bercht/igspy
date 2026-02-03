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

    # ✅ ADICIONAR: Log do event.id para rastreamento
    Rails.logger.info "🔔 Webhook received | Event ID: #{event.id} | Type: #{event.type}"

    # Handle the event
    case event.type
    when 'checkout.session.completed'
      handle_checkout_completed(event.data.object, event.id)
    when 'customer.subscription.updated'
      handle_subscription_updated(event.data.object, event.id)
    when 'customer.subscription.deleted'
      handle_subscription_deleted(event.data.object, event.id)
    when 'invoice.payment_succeeded'
      handle_payment_succeeded(event.data.object, event.id)
    when 'invoice.payment_failed'
      handle_payment_failed(event.data.object, event.id)
    else
      Rails.logger.info "Unhandled event type: #{event.type}"
    end

    head :ok
  end

  private

  def handle_checkout_completed(session, event_id)
    Rails.logger.info "📦 Processing checkout.session.completed | Event: #{event_id}"
    
    user = User.find_by(id: session.client_reference_id)
    
    unless user
      Rails.logger.error "❌ User not found: #{session.client_reference_id}"
      return
    end

    unless session.subscription
      Rails.logger.error "❌ Checkout session missing subscription: #{session.id}"
      return
    end

    # Forma correta segundo a documentação oficial
    subscription_data = Stripe::Subscription.retrieve(
      { id: session.subscription, expand: ['latest_invoice'] }
    )

    Rails.logger.info "📦 Creating subscription for user #{user.id}"
    Rails.logger.info "  Stripe Subscription ID: #{subscription_data.id}"
    Rails.logger.info "  Status: #{subscription_data.status}"
    Rails.logger.info "  Current period end (raw): #{subscription_data.current_period_end}"
    Rails.logger.info "  Cancel at (raw): #{subscription_data.cancel_at}"

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
    Rails.logger.error "Event ID: #{event_id}"
    Rails.logger.error "Error class: #{e.class.name}"
    Rails.logger.error "Backtrace:\n#{e.backtrace.first(10).join("\n")}"
  end

  def handle_subscription_updated(subscription, event_id)
    Rails.logger.info "📦 Processing customer.subscription.updated | Event: #{event_id}"
    Rails.logger.info "  Subscription ID: #{subscription.id}"
    Rails.logger.info "  Status: #{subscription.status}"
    Rails.logger.info "  Cancel at period end: #{subscription.cancel_at_period_end}"
    Rails.logger.info "  Cancel at (raw): #{subscription.cancel_at}"
    Rails.logger.info "  Current period end (raw): #{subscription.current_period_end}"
    
    # ✅ CORREÇÃO #1: Log explícito se não encontrar
    sub = Subscription.find_by(stripe_subscription_id: subscription.id)
    
    unless sub
      Rails.logger.error "❌ Subscription not found in database: #{subscription.id}"
      Rails.logger.error "Event ID: #{event_id}"
      Rails.logger.error "Available subscriptions in DB: #{Subscription.pluck(:id, :stripe_subscription_id).inspect}"
      return
    end
    
    Rails.logger.info "  Found in DB: Subscription ID=#{sub.id} | User ID=#{sub.user_id}"
    Rails.logger.info "  Current DB state:"
    Rails.logger.info "    status: #{sub.status}"
    Rails.logger.info "    current_period_end: #{sub.current_period_end}"
    Rails.logger.info "    cancel_at: #{sub.cancel_at}"

    # ✅ CORREÇÃO #2: Pegar current_period_end corretamente
    current_period_end = subscription.current_period_end
    
    if current_period_end.nil?
      Rails.logger.warn "⚠️ current_period_end is nil at subscription level"
      # Tentar pegar de items.data se existir
      if subscription.respond_to?(:items) && subscription.items&.data&.any?
        current_period_end = subscription.items.data.first.current_period_end
        Rails.logger.info "  Using current_period_end from items.data: #{current_period_end}"
      end
    end
    
    # ✅ CORREÇÃO #3: Simplificar lógica de cancel_at
    cancel_at = subscription.cancel_at
    
    Rails.logger.info "  Values to update:"
    Rails.logger.info "    status (from Stripe): #{subscription.status}"
    Rails.logger.info "    current_period_end (converted): #{timestamp_to_time(current_period_end)}"
    Rails.logger.info "    cancel_at (converted): #{timestamp_to_time(cancel_at)}"

    # ✅ CORREÇÃO #4: Usar update! para levantar exceção
    # ✅ CORREÇÃO #5: Usar status real do Stripe (não alterar para 'canceled' prematuramente)
    sub.update!(
      status: subscription.status,
      current_period_end: timestamp_to_time(current_period_end),
      cancel_at: timestamp_to_time(cancel_at)
    )
    
    # Recarregar do banco para confirmar
    sub.reload
    
    Rails.logger.info "✅ Subscription updated successfully"
    Rails.logger.info "  Event ID: #{event_id}"
    Rails.logger.info "  Subscription ID: #{sub.id}"
    Rails.logger.info "  New DB state:"
    Rails.logger.info "    status: #{sub.status}"
    Rails.logger.info "    current_period_end: #{sub.current_period_end}"
    Rails.logger.info "    cancel_at: #{sub.cancel_at}"
    Rails.logger.info "    updated_at: #{sub.updated_at}"
    
  rescue => e
    Rails.logger.error "❌ Error in handle_subscription_updated: #{e.message}"
    Rails.logger.error "Event ID: #{event_id}"
    Rails.logger.error "Subscription ID (from webhook): #{subscription.id rescue 'N/A'}"
    Rails.logger.error "Error class: #{e.class.name}"
    Rails.logger.error "Backtrace:\n#{e.backtrace.first(10).join("\n")}"
    
    # Se for erro de validação, mostrar detalhes
    if e.is_a?(ActiveRecord::RecordInvalid)
      Rails.logger.error "Validation errors: #{e.record.errors.full_messages.join(', ')}"
    end
  end

  def handle_subscription_deleted(subscription, event_id)
    Rails.logger.info "📦 Processing customer.subscription.deleted | Event: #{event_id}"
    
    sub = Subscription.find_by(stripe_subscription_id: subscription.id)
    
    unless sub
      Rails.logger.error "❌ Subscription not found: #{subscription.id}"
      return
    end

    current_period_end = subscription.current_period_end || subscription.ended_at
    canceled_at = subscription.canceled_at || subscription.cancel_at

    sub.update!(
      status: 'canceled',
      current_period_end: timestamp_to_time(current_period_end),
      cancel_at: timestamp_to_time(canceled_at) || sub.cancel_at
    )
    
    Rails.logger.info "✅ Subscription canceled: #{sub.id}"
  rescue => e
    Rails.logger.error "❌ Error in handle_subscription_deleted: #{e.message}"
    Rails.logger.error "Event ID: #{event_id}"
    Rails.logger.error "Backtrace:\n#{e.backtrace.first(10).join("\n")}"
  end

  def handle_payment_succeeded(invoice, event_id)
    Rails.logger.info "✅ Payment succeeded | Event: #{event_id} | Invoice: #{invoice.id}"
  end

  def handle_payment_failed(invoice, event_id)
    Rails.logger.error "❌ Payment failed | Event: #{event_id} | Invoice: #{invoice.id}"
  end

  def timestamp_to_time(timestamp)
    return nil if timestamp.nil?

    value = timestamp.to_i
    return nil if value.zero?

    Time.zone.at(value)
  end
end
