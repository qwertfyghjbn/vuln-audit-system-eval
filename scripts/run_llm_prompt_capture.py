#!/usr/bin/env python3
import argparse
import json
import os
from pathlib import Path

from openai import OpenAI


def read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--system-prompt-file", required=True)
    parser.add_argument("--user-prompt-file", required=True)
    parser.add_argument("--output-dir", required=True)
    parser.add_argument("--expect-json", action="store_true")
    parser.add_argument("--temperature", type=float, default=0.0)
    parser.add_argument("--max-tokens", type=int, default=4096)
    parser.add_argument("--seed", type=int, default=345)
    args = parser.parse_args()

    system_prompt_path = Path(args.system_prompt_file)
    user_prompt_path = Path(args.user_prompt_file)
    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    system_prompt = read_text(system_prompt_path)
    user_prompt = read_text(user_prompt_path)
    messages = [
        {"role": "system", "content": system_prompt},
        {"role": "user", "content": user_prompt},
    ]

    client = OpenAI(
        api_key=os.environ["OPENAI_API_KEY"],
        base_url=os.environ.get("OPENAI_BASE_URL"),
    )
    model = os.environ.get("OPENAI_MODEL", "gpt-4-0125-preview")

    request = {
        "model": model,
        "messages": messages,
        "temperature": args.temperature,
        "max_tokens": args.max_tokens,
        "seed": args.seed,
    }
    if args.expect_json:
        request["response_format"] = {"type": "json_object"}

    response = client.chat.completions.create(**request)
    content = response.choices[0].message.content

    (output_dir / "system_prompt.txt").write_text(system_prompt, encoding="utf-8")
    (output_dir / "user_prompt.txt").write_text(user_prompt, encoding="utf-8")
    (output_dir / "request.json").write_text(
        json.dumps(request, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    (output_dir / "response.txt").write_text(content or "", encoding="utf-8")

    result = {
        "model": model,
        "expect_json": args.expect_json,
        "response_text_file": str(output_dir / "response.txt"),
        "parsed_ok": False,
    }
    if content:
        try:
            parsed = json.loads(content)
            (output_dir / "parsed_output.json").write_text(
                json.dumps(parsed, indent=2, ensure_ascii=False),
                encoding="utf-8",
            )
            result["parsed_ok"] = True
            result["parsed_output_file"] = str(output_dir / "parsed_output.json")
        except json.JSONDecodeError as exc:
            result["parse_error"] = str(exc)

    (output_dir / "run_meta.json").write_text(
        json.dumps(result, indent=2, ensure_ascii=False),
        encoding="utf-8",
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
