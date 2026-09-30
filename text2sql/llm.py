import json
from typing import Type, TypeVar
from openai import OpenAI
from pydantic import BaseModel, ValidationError
from . import config

T = TypeVar("T", bound=BaseModel)
_client = None


def client() -> OpenAI:
    """One shared client, built from .env (LLM_PROVIDER / LLM_API_KEY / LLM_MODEL)."""
    global _client
    if _client is None:
        if not config.API_KEY:
            raise RuntimeError("LLM_API_KEY is not set. Put it in .env (see .env.example).")
        _client = OpenAI(api_key=config.API_KEY, base_url=config.BASE_URL,
                         max_retries=8)  # waits and retries on 429 rate limits
    return _client


def structured(system: str, user: str, model_cls: Type[T], retries: int = 2) -> T:
    """Call the LLM in JSON mode and validate against a Pydantic model.
    On validation failure, feed the error back and retry."""
    messages = [
        {"role": "system", "content": system + "\n\nReturn ONLY a JSON object matching:\n"
         + json.dumps(model_cls.model_json_schema())},
        {"role": "user", "content": user},
    ]
    last_err = None
    for _ in range(retries + 1):
        resp = client().chat.completions.create(
            model=config.MODEL, messages=messages, temperature=0,
            response_format={"type": "json_object"},
        )
        raw = resp.choices[0].message.content or ""
        try:
            return model_cls.model_validate_json(raw)
        except ValidationError as e:
            last_err = e
            messages += [
                {"role": "assistant", "content": raw},
                {"role": "user", "content": f"Invalid output: {e}. Return corrected JSON only."},
            ]
    raise RuntimeError(f"LLM output failed validation: {last_err}")
