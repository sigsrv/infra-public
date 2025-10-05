name = "langbot"

deployments = [
  "langbot-claude",
  "langbot-gemini",
  "langbot-openai-gpt-4o",
  "langbot-openai-o3",
  "langbot-openai-o4-mini",
]

manifests = [
  "langbot-policy",
  "langbot-vault",
]

onepassword_vault = "sigsrv-prod"
onepassword_items = {
  "langbot-claude"         = "sigsrv-prod-langbot-secrets-claude"
  "langbot-gemini"         = "sigsrv-prod-langbot-secrets-gemini"
  "langbot-openai"         = "sigsrv-prod-langbot-secrets-openai"
  "langbot-openai-gpt-4o"  = "sigsrv-prod-langbot-secrets-openai-gpt-4o"
  "langbot-openai-o3"      = "sigsrv-prod-langbot-secrets-openai-o3"
  "langbot-openai-o4-mini" = "sigsrv-prod-langbot-secrets-openai-o4-mini"
}
