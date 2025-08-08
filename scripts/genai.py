#!/usr/bin/env python3

import sys
import json
import os
import requests

TIMEOUT = 30


def main():
    user_input = sys.stdin.read()

    model = os.getenv("GENAI_MODEL")
    if not model:
        raise SystemExit("No GENAI_MODEL specified")

    api_url = os.getenv("GENAI_API_URL")
    if not api_url:
        raise SystemExit("No GENAI_API_URL specified")

    if len(sys.argv) > 1:
        user_input = sys.argv[1] + " " + user_input

    headers = {
        "Content-Type": "application/json",
    }

    payload = {
        "model": model,
        "messages": [{"role": "user", "content": user_input.strip()}],
    }

    try:
        response = requests.post(
            api_url, headers=headers, json=payload, timeout=TIMEOUT
        )
    except requests.exceptions.RequestException as e:
        raise SystemExit(e)

    if not response.ok:
        raise SystemExit(f"Error {response.status_code}: {response.text}")

    try:
        result = response.json()
        content = result["choices"][0]["message"]["content"]
        print(content)
    except (json.JSONDecodeError, KeyError) as e:
        raise SystemExit(e)


if __name__ == "__main__":
    main()
