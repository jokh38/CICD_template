#!/usr/bin/env python3
"""
Parse and process Claude Code CLI results for GitHub Actions workflows.
"""

import json
import sys
import re
from pathlib import Path
from typing import Dict, Any, List, Optional


class ResultParser:
    def __init__(self):
        self.changes_detected = []
        self.files_modified = []
        self.commands_suggested = []
        self.errors_found = []

    def parse_claude_results(self, results: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Parse Claude Code CLI results and extract actionable information"""

        parsed = {
            "has_changes": False,
            "files_to_modify": [],
            "commands_to_run": [],
            "errors_to_fix": [],
            "summary": "",
            "raw_results": results
        }

        for result in results:
            # Extract tool usage information
            if "tool_use" in result:
                tool_info = result["tool_use"]

                if tool_info.get("name") == "Write":
                    self._handle_write_operation(tool_info, parsed)
                elif tool_info.get("name") == "Edit":
                    self._handle_edit_operation(tool_info, parsed)
                elif tool_info.get("name") == "Bash":
                    self._handle_bash_operation(tool_info, parsed)
                elif tool_info.get("name") == "Read":
                    self._handle_read_operation(tool_info, parsed)

            # Extract text content for summary
            if "text" in result:
                self._extract_text_content(result["text"], parsed)

        # Determine if changes are needed
        parsed["has_changes"] = bool(
            parsed["files_to_modify"] or
            parsed["commands_to_run"] or
            parsed["errors_to_fix"]
        )

        return parsed

    def _handle_write_operation(self, tool_info: Dict[str, Any], parsed: Dict[str, Any]):
        """Handle Write tool operations"""
        input_data = tool_info.get("input", {})
        file_path = input_data.get("file_path")

        if file_path:
            parsed["files_to_modify"].append({
                "action": "create",
                "path": file_path,
                "operation": "write"
            })

    def _handle_edit_operation(self, tool_info: Dict[str, Any], parsed: Dict[str, Any]):
        """Handle Edit tool operations"""
        input_data = tool_info.get("input", {})
        file_path = input_data.get("file_path")

        if file_path:
            parsed["files_to_modify"].append({
                "action": "modify",
                "path": file_path,
                "operation": "edit"
            })

    def _handle_bash_operation(self, tool_info: Dict[str, Any], parsed: Dict[str, Any]):
        """Handle Bash tool operations"""
        input_data = tool_info.get("input", {})
        command = input_data.get("command")

        if command:
            parsed["commands_to_run"].append({
                "command": command,
                "description": input_data.get("description", "")
            })

    def _handle_read_operation(self, tool_info: Dict[str, Any], parsed: Dict[str, Any]):
        """Handle Read tool operations"""
        input_data = tool_info.get("input", {})
        file_path = input_data.get("file_path")

        # Read operations don't require action, but we can track them for context
        pass

    def _extract_text_content(self, text: str, parsed: Dict[str, Any]):
        """Extract relevant information from text content"""
        lines = text.split('\n')

        # Look for specific patterns in the text
        for line in lines:
            # Error messages
            if any(keyword in line.lower() for keyword in ['error:', 'failed:', 'exception:']):
                self.errors_found.append(line.strip())

            # File operations mentioned in text
            file_match = re.search(r'(\w+)\s+file\s+([^\s]+)', line, re.IGNORECASE)
            if file_match:
                action, path = file_match.groups()
                parsed["files_to_modify"].append({
                    "action": action.lower(),
                    "path": path,
                    "operation": "mentioned"
                })

        # Build summary from text
        if len(text.strip()) > 100:
            parsed["summary"] = text.strip()[:500] + "..." if len(text.strip()) > 500 else text.strip()

    def generate_github_actions_output(self, parsed: Dict[str, Any]) -> str:
        """Generate GitHub Actions compatible output"""

        output = {
            "metadata": {
                "changes_detected": parsed["has_changes"],
                "files_count": len(parsed["files_to_modify"]),
                "commands_count": len(parsed["commands_to_run"]),
                "errors_count": len(parsed["errors_to_fix"])
            },
            "actions": {
                "files": parsed["files_to_modify"],
                "commands": parsed["commands_to_run"],
                "errors": parsed["errors_to_fix"]
            },
            "summary": parsed["summary"]
        }

        return json.dumps(output, indent=2)


def main():
    """Main entry point"""
    if len(sys.argv) != 2:
        print("Usage: python parse_results.py <results_json_file>", file=sys.stderr)
        sys.exit(1)

    results_file = Path(sys.argv[1])

    if not results_file.exists():
        print(f"Error: Results file {results_file} not found", file=sys.stderr)
        sys.exit(1)

    try:
        # Load results
        with open(results_file, 'r') as f:
            results_data = json.load(f)

        # Extract results array
        results = results_data.get("results", [])
        if isinstance(results, dict):
            results = [results]

        # Parse results
        parser = ResultParser()
        parsed = parser.parse_claude_results(results)

        # Generate and output GitHub Actions format
        github_output = parser.generate_github_actions_output(parsed)
        print(github_output)

        # Set exit code based on whether changes are needed
        sys.exit(0 if parsed["has_changes"] else 0)

    except Exception as e:
        print(f"Error parsing results: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()