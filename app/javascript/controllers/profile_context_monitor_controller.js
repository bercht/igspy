import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    status: String,
    updatedAt: Number,
    url: String
  }

  connect() {
    if (this.isInProgress()) {
      this.startPolling()
    }
  }

  disconnect() {
    this.stopPolling()
  }

  isInProgress() {
    const active = ["pending", "processing"]
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
      const response = await fetch(this.urlValue, {
        headers: { "Accept": "application/json" }
      })

      if (!response.ok) return

      const data = await response.json()
      this.applyUpdate(data)
    } catch (e) {
      // silencioso - tenta novamente no próximo intervalo
    }
  }

  applyUpdate(data) {
    const previousStatus = this.statusValue
    const previousUpdatedAt = this.updatedAtValue

    this.statusValue = data.status
    if (data.updated_at) {
      this.updatedAtValue = data.updated_at
    }

    if ((data.completed || data.failed) &&
        (previousStatus !== data.status || previousUpdatedAt !== data.updated_at)) {
      this.stopPolling()
      setTimeout(() => window.location.reload(), 1500)
    }
  }
}
