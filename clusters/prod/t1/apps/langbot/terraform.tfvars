name = "langbot"

deployments = [
  "langbot-claude-sonnet",
  "langbot-gemini-pro",
  "langbot-openai-gpt",
]

manifests = [
  "langbot-policy",
  "langbot-vault",
]

onepassword_vault = "sigsrv-prod"
onepassword_items = {
  "langbot-claude-sonnet" = "sigsrv-prod-langbot-secrets-claude-sonnet"
  "langbot-gemini-pro"    = "sigsrv-prod-langbot-secrets-gemini-pro"
  "langbot-openai"        = "sigsrv-prod-langbot-secrets-openai"
  "langbot-openai-gpt"    = "sigsrv-prod-langbot-secrets-openai-gpt"
}
