import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    scrapingId: Number,
    status: String
  }
  
  static targets = ["statusBadge", "statusMessage", "timeline"]

  connect() {
    console.log("Scraping monitor connected")
    console.log("Status:", this.statusValue)
    
    // Se o scraping ainda está em progresso, faz polling
    if (this.isInProgress()) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  isInProgress() {
    return ["pending", "fetching", "processing"].includes(this.statusValue)
  }

  startPolling() {
    console.log("Starting polling...")
    // Recarrega a página a cada 3 segundos
    this.pollInterval = setInterval(() => {
      this.refreshStatus()
    }, 3000)
  }

  stopPolling() {
    if (this.pollInterval) {
      console.log("Stopping polling...")
      clearInterval(this.pollInterval)
    }
  }

  refreshStatus() {
    console.log("Refreshing status...")
    // Recarrega a página para pegar o status atualizado
    window.location.reload()
  }
}