name = "langbot"

deployments = [
  "langbot-claude-sonnet",
  "langbot-gemini-pro",
  "langbot-openai-gpt-4",
  "langbot-openai-o3",
  "langbot-openai-o4-mini",
]

manifests = [
  "langbot-policy",
  "langbot-vault",
]

onepassword_vault = "sigsrv-prod"
onepassword_items = {
  "langbot-claude-sonnet"  = "sigsrv-prod-langbot-secrets-claude-sonnet"
  "langbot-gemini-pro"     = "sigsrv-prod-langbot-secrets-gemini-pro"
  "langbot-openai"         = "sigsrv-prod-langbot-secrets-openai"
  "langbot-openai-gpt-4"   = "sigsrv-prod-langbot-secrets-openai-gpt-4"
  "langbot-openai-o3"      = "sigsrv-prod-langbot-secrets-openai-o3"
  "langbot-openai-o4-mini" = "sigsrv-prod-langbot-secrets-openai-o4-mini"
}
