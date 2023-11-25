#!/usr/bin/env fish

set OP_DISCORD_GPT_BOT_ROOT_SECRET_PATH "op://Personal/sigsrv-sdlc-chatgpt-discord-bot-secrets"
set OP_DISCORD_GPT_BOT_3_5_SECRET_PATH "$OP_DISCORD_GPT_BOT_ROOT_SECRET_PATH/chatgpt-discord-bot-secret-gpt-3.5-turbo"
set OP_DISCORD_GPT_BOT_4_SECRET_PATH "$OP_DISCORD_GPT_BOT_ROOT_SECRET_PATH/chatgpt-discord-bot-secret-gpt-4"

kubectl create secret generic -n chatgpt-discord-bot chatgpt-discord-bot-secret-gpt-3.5-turbo \
  --from-literal=DISCORD_TOKEN=(op read "$OP_DISCORD_GPT_BOT_3_5_SECRET_PATH/DISCORD_TOKEN") \
  --from-literal=OPENAI_API_KEY=(op read "$OP_DISCORD_GPT_BOT_3_5_SECRET_PATH/OPENAI_API_KEY")

kubectl create secret generic -n chatgpt-discord-bot chatgpt-discord-bot-secret-gpt-4 \
  --from-literal=DISCORD_TOKEN=(op read "$OP_DISCORD_GPT_BOT_4_SECRET_PATH/DISCORD_TOKEN") \
  --from-literal=OPENAI_API_KEY=(op read "$OP_DISCORD_GPT_BOT_4_SECRET_PATH/OPENAI_API_KEY")
