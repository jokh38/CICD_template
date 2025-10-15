import subprocess
import json
import asyncio
import sys
import os
from pathlib import Path
from typing import Optional, Dict, Any, List


class ClaudeCodeRunner:
    def __init__(self):
        self.context_file = Path(".github/claude/CLAUDE.md")
        self.max_retries = 3
        self.timeout = 300  # 5 minutes

    async def run_claude_command(self, prompt: str, options: Optional[Dict[str, Any]] = None) -> List[Dict[str, Any]]:
        """Execute Claude Code CLI in headless mode with proper error handling"""

        # Build base command
        cmd = [
            "claude-code",
            "-p",  # Headless mode
            "-",   # Read prompt from stdin
            "--output-format", "stream-json",
            "--max-turns", "1"
        ]

        # Add additional options
        if options:
            if options.get('add_dirs'):
                for dir in options['add_dirs']:
                    cmd.extend(['--add-dir', dir])

            if options.get('timeout'):
                self.timeout = options['timeout']

        # Build full prompt with context
        full_prompt = self._build_prompt_with_context(prompt)

        try:
            # Execute command with timeout
            process = await asyncio.wait_for(
                asyncio.create_subprocess_exec(
                    *cmd,
                    stdin=asyncio.subprocess.PIPE,
                    stdout=asyncio.subprocess.PIPE,
                    stderr=asyncio.subprocess.PIPE
                ),
                timeout=self.timeout
            )

            stdout, stderr = await process.communicate(input=full_prompt.encode())

            # Check for errors
            if process.returncode != 0:
                error_output = stderr.decode() if stderr else "Unknown error"
                raise RuntimeError(f"Claude Code CLI failed with return code {process.returncode}: {error_output}")

            # Parse JSON stream output
            results = self._parse_json_stream(stdout.decode())
            return results

        except asyncio.TimeoutError:
            raise RuntimeError(f"Claude Code CLI command timed out after {self.timeout} seconds")
        except FileNotFoundError:
            raise RuntimeError("Claude Code CLI not found. Please ensure it's installed and in PATH")

    def _build_prompt_with_context(self, prompt: str) -> str:
        """Build prompt with project context if available"""

        context_parts = [prompt]

        # Add project context if CLAUDE.md exists
        if self.context_file.exists():
            try:
                with open(self.context_file, 'r', encoding='utf-8') as f:
                    context_content = f.read().strip()
                if context_content:
                    context_parts.insert(0, f"PROJECT CONTEXT:\n{context_content}\n\nUSER REQUEST:")
            except Exception as e:
                print(f"Warning: Could not read context file {self.context_file}: {e}", file=sys.stderr)

        return '\n'.join(context_parts)

    def _parse_json_stream(self, output: str) -> List[Dict[str, Any]]:
        """Parse multiple JSON objects from stream output"""
        results = []

        for line_num, line in enumerate(output.split('\n'), 1):
            line = line.strip()
            if not line:
                continue

            try:
                parsed = json.loads(line)
                results.append(parsed)
            except json.JSONDecodeError as e:
                print(f"Warning: Failed to parse JSON on line {line_num}: {e}", file=sys.stderr)
                print(f"Line content: {line}", file=sys.stderr)
                continue

        return results


async def main():
    """Main entry point for the script"""
    import argparse

    parser = argparse.ArgumentParser(description="Run Claude Code CLI in automated environments")
    parser.add_argument("--task", required=True, help="Task description for Claude")
    parser.add_argument("--add-dir", action="append", help="Additional directories to include")
    parser.add_argument("--timeout", type=int, default=300, help="Timeout in seconds")
    parser.add_argument("--error-log", help="Path to error log file for context")
    parser.add_argument("--retry-count", type=int, default=0, help="Current retry attempt")

    args = parser.parse_args()

    # Prepare options
    options = {
        'timeout': args.timeout
    }

    if args.add_dir:
        options['add_dirs'] = args.add_dir

    # Build enhanced prompt
    prompt_parts = [args.task]

    if args.error_log:
        try:
            with open(args.error_log, 'r') as f:
                error_content = f.read()
            prompt_parts.append(f"\nERROR LOG TO FIX:\n{error_content}")
        except Exception as e:
            print(f"Warning: Could not read error log {args.error_log}: {e}", file=sys.stderr)

    if args.retry_count > 0:
        prompt_parts.append(f"\nRETRY ATTEMPT: {args.retry_count + 1}")

    prompt = '\n'.join(prompt_parts)

    # Run Claude Code
    runner = ClaudeCodeRunner()

    try:
        results = await runner.run_claude_command(prompt, options)

        if not results:
            print("No results returned from Claude Code CLI", file=sys.stderr)
            sys.exit(1)

        # Output results as JSON for GitHub Actions
        print(json.dumps({
            "success": True,
            "results": results,
            "retry_count": args.retry_count
        }))

    except Exception as e:
        print(json.dumps({
            "success": False,
            "error": str(e),
            "retry_count": args.retry_count
        }), file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())