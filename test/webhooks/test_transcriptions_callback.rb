#!/usr/bin/env ruby
# test/webhooks/test_transcriptions_callback.rb

require 'httparty'
require 'json'

# Configuração
BASE_URL = 'http://localhost:3000'
WEBHOOK_URL = "#{BASE_URL}/webhooks/transcriptions_completed"

# Criar um scraping de teste
puts "🧪 Iniciando teste de callback de transcrições...\n"

# Dados de teste
test_scraping_id = "test_#{Time.now.to_i}"
test_record_id = 1 # Ajuste para um ID real do seu banco

# Simular callback do n8n
puts "📤 Enviando callback para: #{WEBHOOK_URL}"
puts "   scrapingId: #{test_scraping_id}"
puts "   scrapingRecordId: #{test_record_id}\n"

response = HTTParty.post(
  WEBHOOK_URL,
  body: {
    scrapingId: test_scraping_id,
    scrapingRecordId: test_record_id
  }.to_json,
  headers: {
    'Content-Type' => 'application/json'
  }
)

puts "\n📥 Resposta do servidor:"
puts "   Status: #{response.code}"
puts "   Body: #{JSON.pretty_generate(JSON.parse(response.body))}\n"

if response.success?
  puts "✅ Callback processado com sucesso!"
else
  puts "❌ Erro no callback!"
end
