variable "github" {
  type        = map(string)
  description = "Github private access token"
}

variable "webhook_url" {
  type        = map(string)
  description = "Webhook URL for notifications"
}
