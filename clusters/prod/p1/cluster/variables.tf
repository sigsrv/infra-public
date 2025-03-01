variable "status" {
  default = "running"

  validation {
    condition     = contains(["prepare", "ready", "running"], var.status)
    error_message = "Invalid status: ${var.status}"
  }
}
