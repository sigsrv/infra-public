import asyncio
import os

import discord
import openai
from discord.ext import commands
from discord.utils import setup_logging
from openai.types.beta import Assistant
from openai.types.beta.threads import MessageContentText, Run, ThreadMessage
from openai.types.beta.threads.runs import CodeToolCall, ToolCallsStepDetails, RunStep
from openai.types.beta.threads.runs.code_tool_call import CodeInterpreterOutputLogs

openai = openai.AsyncClient(api_key=os.environ.get("OPENAI_API_KEY"))

bot = commands.Bot(
    command_prefix="!",
    intents=discord.Intents.default(),
)

message_chains = {}
assistant: Assistant


async def init():
    global assistant
    print(await openai.beta.assistants.list())

    assistant = await openai.beta.assistants.retrieve(
        assistant_id=os.environ.get("OPENAI_ASSISTANT_ID"),
    )


async def wait_for_run(run: Run):
    while run.status == "queued" or run.status == "in_progress":
        await asyncio.sleep(0.5)
        run = await openai.beta.threads.runs.retrieve(
            thread_id=run.thread_id,
            run_id=run.id,
        )

    return run


@bot.event
async def on_message(message: discord.Message):
    if message.author.bot:
        return

    if bot.user in message.mentions:
        text = message.content.rstrip()
        for prefix in commands.when_mentioned(bot, message):
            text = text.removeprefix(prefix).lstrip()

        thread_id = (
            message_chains.get(message.reference.message_id)
            if message.reference
            else None
        )
        if thread_id:
            thread = await openai.beta.threads.retrieve(thread_id)
        else:
            thread = await openai.beta.threads.create()

        message_chains[message.id] = thread.id
        async with message.channel.typing():
            await openai.beta.threads.messages.create(
                thread_id=thread.id,
                content=text,
                role="user",
            )

            run = await wait_for_run(
                await openai.beta.threads.runs.create(
                    thread_id=thread.id,
                    assistant_id=assistant.id,
                )
            )

            answer = []
            write = answer.append

            run_steps = await openai.beta.threads.runs.steps.list(
                thread_id=run.thread_id,
                run_id=run.id,
            )
            async for run_step in run_steps:  # type: RunStep
                if isinstance(run_step.step_details, ToolCallsStepDetails):
                    for tool_call in run_step.step_details.tool_calls:
                        if isinstance(tool_call, CodeToolCall):
                            code_interpreter = tool_call.code_interpreter
                            write("```python")
                            write(code_interpreter.input)
                            write("```")
                            for output in code_interpreter.outputs:
                                if isinstance(output, CodeInterpreterOutputLogs):
                                    if len(output.logs) > 64:
                                        write(f"→ {output.logs[:64]}...")
                                    else:
                                        write(f"→ {output.logs}")
                                else:
                                    raise NotImplementedError(
                                        f"Unknown output type {output}"
                                    )
                            write("")

            items = await openai.beta.threads.messages.list(
                thread_id=run.thread_id,
                limit=1,
            )
            async for item in items:  # type: ThreadMessage
                for content in item.content:
                    if isinstance(content, MessageContentText):
                        write(content.text.value)
                    else:
                        raise NotImplementedError(f"Unknown content type {content}")

            new_message = await message.reply("\n".join(answer))
            message_chains[new_message.id] = run.thread_id


async def close():
    for thread_id in set(message_chains.values()):
        await openai.beta.threads.delete(thread_id)

    await openai.beta.assistants.delete(assistant.id)
    await openai.close()


async def main():
    setup_logging()

    await init()
    try:
        await bot.start(os.environ["DISCORD_BOT_TOKEN"])
    finally:
        await close()


if __name__ == "__main__":
    asyncio.run(main())
