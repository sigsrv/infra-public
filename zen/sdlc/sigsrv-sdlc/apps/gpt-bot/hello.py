#!/usr/bin/env python

from typing import ContextManager
from httpx import delete
import openai
import warnings
from contextlib import contextmanager
from typing import TypeVar, ContextManager

from openai.types.beta.assistant import Assistant
from openai.types.beta.thread import Thread
import time

from openai.types.beta.threads.runs import ToolCallsStepDetails
from openai.types.beta.threads.runs.code_tool_call import (
    CodeInterpreterOutputLogs,
    CodeToolCall,
)

client = openai.OpenAI()


@contextmanager
def forget(obj):
    assert isinstance(obj, (Assistant, Thread))

    try:
        yield obj
    finally:
        if isinstance(obj, Assistant):
            client.beta.assistants.delete(obj.id)
        elif isinstance(obj, Thread):
            client.beta.threads.delete(obj.id)
        else:
            warnings.warn(f"Unknown object type {type(obj)}")


with forget(
    client.beta.assistants.create(
        name="GPT Discord Bot",
        description="A bot that generates messages based on the conversation so far.",
        model="gpt-4-1106-preview",
        tools=[{"type": "code_interpreter"}],
    )
) as assistant:
    with forget(client.beta.threads.create()) as thread:
        client.beta.threads.messages.create(
            thread_id=thread.id,
            content=input("Q:"),
            role="user",
        )

        run = client.beta.threads.runs.create(
            thread_id=thread.id,
            assistant_id=assistant.id,
        )

        while run.status == "queued" or run.status == "in_progress":
            time.sleep(0.1)
            run = client.beta.threads.runs.retrieve(
                thread_id=thread.id,
                run_id=run.id,
            )

        run_steps = client.beta.threads.runs.steps.list(
            thread_id=thread.id,
            run_id=run.id,
        )
        for run_step in run_steps:
            if isinstance(run_step.step_details, ToolCallsStepDetails):
                for tool_call in run_step.step_details.tool_calls:
                    if isinstance(tool_call, CodeToolCall):
                        code_interpreter = tool_call.code_interpreter
                        print("input:")
                        print(code_interpreter.input)
                        print()
                        print("outputs:")
                        for output in code_interpreter.outputs:
                            if isinstance(output, CodeInterpreterOutputLogs):
                                print(output.logs)
                            else:
                                raise NotImplementedError(
                                    f"Unknown output type {output}"
                                )
                        print()

        messages = client.beta.threads.messages.list(
            thread_id=thread.id,
        )
        for message in messages:
            for content in message.content:
                print(content.text.value)
