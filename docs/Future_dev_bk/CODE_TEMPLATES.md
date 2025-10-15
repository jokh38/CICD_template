# Code Templates and Examples

## Overview

This document contains code templates, examples, and patterns used throughout the AI automation system. These templates serve as building blocks for implementing various components and features.

## Python Code Templates

### Core Components

#### run_claude_code.py

```python
#!/usr/bin/env python3
"""
Claude Code CLI integration for GitHub Actions.

Main orchestrator for AI-powered workflow automation.
"""

import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Dict, List, Optional, Any

import asyncio
from context_manager import ContextManager
from parse_results import ErrorLogParser
from retry_handler import RetryHandler, RetryConfig
from validation import ValidationPipeline


class ClaudeCodeRunner:
    """Main class for running Claude Code operations"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.context_manager = ContextManager(project_root)
        self.error_parser = ErrorLogParser()
        self.retry_config = RetryConfig(max_attempts=3, base_delay=2.0)

    async def run_workflow(
        self,
        task_type: str,
        prompt: str,
        context: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """
        Run a Claude Code workflow.

        Args:
            task_type: Type of task (fix, review, implement)
            prompt: The prompt to send to Claude
            context: Additional context for the task

        Returns:
            Dictionary with results and metadata
        """
        try:
            # Load context
            full_context = await self._build_context(task_type, context)

            # Prepare prompt with context
            full_prompt = self._prepare_prompt(prompt, full_context)

            # Execute Claude Code with retry
            retry_handler = RetryHandler(self.retry_config)
            result = await retry_handler.execute_with_retry(
                self._execute_claude_code,
                full_prompt,
                task_type
            )

            # Parse and validate results
            parsed_result = self._parse_result(result)
            validation_result = await self._validate_changes(parsed_result)

            return {
                'success': validation_result['passed'],
                'result': parsed_result,
                'validation': validation_result,
                'context_used': full_context
            }

        except Exception as e:
            return {
                'success': False,
                'error': str(e),
                'context_used': full_context if 'full_context' in locals() else {}
            }

    async def _build_context(self, task_type: str, custom_context: Optional[Dict]) -> Dict:
        """Build full context for Claude Code"""
        context = {
            'project_root': str(self.project_root),
            'task_type': task_type,
            'claude_context': await self.context_manager.get_claude_context(),
            'git_context': await self.context_manager.get_git_context(),
            'recent_changes': await self.context_manager.get_recent_changes()
        }

        if custom_context:
            context.update(custom_context)

        return context

    def _prepare_prompt(self, user_prompt: str, context: Dict) -> str:
        """Prepare full prompt with context"""
        template = """
# Task Context
{context}

# User Request
{user_prompt}

# Instructions
1. Analyze the provided context carefully
2. Implement the requested changes
3. Follow the project's coding standards
4. Ensure all tests pass
5. Provide clear commit messages

# Output Format
Return your response in the following JSON format:
{
  "analysis": "Brief analysis of what needs to be done",
  "changes": [
    {
      "file": "path/to/file",
      "action": "create|modify|delete",
      "description": "Description of changes"
    }
  ],
  "commands": [
    {
      "command": "command to run",
      "description": "Description of command"
    }
  ],
  "validation": {
    "tests_to_run": ["list of test commands"],
    "checks_to_perform": ["list of validation checks"]
  }
}
"""
        return template.format(
            context=json.dumps(context, indent=2),
            user_prompt=user_prompt
        )

    async def _execute_claude_code(self, prompt: str, task_type: str) -> str:
        """Execute Claude Code CLI"""
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(prompt)
            prompt_file = f.name

        try:
            cmd = [
                'claude', '-p',  # headless mode
                '--output-format', 'stream-json',
                '--prompt-stdin',  # read prompt from stdin
            ]

            # Add task-specific parameters
            if task_type == 'fix':
                cmd.extend(['--fix', '--auto-apply'])
            elif task_type == 'review':
                cmd.extend(['--review', '--detailed'])

            process = await asyncio.create_subprocess_exec(
                *cmd,
                stdin=asyncio.subprocess.PIPE,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=self.project_root
            )

            # Send prompt via stdin
            with open(prompt_file, 'r') as f:
                prompt_content = f.read()

            stdout, stderr = await process.communicate(input=prompt_content.encode())

            if process.returncode != 0:
                raise RuntimeError(f"Claude Code failed: {stderr.decode()}")

            return stdout.decode()

        finally:
            os.unlink(prompt_file)

    def _parse_result(self, raw_result: str) -> Dict:
        """Parse Claude Code response"""
        try:
            # Parse streaming JSON responses
            lines = raw_result.strip().split('\n')
            results = []

            for line in lines:
                if line.strip():
                    try:
                        results.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue

            # Return the last complete result
            return results[-1] if results else {}

        except Exception as e:
            raise RuntimeError(f"Failed to parse Claude Code result: {e}")

    async def _validate_changes(self, result: Dict) -> Dict:
        """Validate the changes made by Claude Code"""
        language = self._detect_language()

        validation_pipeline = ValidationPipeline(self.project_root, language)

        # Get validation steps from result
        validation_steps = result.get('validation', {})

        # Run default validation if none specified
        if not validation_steps:
            passed = await validation_pipeline.run_all()
            return {
                'passed': passed,
                'pipeline_results': validation_pipeline.get_summary()
            }

        # Run specified validation
        # Implementation depends on validation format
        return await validation_pipeline.run_custom(validation_steps)

    def _detect_language(self) -> str:
        """Detect project language"""
        # Simple detection based on files
        if (self.project_root / 'pyproject.toml').exists():
            return 'python'
        elif (self.project_root / 'CMakeLists.txt').exists():
            return 'cpp'
        else:
            return 'unknown'


# Main execution
async def main():
    """Main entry point"""
    import argparse

    parser = argparse.ArgumentParser(description='Run Claude Code workflows')
    parser.add_argument('--task-type', required=True, choices=['fix', 'review', 'implement'])
    parser.add_argument('--prompt', required=True, help='Prompt for Claude')
    parser.add_argument('--context', help='Additional context (JSON)')
    parser.add_argument('--project-root', default='.', help='Project root directory')

    args = parser.parse_args()

    # Parse context if provided
    context = json.loads(args.context) if args.context else None

    # Create runner and execute
    runner = ClaudeCodeRunner(Path(args.project_root))
    result = await runner.run_workflow(args.task_type, args.prompt, context)

    # Output result
    print(json.dumps(result, indent=2))

    # Exit with appropriate code
    sys.exit(0 if result['success'] else 1)


if __name__ == '__main__':
    asyncio.run(main())
```

#### context_manager.py

```python
#!/usr/bin/env python3
"""
Context management for Claude Code operations.

Handles loading and managing project context, including CLAUDE.md,
git context, and MCP server integration.
"""

import json
import os
import subprocess
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime, timedelta


@dataclass
class GitContext:
    """Git repository context"""
    branch: str
    commit_hash: str
    author: str
    recent_commits: List[Dict]
    changed_files: List[str]
    uncommitted_changes: bool


class ContextManager:
    """Manages project context for Claude Code operations"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.claude_md_path = project_root / 'CLAUDE.md'
        self.github_context_path = Path(os.environ.get('GITHUB_CONTEXT_PATH', ''))

    async def get_claude_context(self) -> Dict[str, Any]:
        """Load context from CLAUDE.md"""
        if not self.claude_md_path.exists():
            return {}

        try:
            with open(self.claude_md_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Parse CLAUDE.md content
            return self._parse_claude_md(content)

        except Exception as e:
            print(f"Warning: Failed to load CLAUDE.md: {e}")
            return {}

    async def get_git_context(self) -> GitContext:
        """Get git repository context"""
        try:
            # Get current branch
            branch = subprocess.check_output(
                ['git', 'rev-parse', '--abbrev-ref', 'HEAD'],
                cwd=self.project_root,
                text=True
            ).strip()

            # Get current commit hash
            commit_hash = subprocess.check_output(
                ['git', 'rev-parse', 'HEAD'],
                cwd=self.project_root,
                text=True
            ).strip()

            # Get author of current commit
            author = subprocess.check_output(
                ['git', 'log', '-1', '--format=%an <%ae>'],
                cwd=self.project_root,
                text=True
            ).strip()

            # Get recent commits (last 10)
            recent_commits_raw = subprocess.check_output(
                ['git', 'log', '--oneline', '-10', '--format=%H|%s|%an|%ad'],
                cwd=self.project_root,
                text=True
            ).strip()

            recent_commits = []
            for line in recent_commits_raw.split('\n'):
                if line:
                    commit_hash, subject, author, date = line.split('|', 3)
                    recent_commits.append({
                        'hash': commit_hash,
                        'subject': subject,
                        'author': author,
                        'date': date
                    })

            # Get changed files in working directory
            changed_files_raw = subprocess.check_output(
                ['git', 'status', '--porcelain'],
                cwd=self.project_root,
                text=True
            ).strip()

            changed_files = []
            uncommitted_changes = False

            for line in changed_files_raw.split('\n'):
                if line:
                    status, file_path = line[:2], line[3:]
                    changed_files.append({
                        'file': file_path,
                        'status': status
                    })
                    if status != '  ':  # Not clean
                        uncommitted_changes = True

            return GitContext(
                branch=branch,
                commit_hash=commit_hash,
                author=author,
                recent_commits=recent_commits,
                changed_files=[f['file'] for f in changed_files],
                uncommitted_changes=uncommitted_changes
            )

        except subprocess.CalledProcessError as e:
            print(f"Warning: Failed to get git context: {e}")
            return GitContext(
                branch='unknown',
                commit_hash='unknown',
                author='unknown',
                recent_commits=[],
                changed_files=[],
                uncommitted_changes=False
            )

    async def get_recent_changes(self, hours: int = 24) -> List[Dict]:
        """Get recent changes within specified hours"""
        try:
            since_date = (datetime.now() - timedelta(hours=hours)).isoformat()

            commits_raw = subprocess.check_output(
                ['git', 'log', f'--since={since_date}', '--format=%H|%s|%an|%ad'],
                cwd=self.project_root,
                text=True
            ).strip()

            changes = []
            for line in commits_raw.split('\n'):
                if line:
                    commit_hash, subject, author, date = line.split('|', 3)

                    # Get files changed in this commit
                    files_raw = subprocess.check_output(
                        ['git', 'show', '--name-only', '--format=', commit_hash],
                        cwd=self.project_root,
                        text=True
                    ).strip()

                    changes.append({
                        'commit': commit_hash,
                        'subject': subject,
                        'author': author,
                        'date': date,
                        'files': files_raw.split('\n') if files_raw else []
                    })

            return changes

        except subprocess.CalledProcessError:
            return []

    async def get_github_context(self) -> Dict[str, Any]:
        """Get GitHub Actions context if available"""
        if not self.github_context_path.exists():
            return {}

        try:
            with open(self.github_context_path, 'r') as f:
                return json.load(f)
        except Exception:
            return {}

    def _parse_claude_md(self, content: str) -> Dict[str, Any]:
        """Parse CLAUDE.md content into structured context"""
        context = {
            'raw_content': content,
            'sections': {},
            'project_info': {},
            'guidelines': []
        }

        current_section = None
        lines = content.split('\n')

        for line in lines:
            line = line.strip()

            if line.startswith('# '):
                current_section = line[2:].lower()
                context['sections'][current_section] = []
            elif line.startswith('## '):
                subsection = line[3:].lower()
                if current_section:
                    if 'subsections' not in context['sections'][current_section]:
                        context['sections'][current_section]['subsections'] = {}
                    context['sections'][current_section]['subsections'][subsection] = []
            elif line.startswith('- ') or line.startswith('* '):
                item = line[2:]
                if current_section:
                    context['sections'][current_section].append(item)
            elif line and not line.startswith('#'):
                # Regular content line
                if current_section:
                    context['sections'][current_section].append(line)

        # Extract project-specific information
        if 'project context' in context['sections']:
            project_section = context['sections']['project context']
            for line in project_section:
                if ':' in line:
                    key, value = line.split(':', 1)
                    context['project_info'][key.strip().lower()] = value.strip()

        return context

    async def save_context_artifact(self, context: Dict, artifact_name: str = 'context'):
        """Save context as GitHub Actions artifact"""
        if not os.environ.get('GITHUB_OUTPUT'):
            return  # Not running in GitHub Actions

        artifact_path = Path(f'/tmp/{artifact_name}.json')
        with open(artifact_path, 'w') as f:
            json.dump(context, f, indent=2)

        print(f"::notice::Context saved to {artifact_path}")
        print(f"::set-output name=context-path::{artifact_path}")
```

### Error Handling and Retry Logic

#### retry_handler.py

```python
#!/usr/bin/env python3
"""
Retry logic with exponential backoff and intelligent failure handling.

Provides configurable retry strategies for AI operations.
"""

import asyncio
import time
from typing import Callable, Optional, Any
from dataclasses import dataclass
from enum import Enum


class RetryStrategy(Enum):
    """Retry strategies"""
    EXPONENTIAL_BACKOFF = "exponential"
    LINEAR_BACKOFF = "linear"
    CONSTANT = "constant"


@dataclass
class RetryConfig:
    """Configuration for retry behavior"""
    max_attempts: int = 3
    base_delay: float = 1.0  # seconds
    max_delay: float = 60.0
    strategy: RetryStrategy = RetryStrategy.EXPONENTIAL_BACKOFF
    retry_on_exceptions: tuple = (Exception,)


class RetryHandler:
    """Handle retries with various backoff strategies"""

    def __init__(self, config: Optional[RetryConfig] = None):
        self.config = config or RetryConfig()
        self.attempt_count = 0
        self.total_delay = 0.0

    async def execute_with_retry(
        self,
        func: Callable,
        *args,
        **kwargs
    ) -> Any:
        """
        Execute function with retry logic.

        Args:
            func: Async function to execute
            *args, **kwargs: Arguments to pass to func

        Returns:
            Result from successful execution

        Raises:
            Last exception if all retries fail
        """
        last_exception = None

        for attempt in range(1, self.config.max_attempts + 1):
            self.attempt_count = attempt

            try:
                result = await func(*args, **kwargs)
                if self._is_success(result):
                    return result
                else:
                    last_exception = Exception(f"Validation failed on attempt {attempt}")

            except self.config.retry_on_exceptions as e:
                last_exception = e
                print(f"Attempt {attempt} failed: {str(e)}")

            # Don't sleep after last attempt
            if attempt < self.config.max_attempts:
                delay = self._calculate_delay(attempt)
                print(f"Retrying in {delay:.2f} seconds...")
                await asyncio.sleep(delay)
                self.total_delay += delay

        # All retries exhausted
        raise last_exception or Exception("All retry attempts failed")

    def _calculate_delay(self, attempt: int) -> float:
        """Calculate delay based on retry strategy"""
        if self.config.strategy == RetryStrategy.EXPONENTIAL_BACKOFF:
            delay = self.config.base_delay * (2 ** (attempt - 1))
        elif self.config.strategy == RetryStrategy.LINEAR_BACKOFF:
            delay = self.config.base_delay * attempt
        else:  # CONSTANT
            delay = self.config.base_delay

        # Cap at max_delay
        return min(delay, self.config.max_delay)

    def _is_success(self, result: Any) -> bool:
        """Check if result indicates success"""
        if isinstance(result, dict):
            return result.get('success', False)
        return bool(result)

    def get_stats(self) -> dict:
        """Get retry statistics"""
        return {
            'total_attempts': self.attempt_count,
            'total_delay': self.total_delay,
            'average_delay': self.total_delay / max(1, self.attempt_count - 1)
        }


# Decorator for easy retry
def with_retry(config: Optional[RetryConfig] = None):
    """Decorator to add retry logic to async functions"""
    def decorator(func):
        async def wrapper(*args, **kwargs):
            handler = RetryHandler(config)
            return await handler.execute_with_retry(func, *args, **kwargs)
        return wrapper
    return decorator


# Usage example
@with_retry(RetryConfig(max_attempts=3, base_delay=2.0))
async def validate_fix(code_changes: dict) -> dict:
    """Validate code changes with retry"""
    # Run validation
    # Return {'success': True/False, 'errors': [...]}
    pass
```

## C++ Code Templates

### Build System Integration

#### CMakeLists.txt for AI Integration

```cmake
# CMakeLists.txt with AI workflow support
cmake_minimum_required(VERSION 3.20)
project(${PROJECT_NAME} VERSION 1.0.0 LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD ${CPP_STANDARD})
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Use sccache for compilation caching if available
find_program(SCCACHE_PROGRAM sccache)
if(SCCACHE_PROGRAM)
    message(STATUS "Using sccache for compilation caching")
    set(CMAKE_CXX_COMPILER_LAUNCHER ${SCCACHE_PROGRAM})
    set(CMAKE_C_COMPILER_LAUNCHER ${SCCACHE_PROGRAM})
endif()

# Compiler options
if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" OR CMAKE_CXX_COMPILER_ID STREQUAL "Clang")
    target_compile_options(${PROJECT_NAME} PRIVATE
        -Wall
        -Wextra
        -Wpedantic
        $<$<CONFIG:Debug>:-g -O0>
        $<$<CONFIG:Release>:-O3 -DNDEBUG>
    )
endif()

# Find dependencies
find_package(PkgConfig REQUIRED)
pkg_check_modules(${PROJECT_NAME}_DEPS REQUIRED fmt)

# Add executable
add_executable(${PROJECT_NAME}
    src/main.cpp
    src/utils.cpp
)

# Link libraries
target_link_libraries(${PROJECT_NAME}
    PRIVATE
    ${PROJECT_NAME}_DEPS_LIBRARIES}
)

# Include directories
target_include_directories(${PROJECT_NAME}
    PRIVATE
    ${PROJECT_NAME}_DEPS_INCLUDE_DIRS}
)

# Add tests
option(BUILD_TESTS "Build tests" ON)
if(BUILD_TESTS)
    enable_testing()

    # Find GoogleTest
    find_package(GTest REQUIRED)

    # Add test executable
    add_executable(${PROJECT_NAME}_tests
        tests/test_main.cpp
        tests/test_utils.cpp
    )

    target_link_libraries(${PROJECT_NAME}_tests
        PRIVATE
        GTest::gtest
        GTest::gtest_main
        ${PROJECT_NAME}
    )

    # Register tests
    add_test(NAME ${PROJECT_NAME}_unit_tests COMMAND ${PROJECT_NAME}_tests)
endif()

# Install targets
install(TARGETS ${PROJECT_NAME}
    RUNTIME DESTINATION bin
)

# Add clang-format target
find_program(CLANG_FORMAT_PROGRAM clang-format)
if(CLANG_FORMAT_PROGRAM)
    add_custom_target(clang-format
        COMMAND ${CLANG_FORMAT_PROGRAM} -i src/**/*.cpp include/**/*.hpp
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Formatting code with clang-format"
    )
endif()

# Add clang-tidy target
find_program(CLANG_TIDY_PROGRAM clang-tidy)
if(CLANG_TIDY_PROGRAM)
    add_custom_target(clang-tidy
        COMMAND ${CLANG_TIDY_PROGRAM} src/**/*.cpp
        WORKING_DIRECTORY ${CMAKE_CURRENT_SOURCE_DIR}
        COMMENT "Running clang-tidy"
    )
endif()
```

## GitHub Actions Templates

### Composite Action Template

```yaml
# .github/actions/claude-code-runner/action.yaml
name: 'Claude Code Runner'
description: 'Run Claude Code CLI for AI-powered workflow automation'
author: 'Claude Code AI'

inputs:
  task-type:
    description: 'Type of task to perform'
    required: true
    choices:
      - fix
      - review
      - implement
  prompt:
    description: 'Prompt for Claude Code'
    required: true
  context:
    description: 'Additional context (JSON)'
    required: false
    default: '{}'
  project-root:
    description: 'Project root directory'
    required: false
    default: '.'
  claude-api-key:
    description: 'Anthropic API key'
    required: true

outputs:
  success:
    description: 'Whether the operation was successful'
  result:
    description: 'Result from Claude Code'
  validation:
    description: 'Validation results'
  error:
    description: 'Error message if failed'

runs:
  using: 'composite'
  steps:
    - name: Set up Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install dependencies
      shell: bash
      run: |
        python -m pip install --upgrade pip
        pip install -r ${{ github.action_path }}/requirements.txt

    - name: Install Claude Code CLI
      shell: bash
      run: |
        curl -fsSL https://claude.ai/install.sh | sh

    - name: Configure Claude Code
      shell: bash
      env:
        ANTHROPIC_API_KEY: ${{ inputs.claude-api-key }}
      run: |
        claude auth login

    - name: Run Claude Code
      id: run-claude
      shell: bash
      env:
        ANTHROPIC_API_KEY: ${{ inputs.claude-api-key }}
        GITHUB_CONTEXT_PATH: ${{ github.event_path }}
      run: |
        python ${{ github.action_path }}/scripts/run_claude_code.py \
          --task-type "${{ inputs.task-type }}" \
          --prompt "${{ inputs.prompt }}" \
          --context "${{ inputs.context }}" \
          --project-root "${{ inputs.project-root }}" \
          > result.json

        # Extract results for outputs
        success=$(jq -r '.success' result.json)
        echo "success=$success" >> $GITHUB_OUTPUT

        if [ "$success" = "true" ]; then
          result=$(jq -c '.result' result.json)
          echo "result=$result" >> $GITHUB_OUTPUT

          validation=$(jq -c '.validation' result.json)
          echo "validation=$validation" >> $GITHUB_OUTPUT
        else
          error=$(jq -r '.error // "Unknown error"' result.json)
          echo "error=$error" >> $GITHUB_OUTPUT
          echo "::error::$error"
          exit 1
        fi

    - name: Upload context artifact
      if: always()
      uses: actions/upload-artifact@v4
      with:
        name: claude-context-${{ github.run_id }}
        path: |
          result.json
          context-*.json
        retention-days: 7
```

### Workflow Templates

#### PR Automation Workflow

```yaml
# .github/workflows/ai-workflow.yaml
name: AI Workflow Automation

on:
  issues:
    types: [labeled]
  issue_comment:
    types: [created]
  workflow_dispatch:
    inputs:
      issue-number:
        description: 'Issue number to process'
        required: true
        type: number
      task-type:
        description: 'Type of task'
        required: true
        default: 'implement'
        type: choice
        options:
          - implement
          - fix
          - review

permissions:
  contents: write
  issues: write
  pull-requests: write

jobs:
  process-issue:
    if: |
      (github.event.action == 'labeled' && contains(github.event.label.name, 'ai-assist')) ||
      (github.event.action == 'created' && contains(github.event.comment.body, '@claude')) ||
      github.event_name == 'workflow_dispatch'
    runs-on: ubuntu-latest

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          token: ${{ secrets.GITHUB_TOKEN }}

      - name: Get issue details
        id: issue
        uses: actions/github-script@v7
        with:
          script: |
            let issueNumber;
            if (context.eventName === 'workflow_dispatch') {
              issueNumber = context.payload.inputs.issue_number;
            } else {
              issueNumber = context.payload.issue.number;
            }

            const issue = await github.rest.issues.get({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: issueNumber
            });

            // Extract task type from input or detect from issue
            let taskType = context.payload.inputs?.task_type || 'implement';
            if (context.eventName === 'issue_comment' || context.eventName === 'issues') {
              const body = context.payload.issue.body || context.payload.comment.body;
              if (body.includes('fix') || body.includes('bug')) {
                taskType = 'fix';
              } else if (body.includes('review')) {
                taskType = 'review';
              }
            }

            core.setOutput('number', issueNumber);
            core.setOutput('title', issue.data.title);
            core.setOutput('body', issue.data.body);
            core.setOutput('task-type', taskType);

      - name: Create feature branch
        id: branch
        run: |
          BRANCH_NAME="ai/issue-${{ steps.issue.outputs.number }}"
          git config --global user.name "github-actions[bot]"
          git config --global user.email "github-actions[bot]@users.noreply.github.com"
          git checkout -b $BRANCH_NAME
          echo "branch=$BRANCH_NAME" >> $GITHUB_OUTPUT

      - name: Run Claude Code
        id: claude
        uses: ./.github/actions/claude-code-runner
        with:
          task-type: ${{ steps.issue.outputs.task-type }}
          prompt: |
            Issue Title: ${{ steps.issue.outputs.title }}
            Issue Body: ${{ steps.issue.outputs.body }}

            Please implement the requested changes based on the issue description.
          claude-api-key: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Commit and push changes
        if: steps.claude.outputs.success == 'true'
        run: |
          git add .
          git commit -m "$(cat <<EOF
          AI-generated changes for issue #${{ steps.issue.outputs.number }}

          ${{ steps.issue.outputs.title }}

          🤖 Generated with Claude Code
          Co-Authored-By: Claude <noreply@anthropic.com>
          EOF
          )"
          git push origin ${{ steps.branch.outputs.branch }}

      - name: Create pull request
        if: steps.claude.outputs.success == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            const result = await github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `AI: ${{ steps.issue.outputs.title }}`,
              head: '${{ steps.branch.outputs.branch }}',
              base: 'main',
              body: `## AI-Generated Changes

              This PR was automatically generated by Claude Code AI based on issue #${{ steps.issue.outputs.number }}.

              **Issue**: ${{ steps.issue.outputs.title }}

              **Changes made**:
              ${{ steps.claude.outputs.result }}

              **Validation**: ${{ steps.claude.outputs.validation }}

              ---

              🤖 Generated with [Claude Code](https://claude.com/claude-code)
              `,
              draft: false
            });

            // Add ai-review label
            await github.rest.issues.addLabels({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: result.data.number,
              labels: ['ai-generated', 'ai-review']
            });

      - name: Comment on issue
        if: always()
        uses: actions/github-script@v7
        with:
          script: |
            let comment;
            if ('${{ steps.claude.outputs.success }}' === 'true') {
              comment = `## ✅ AI Processing Complete

              I've analyzed your issue and created a pull request with the requested changes.

              **PR**: #${{ steps.branch.outputs.branch }} (will be available shortly)
              **Branch**: `${{ steps.branch.outputs.branch }}`

              The changes are currently being validated and will be ready for review shortly.

              ---

              🤖 Processed by Claude Code AI`;
            } else {
              comment = `## ❌ AI Processing Failed

              I encountered an error while processing your issue:

              **Error**: ${{ steps.claude.outputs.error }}

              Please check the issue description and try again, or address the error manually.

              ---

              🤖 Processed by Claude Code AI`;
            }

            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: ${{ steps.issue.outputs.number }},
              body: comment
            });
```

## Prompt Templates

### Python Fix Template

```markdown
# Python Project Fix Template

## Project Context
- **Language**: Python 3.11
- **Package Manager**: pip/poetry (check for pyproject.toml)
- **Formatter**: black
- **Linter**: ruff
- **Type Checker**: mypy
- **Test Framework**: pytest

## Common Python Issues

### Import Errors
- Missing dependencies: Install with `pip install`
- Relative imports: Fix import paths
- Circular imports: Reorganize code structure

### Type Errors
- Missing type hints: Add annotations
- Incorrect types: Fix annotations
- Optional types: Use `Optional[T]`

### Test Failures (pytest)
- AssertionError: Fix logic or expected values
- Fixtures not found: Define fixtures
- Import errors in tests: Fix test imports

## Fix Approach

1. **Parse Error**: Extract file, line, error type
2. **Review Code**: Understand the context
3. **Apply Fix**: Minimal, targeted change
4. **Validate**: Run `ruff check`, `mypy`, `pytest`

## Code Style
- Follow PEP 8
- Use type hints everywhere
- Prefer f-strings for formatting
- Use pathlib for file paths
- Use context managers (with statements)

## Example Fixes

### Unused Import
```python
# Before
import os
import sys

# After (if os not used)
import sys
```

### Type Hint Missing
```python
# Before
def calculate(x, y):
    return x + y

# After
def calculate(x: int, y: int) -> int:
    return x + y
```

### Test Fix
```python
# Before
assert result == 42  # Fails with result=43

# After (if logic was wrong)
assert result == 43  # Fixed expected value
```

## Validation Commands
```bash
# Format check
ruff format --check .

# Linting
ruff check .

# Type checking
mypy src/

# Run tests
pytest --tb=short
```

## Instructions
1. Analyze the error carefully
2. Understand the root cause
3. Apply the minimal fix needed
4. Ensure all validation passes
5. Provide clear explanation of changes
```

### C++ Fix Template

```markdown
# C++ Project Fix Template

## Project Context
- **Standard**: C++${CPP_STANDARD}
- **Build System**: CMake + Ninja
- **Compiler Cache**: sccache
- **Formatter**: clang-format
- **Linter**: clang-tidy
- **Test Framework**: GoogleTest / Catch2 / doctest

## Common C++ Issues

### Compilation Errors
- Missing includes: Add `#include`
- Undefined references: Link libraries
- Template errors: Check instantiation
- Type mismatches: Cast or fix types

### Linker Errors
- Undefined symbol: Implement function or link library
- Multiple definitions: Use inline or anonymous namespace
- Library not found: Update CMakeLists.txt

### clang-tidy Warnings
- Modernize: Use modern C++ features
- Readability: Improve naming and structure
- Performance: Fix inefficiencies
- Safety: Fix potential bugs

### Test Failures (GoogleTest)
- ASSERT failures: Fix logic or expected value
- Segfaults: Check pointers and memory
- Timeouts: Optimize or increase limit

## Fix Approach

1. **Parse Error**: Extract file, line, error type
2. **Review Code**: Understand the context
3. **Apply Fix**: Minimal, targeted change
4. **Rebuild**:
   ```bash
   cmake --build build
   ctest --test-dir build
   ```

## Code Style
- Follow clang-format configuration
- Use RAII for resource management
- Prefer `std::unique_ptr` over raw pointers
- Use `const` wherever possible
- Prefer `enum class` over `enum`
- Use `auto` for complex types

## Example Fixes

### Missing Include
```cpp
// Before
std::vector<int> vec;  // Error: no 'vector' in namespace 'std'

// After
#include <vector>
std::vector<int> vec;
```

### Clang-tidy: Use auto
```cpp
// Before
std::vector<int>::iterator it = vec.begin();

// After
auto it = vec.begin();
```

### Test Fix
```cpp
// Before
EXPECT_EQ(result, 42);  // Fails with result=43

// After (if logic was correct, test was wrong)
EXPECT_EQ(result, 43);
```

### Memory Safety
```cpp
// Before
int* ptr = new int(42);
// ... (no delete, memory leak)

// After
auto ptr = std::make_unique<int>(42);
// Automatically freed
```

## Validation Commands
```bash
# Format check
clang-format --dry-run -Werror src/**/*.cpp

# Linting
clang-tidy src/**/*.cpp

# Build
cmake --build build

# Run tests
ctest --test-dir build --output-on-failure
```

## Instructions
1. Analyze the compilation/linker error
2. Identify the root cause
3. Apply the minimal fix
4. Ensure code compiles and tests pass
5. Follow C++ best practices
```

---

*Document Version*: 1.0
*Last Updated*: 2025-10-15