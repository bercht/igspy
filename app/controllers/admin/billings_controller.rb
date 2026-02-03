class Admin::BillingsController < Admin::BaseController
  def new
    # Página de seleção de plano
    @plans = [
      {
        name: 'Mensal',
        price: 'R$ 49,00',
        interval: 'mês',
        price_id: Rails.application.credentials.dig(:stripe, :price_monthly)
      },
      {
        name: 'Semestral',
        price: 'R$ 190,00',
        interval: '6 meses',
        price_id: Rails.application.credentials.dig(:stripe, :price_semiannual),
        savings: 'Economize R$ 104'
      }
    ]
  end

  def create
    # Criar Stripe Checkout Session
    session = Stripe::Checkout::Session.create({
      customer: get_or_create_stripe_customer,
      client_reference_id: current_user.id.to_s,
      mode: 'subscription',
      line_items: [{
        price: params[:price_id],
        quantity: 1
      }],
      success_url: success_admin_billings_url,  # MUDOU AQUI
      cancel_url: cancel_admin_billings_url,    # MUDOU AQUI
      allow_promotion_codes: true,
      billing_address_collection: 'required',
      payment_method_types: ['card'],
      locale: 'pt-BR'
    })

    redirect_to session.url, allow_other_host: true, status: 303
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe error: #{e.message}"
    redirect_to new_admin_billing_path, alert: "Erro ao processar pagamento: #{e.message}"
  end

  def success
    # Página de sucesso após pagamento
  end

  def cancel
    # Página quando usuário cancela o checkout
  end

  def portal
    # Redireciona para o Stripe Customer Portal
    session = Stripe::BillingPortal::Session.create({
      customer: current_user.stripe_customer_id,
      return_url: admin_root_url
    })

    redirect_to session.url, allow_other_host: true, status: 303
  rescue Stripe::StripeError => e
    Rails.logger.error "Stripe portal error: #{e.message}"
    redirect_to admin_root_path, alert: "Erro ao acessar portal de pagamento."
  end

  private

  def get_or_create_stripe_customer
    if current_user.stripe_customer_id.present?
      current_user.stripe_customer_id
    else
      customer = Stripe::Customer.create({
        email: current_user.email,
        metadata: { user_id: current_user.id }
      })
      current_user.update(stripe_customer_id: customer.id)
      customer.id
    end
  end
end