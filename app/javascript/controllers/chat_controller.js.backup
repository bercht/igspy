import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "messagesContainer",
    "messageInput", 
    "sendButton",
    "fileInput",
    "filePreview",
    "fileName",
    "fileSize",
    "loadingIndicator",
    "message"
  ]

  static values = {
    conversationId: Number
  }

  connect() {
    console.log("Chat controller connected")
    this.uploadedFile = null
    this.scrollToBottom()
    this.autoResizeTextarea()
  }

  handleKeydown(event) {
    // Enviar com Ctrl+Enter ou Cmd+Enter
    if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
      event.preventDefault()
      this.sendMessage(event)
    }
  }

  async sendMessage(event) {
    event.preventDefault()

    const content = this.messageInputTarget.value.trim()
    
    if (!content && !this.uploadedFile) {
      return
    }

    // Desabilitar input
    this.disableInput()

    try {
      // Preparar dados da mensagem
      const messageData = {
        message: {
          content: content || "(arquivo enviado)"
        }
      }

      // Adicionar file_ids se houver arquivo
      if (this.uploadedFile) {
        messageData.message.file_ids = [{
          file_id: this.uploadedFile.file_id,
          filename: this.uploadedFile.filename,
          content_type: this.uploadedFile.content_type,
          file_size: this.uploadedFile.file_size
        }]
      }

      // Adicionar mensagem do usuário na UI imediatamente
      this.addMessageToUI("user", content, this.uploadedFile ? [this.uploadedFile] : [])

      // Limpar input e arquivo
      this.messageInputTarget.value = ""
      this.removeFile()
      this.autoResizeTextarea()

      // Mostrar indicador de loading
      this.showLoadingIndicator()

      // Enviar para o backend
      const response = await fetch(`/admin/conversations/${this.conversationIdValue}/messages`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": this.getCSRFToken()
        },
        body: JSON.stringify(messageData)
      })

      const data = await response.json()

      if (response.ok) {
        // Adicionar resposta do assistant
        this.addMessageToUI("assistant", data.assistant_message.content, [])
      } else {
        alert(`Erro: ${data.error}`)
      }

    } catch (error) {
      console.error("Error sending message:", error)
      alert("Erro ao enviar mensagem. Tente novamente.")
    } finally {
      this.hideLoadingIndicator()
      this.enableInput()
      this.messageInputTarget.focus()
    }
  }

  async handleFileSelect(event) {
    const file = event.target.files[0]
    
    if (!file) return

    // Validar tamanho (10MB)
    if (file.size > 10 * 1024 * 1024) {
      alert("Arquivo muito grande! Máximo: 10MB")
      event.target.value = ""
      return
    }

    // Validar tipo
    const allowedTypes = ["text/plain", "text/csv", "application/json", "image/png", "image/jpeg"]
    if (!allowedTypes.includes(file.type)) {
      alert("Tipo de arquivo não permitido!")
      event.target.value = ""
      return
    }

    try {
      // Mostrar preview
      this.fileNameTarget.textContent = file.name
      this.fileSizeTarget.textContent = this.formatFileSize(file.size)
      this.filePreviewTarget.classList.remove("hidden")

      // Fazer upload
      const formData = new FormData()
      formData.append("file", file)

      const response = await fetch(`/admin/conversations/${this.conversationIdValue}/upload_file`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": this.getCSRFToken()
        },
        body: formData
      })

      const data = await response.json()

      if (response.ok) {
        // Guardar dados do arquivo
        this.uploadedFile = {
          file_id: data.file_id,
          filename: data.filename,
          content_type: file.type,
          file_size: file.size
        }
        console.log("File uploaded:", this.uploadedFile)
      } else {
        alert(`Erro no upload: ${data.error}`)
        this.removeFile()
      }

    } catch (error) {
      console.error("Upload error:", error)
      alert("Erro ao fazer upload. Tente novamente.")
      this.removeFile()
    }

    // Limpar input
    event.target.value = ""
  }

  removeFile() {
    this.uploadedFile = null
    this.filePreviewTarget.classList.add("hidden")
    if (this.hasFileInputTarget) {
      this.fileInputTarget.value = ""
    }
  }

  addMessageToUI(role, content, attachments = []) {
    const isUser = role === "user"
    const now = new Date()
    const time = now.toLocaleTimeString("pt-BR", { hour: "2-digit", minute: "2-digit" })

    const messageDiv = document.createElement("div")
    messageDiv.className = `flex ${isUser ? "justify-end" : "justify-start"}`
    messageDiv.dataset.chatTarget = "message"

    let attachmentsHTML = ""
    if (attachments.length > 0) {
      attachmentsHTML = `
        <div class="mt-2 space-y-1">
          ${attachments.map(att => `
            <div class="flex items-center space-x-2 text-xs ${isUser ? "text-blue-100" : "text-gray-600"}">
              <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15.172 7l-6.586 6.586a2 2 0 102.828 2.828l6.414-6.586a4 4 0 00-5.656-5.656l-6.415 6.585a6 6 0 108.486 8.486L20.5 13" />
              </svg>
              <span>${att.filename} (${this.formatFileSize(att.file_size)})</span>
            </div>
          `).join("")}
        </div>
      `
    }

    messageDiv.innerHTML = `
      <div class="${isUser ? "bg-blue-600 text-white" : "bg-white border border-gray-200 text-gray-900"} rounded-lg px-4 py-3 max-w-2xl shadow-sm">
        <div class="whitespace-pre-wrap break-words">${this.escapeHtml(content)}</div>
        ${attachmentsHTML}
        <div class="text-xs ${isUser ? "text-blue-100" : "text-gray-500"} mt-1">${time}</div>
      </div>
    `

    this.messagesContainerTarget.appendChild(messageDiv)
    this.scrollToBottom()
  }

  showLoadingIndicator() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.remove("hidden")
      this.loadingIndicatorTarget.classList.add("flex")
      this.scrollToBottom()
    }
  }

  hideLoadingIndicator() {
    if (this.hasLoadingIndicatorTarget) {
      this.loadingIndicatorTarget.classList.add("hidden")
      this.loadingIndicatorTarget.classList.remove("flex")
    }
  }

  disableInput() {
    this.messageInputTarget.disabled = true
    this.sendButtonTarget.disabled = true
  }

  enableInput() {
    this.messageInputTarget.disabled = false
    this.sendButtonTarget.disabled = false
  }

  autoResizeTextarea() {
    const textarea = this.messageInputTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.min(textarea.scrollHeight, 150) + "px"
  }

  scrollToBottom() {
    setTimeout(() => {
      this.messagesContainerTarget.scrollTop = this.messagesContainerTarget.scrollHeight
    }, 100)
  }

  formatFileSize(bytes) {
    if (bytes === 0) return "0 B"
    const k = 1024
    const sizes = ["B", "KB", "MB", "GB"]
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + " " + sizes[i]
  }

  escapeHtml(text) {
    const div = document.createElement("div")
    div.textContent = text
    return div.innerHTML
  }

  getCSRFToken() {
    return document.querySelector("[name='csrf-token']")?.content
  }
}