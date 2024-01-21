#!/usr/bin/env fish
set OP_DISCORD_GPT_BOT_ROOT_SECRET_PATH "op://sigsrv-prod/sigsrv-prod-chatgpt-discord-bot-secrets"

kubectl create ns --context sigsrv-prod chatgpt-discord-bot

set OP_DISCORD_GPT_BOT_3_5_SECRET_PATH "$OP_DISCORD_GPT_BOT_ROOT_SECRET_PATH/chatgpt-discord-bot-secret-gpt-3.5-turbo"
kubectl create secret generic --context sigsrv-prod -n chatgpt-discord-bot chatgpt-discord-bot-secret-gpt-3.5-turbo \
  --from-literal=DISCORD_TOKEN=(op read "$OP_DISCORD_GPT_BOT_3_5_SECRET_PATH/DISCORD_TOKEN") \
  --from-literal=OPENAI_API_KEY=(op read "$OP_DISCORD_GPT_BOT_3_5_SECRET_PATH/OPENAI_API_KEY")
kubectl apply --context sigsrv-prod -n chatgpt-discord-bot -f chatgpt-discord-bot-gpt-3.5-turbo.yaml

set OP_DISCORD_GPT_BOT_4_SECRET_PATH "$OP_DISCORD_GPT_BOT_ROOT_SECRET_PATH/chatgpt-discord-bot-secret-gpt-4"
kubectl create secret generic --context sigsrv-prod -n chatgpt-discord-bot chatgpt-discord-bot-secret-gpt-4 \
  --from-literal=DISCORD_TOKEN=(op read "$OP_DISCORD_GPT_BOT_4_SECRET_PATH/DISCORD_TOKEN") \
  --from-literal=OPENAI_API_KEY=(op read "$OP_DISCORD_GPT_BOT_4_SECRET_PATH/OPENAI_API_KEY")
kubectl apply --context sigsrv-prod -n chatgpt-discord-bot -f chatgpt-discord-bot-gpt-4.yaml
