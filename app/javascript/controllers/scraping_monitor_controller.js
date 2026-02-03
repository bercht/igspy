import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    scrapingId: Number,
    status: String
  }

  static targets = ["statusBadge", "statusMessage", "postsCount", "analysisStatus", "progressSection"]

  connect() {
    if (this.isInProgress()) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  // Status que mantém polling ativo
  isInProgress() {
    const active = ["pending", "fetching", "scraped", "transcribing", "transcriptions_completed", "analyzing"]
    return active.includes(this.statusValue)
  }

  startPolling() {
    this.pollInterval = setInterval(() => this.fetchStatus(), 4000)
  }

  stopPolling() {
    if (this.pollInterval) {
      clearInterval(this.pollInterval)
      this.pollInterval = null
    }
  }

  async fetchStatus() {
    try {
      const response = await fetch(`/api/scrapings/${this.scrapingIdValue}/status`, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) return

      const data = await response.json()
      this.applyUpdate(data)

    } catch (e) {
      // silencioso - tenta de novo no próximo intervalo
    }
  }

  applyUpdate(data) {
    const previousStatus = this.statusValue
    this.statusValue = data.status

    // Atualiza badge de status
    if (this.hasStatusBadgeTarget) {
      this.statusBadgeTarget.textContent = this.labelFor(data.status)
      this.statusBadgeTarget.className = "px-4 py-2 rounded-full text-sm font-semibold " + this.badgeClassFor(data.status)
    }

    // Atualiza mensagem de progresso
    if (this.hasStatusMessageTarget) {
      this.statusMessageTarget.textContent = data.status_message
    }

    // Atualiza contagem de posts
    if (this.hasPostsCountTarget) {
      this.postsCountTarget.textContent = data.posts_count
    }

    // Atualiza card da Análise IA
    if (this.hasAnalysisStatusTarget) {
      this.analysisStatusTarget.innerHTML = this.analysisHTML(data)
    }

    // Se completou ou falhou → reload uma vez para renderizar a análise completa
    if (previousStatus !== data.status && (data.completed || data.failed)) {
      this.stopPolling()
      // Pequeno delay para garantir que o banco já persistiu tudo
      setTimeout(() => window.location.reload(), 2000)
      return
    }

    // Se ainda está em progresso, garante polling ativo
    if (data.in_progress && !this.pollInterval) {
      this.startPolling()
    }
  }

  // Label para o badge
  labelFor(status) {
    const labels = {
      pending: "Em Progresso",
      fetching: "Coletando",
      scraped: "Coletado",
      transcribing: "Transcrindo",
      transcriptions_completed: "Transcrições OK",
      analyzing: "Analisando",
      completed: "Concluído",
      failed: "Erro",
      analysis_failed: "Erro"
    }
    return labels[status] || status.toUpperCase()
  }

  // Classes do badge por status
  badgeClassFor(status) {
    const classes = {
      pending: "bg-gray-100 text-gray-800",
      fetching: "bg-blue-100 text-blue-800",
      scraped: "bg-blue-100 text-blue-800",
      transcribing: "bg-yellow-100 text-yellow-800",
      transcriptions_completed: "bg-yellow-100 text-yellow-800",
      analyzing: "bg-purple-100 text-purple-800",
      completed: "bg-green-100 text-green-800",
      failed: "bg-red-100 text-red-800",
      analysis_failed: "bg-red-100 text-red-800"
    }
    return classes[status] || "bg-gray-100 text-gray-800"
  }

  // HTML do card "Análise IA" por estado
  analysisHTML(data) {
    if (data.has_analysis) {
      return `
        <div class="flex items-center space-x-2">
          <div class="flex-1">
            <div class="text-lg font-semibold" style="color: #00D98E;">Pronta</div>
            <p class="text-sm text-gray-500">Análise concluída com sucesso</p>
          </div>
          <svg class="w-8 h-8" style="color: #00D98E;" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>`
    }

    if (data.status === "analyzing" || data.status === "transcriptions_completed") {
      return `
        <div class="flex items-center space-x-2">
          <div class="flex-1">
            <div class="text-lg font-semibold text-yellow-600">Gerando...</div>
            <p class="text-sm text-gray-500">Aguarde a IA analisar</p>
          </div>
          <svg class="animate-spin w-8 h-8 text-yellow-500" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
        </div>`
    }

    if (data.failed) {
      return `
        <div class="text-lg font-semibold text-red-600">Erro</div>
        <p class="text-sm text-gray-500">${data.status_message}</p>`
    }

    // Estados anteriores à análise
    return `
      <div class="text-lg font-semibold text-gray-400">Pendente</div>
      <p class="text-sm text-gray-500">Aguardando coleta</p>`
  }
}