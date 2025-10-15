# DEV_PLAN.md - Claude Code AI Workflow Automation Implementation

## Executive Summary

This document outlines a comprehensive step-wise plan to transform the current CICD_template project into an AI-powered workflow automation system using Claude Code CLI. The plan implements the vision described in `docs/Future_dev/plan.md` while building upon the existing Cookiecutter-based CI/CD template infrastructure.

### Current State
- **Foundation**: Cookiecutter templates for Python and C++ projects with CI/CD workflows
- **CI/CD**: Reusable GitHub Actions workflows with caching and performance optimization
- **Tooling**: Integrated ruff (Python), sccache (C++), pre-commit hooks
- **AI Integration**: Basic placeholder AI workflow with @claude mentions

### Target State
- **Intelligent Automation**: Full Claude Code CLI integration for automated issue resolution, PR reviews, and CI/CD failure recovery
- **Context-Aware**: Persistent project context via CLAUDE.md and MCP servers
- **Feedback Loops**: Automated validation and self-correction cycles
- **Production-Ready**: Comprehensive error handling, security, and monitoring

---

## Architecture Overview

### Phase Alignment with plan.md

| plan.md Phase | Implementation Phase | Timeline | Status |
|:--------------|:--------------------|:---------|:-------|
| Phase 1: 기본 인프라 구축 | Phase 1-2 | Week 1 | Planned |
| Phase 2: 자동화 워크플로우 구현 | Phase 3-4 | Week 2-3 | Planned |
| Phase 3: 피드백 루프 최적화 | Phase 5 | Week 4 | Planned |
| Phase 4: 고급 기능 추가 | Phase 6-7 | Week 5-6 | Planned |

### Key Technical Decisions

1. **Claude Code CLI Integration**: Use headless mode (`-p` flag) with `--output-format stream-json` for structured responses
2. **Prompt Delivery**: Use `--prompt-stdin` or stdin piping for long prompts to avoid shell argument limitations
3. **State Management**: Combine GitHub Actions artifacts with CLAUDE.md for persistent context
4. **Security**: Implement strict permissions model and secret management
5. **Validation**: Multi-layer validation with pre-commit hooks, CI checks, and AI-driven correction loops

---

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
```

**File**: `.github/claude/prompts/templates/cpp_fix.md`

```markdown
# C++ Project Fix Template

## Project Context
- **Standard**: C++$CPP_STANDARD
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
```

**Implementation Steps**:
1. Create language-specific fix templates
2. Document common error patterns
3. Provide fix examples
4. Add validation commands
5. Include code style guidelines

**Deliverables**:
- [ ] Python fix template
- [ ] C++ fix template
- [ ] Error pattern documentation
- [ ] Fix examples library

### 4.3 Subagent System Prompt

**Task**: Create system prompt for specialized sub-agents

**File**: `.github/claude/prompts/subagent_systemprompt.txt`

```
You are a specialized AI coding agent operating within a CI/CD automation system.

ROLE: CI/CD Debugger and Fix Agent

CAPABILITIES:
- Analyze CI/CD pipeline failures
- Parse error logs and identify root causes
- Implement fixes for common issues (test failures, linting, type errors, build errors)
- Validate fixes before committing
- Generate clear commit messages

CONSTRAINTS:
- Only fix issues directly related to CI failures
- Do not add new features or refactor unless explicitly required for the fix
- Maintain backward compatibility
- Follow project coding standards strictly
- Keep changes minimal and focused

WORKFLOW:
1. Receive error log and context
2. Classify error type
3. Analyze root cause
4. Propose minimal fix
5. Implement fix
6. Validate locally
7. Report results

OUTPUT FORMAT:
{
  "analysis": "Description of the problem",
  "error_type": "test-failure | lint-error | type-error | build-error",
  "root_cause": "Specific reason for failure",
  "fix_applied": "Description of changes made",
  "files_modified": ["file1.py", "file2.cpp"],
  "validation_results": {
    "tests_passed": true,
    "linter_passed": true,
    "build_passed": true
  },
  "commit_message": "Concise commit message"
}

EXAMPLES:

Input: "pytest failed: AssertionError: assert 42 == 43"
Analysis: Test expected value doesn't match actual result
Fix: Update test assertion from 42 to 43
Validation: pytest passes

Input: "ruff: F401 'os' imported but unused"
Analysis: Unused import
Fix: Remove import os line
Validation: ruff check passes

REMEMBER:
- Precision over speed
- Minimal changes
- Always validate
- Clear documentation
```

**Implementation Steps**:
1. Define sub-agent role and responsibilities
2. Specify input/output formats
3. Add examples of common scenarios
4. Document constraints and guidelines

**Deliverables**:
- [ ] Subagent system prompt
- [ ] Output format specification
- [ ] Example scenarios

---

## Phase 5: Validation and Feedback Loop (Week 3, Days 1-3)

### Objective
Implement robust validation mechanisms and intelligent retry logic.

### 5.1 Enhanced Error Parsing

**Task**: Create sophisticated error log parser

**File**: `.github/actions/claude-code-runner/scripts/parse_results.py`

```python
"""
Error log parsing and classification module.

Parses CI/CD error logs and extracts actionable information.
"""

import re
from typing import Dict, List, Optional
from dataclasses import dataclass
from enum import Enum


class ErrorType(Enum):
    """Classification of error types"""
    TEST_FAILURE = "test-failure"
    LINT_ERROR = "lint-error"
    TYPE_ERROR = "type-error"
    BUILD_ERROR = "build-error"
    IMPORT_ERROR = "import-error"
    RUNTIME_ERROR = "runtime-error"
    UNKNOWN = "unknown"


@dataclass
class ParsedError:
    """Structured error information"""
    error_type: ErrorType
    file_path: Optional[str]
    line_number: Optional[int]
    error_message: str
    context: str
    suggestion: Optional[str] = None


class ErrorLogParser:
    """Parse and classify error logs from CI/CD pipelines"""

    # Regex patterns for different error types
    PATTERNS = {
        ErrorType.TEST_FAILURE: [
            r'(FAILED|ERROR|AssertionError)\s+(.+?):(\d+)',
            r'pytest.*?FAILED.*?::(.+)',
            r'EXPECT_\w+.*?failed.*?at (.+?):(\d+)',
        ],
        ErrorType.LINT_ERROR: [
            r'(.+?):(\d+):(\d+):\s+(E\d+|F\d+|W\d+)',  # Ruff/Flake8
            r'(.+?):(\d+):(\d+):\s+error:',  # clang-tidy
        ],
        ErrorType.TYPE_ERROR: [
            r'(.+?):(\d+):\s+error:.*?\[.*?\]',  # mypy
        ],
        ErrorType.BUILD_ERROR: [
            r'(.+?):(\d+):(\d+):\s+(fatal\s+)?error:',  # Compiler
            r'CMake Error at (.+?):(\d+)',
        ],
        ErrorType.IMPORT_ERROR: [
            r'ImportError:\s+(.+)',
            r'ModuleNotFoundError:\s+No module named ["\'](.+?)["\']',
        ],
    }

    def parse(self, error_log: str) -> List[ParsedError]:
        """
        Parse error log and extract structured errors.

        Args:
            error_log: Raw error log text

        Returns:
            List of parsed errors
        """
        errors = []

        for error_type, patterns in self.PATTERNS.items():
            for pattern in patterns:
                matches = re.finditer(pattern, error_log, re.MULTILINE)
                for match in matches:
                    error = self._create_error(error_type, match, error_log)
                    if error:
                        errors.append(error)

        # If no specific errors found, create generic error
        if not errors:
            errors.append(ParsedError(
                error_type=ErrorType.UNKNOWN,
                file_path=None,
                line_number=None,
                error_message=error_log[:500],  # First 500 chars
                context=error_log
            ))

        return errors

    def _create_error(
        self,
        error_type: ErrorType,
        match: re.Match,
        full_log: str
    ) -> Optional[ParsedError]:
        """Create ParsedError from regex match"""
        groups = match.groups()

        # Extract file path and line number based on match groups
        file_path = groups[0] if len(groups) > 0 else None
        line_number = int(groups[1]) if len(groups) > 1 and groups[1].isdigit() else None

        # Extract context around error (3 lines before and after)
        context = self._extract_context(match.start(), full_log)

        return ParsedError(
            error_type=error_type,
            file_path=file_path,
            line_number=line_number,
            error_message=match.group(0),
            context=context,
            suggestion=self._get_suggestion(error_type)
        )

    def _extract_context(self, position: int, full_text: str, lines: int = 3) -> str:
        """Extract surrounding lines for context"""
        lines_list = full_text[:position].split('\n')
        start_line = max(0, len(lines_list) - lines - 1)

        lines_after = full_text[position:].split('\n')[:lines]

        context_lines = lines_list[start_line:] + lines_after
        return '\n'.join(context_lines)

    def _get_suggestion(self, error_type: ErrorType) -> Optional[str]:
        """Get fix suggestion based on error type"""
        suggestions = {
            ErrorType.TEST_FAILURE: "Review test logic or update expected values",
            ErrorType.LINT_ERROR: "Run 'ruff check --fix' or 'clang-format -i'",
            ErrorType.TYPE_ERROR: "Add or fix type annotations",
            ErrorType.BUILD_ERROR: "Check includes, dependencies, and CMakeLists.txt",
            ErrorType.IMPORT_ERROR: "Install missing dependencies or fix import paths",
        }
        return suggestions.get(error_type)

    def classify_errors(self, errors: List[ParsedError]) -> Dict[ErrorType, List[ParsedError]]:
        """Group errors by type"""
        classified = {}
        for error in errors:
            if error.error_type not in classified:
                classified[error.error_type] = []
            classified[error.error_type].append(error)
        return classified

    def format_for_prompt(self, errors: List[ParsedError]) -> str:
        """Format errors for AI prompt"""
        prompt = "## Errors to Fix\n\n"

        classified = self.classify_errors(errors)

        for error_type, error_list in classified.items():
            prompt += f"### {error_type.value.upper()} ({len(error_list)} errors)\n\n"

            for i, error in enumerate(error_list, 1):
                prompt += f"**Error {i}**:\n"
                if error.file_path:
                    prompt += f"- File: `{error.file_path}`"
                    if error.line_number:
                        prompt += f" (line {error.line_number})"
                    prompt += "\n"

                prompt += f"- Message: {error.error_message}\n"

                if error.suggestion:
                    prompt += f"- Suggestion: {error.suggestion}\n"

                prompt += f"\n```\n{error.context}\n```\n\n"

        return prompt


# Usage example
if __name__ == "__main__":
    parser = ErrorLogParser()

    sample_log = """
    tests/test_main.py::test_calculate FAILED
    tests/test_main.py:42: AssertionError: assert 42 == 43
    src/main.py:10:5: E501 line too long (95 > 88 characters)
    src/utils.py:25: error: Incompatible return value type
    """

    errors = parser.parse(sample_log)
    formatted = parser.format_for_prompt(errors)
    print(formatted)
```

**Implementation Steps**:
1. Create error type enumeration
2. Implement regex patterns for common errors
3. Add context extraction around errors
4. Create structured error objects
5. Implement error classification
6. Add prompt formatting
7. Write comprehensive tests

**Deliverables**:
- [ ] `parse_results.py` with error parsing
- [ ] Error type classification
- [ ] Context extraction
- [ ] Unit tests

### 5.2 Retry Logic with Backoff

**Task**: Implement intelligent retry mechanism

**File**: `.github/actions/claude-code-runner/scripts/retry_handler.py`

```python
"""
Retry logic with exponential backoff and intelligent failure handling.
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

**Implementation Steps**:
1. Define retry strategies
2. Implement backoff calculations
3. Create retry handler class
4. Add async support
5. Implement decorator pattern
6. Add statistics tracking
7. Write tests

**Deliverables**:
- [ ] `retry_handler.py` with retry logic
- [ ] Configurable retry strategies
- [ ] Statistics tracking
- [ ] Unit tests

### 5.3 Validation Pipeline

**Task**: Multi-stage validation system

**File**: `.github/actions/claude-code-runner/scripts/validation.py`

```python
"""
Multi-stage validation pipeline for code changes.
"""

import subprocess
from typing import List, Dict, Optional
from dataclasses import dataclass
from enum import Enum
from pathlib import Path


class ValidationStage(Enum):
    """Validation stages"""
    FORMAT_CHECK = "format"
    LINT = "lint"
    TYPE_CHECK = "type"
    BUILD = "build"
    UNIT_TESTS = "tests"
    INTEGRATION_TESTS = "integration"


@dataclass
class ValidationResult:
    """Result from a validation stage"""
    stage: ValidationStage
    passed: bool
    output: str
    duration: float
    errors: List[str]


class ValidationPipeline:
    """Run validation checks in sequence"""

    def __init__(self, project_root: Path, language: str):
        self.project_root = project_root
        self.language = language
        self.results: List[ValidationResult] = []

    async def run_all(self, stages: Optional[List[ValidationStage]] = None) -> bool:
        """
        Run all validation stages.

        Args:
            stages: Specific stages to run, or None for all

        Returns:
            True if all stages pass
        """
        if stages is None:
            stages = self._get_default_stages()

        all_passed = True

        for stage in stages:
            result = await self._run_stage(stage)
            self.results.append(result)

            if not result.passed:
                all_passed = False
                # Stop on first failure for faster feedback
                break

        return all_passed

    def _get_default_stages(self) -> List[ValidationStage]:
        """Get default validation stages for language"""
        if self.language == "python":
            return [
                ValidationStage.FORMAT_CHECK,
                ValidationStage.LINT,
                ValidationStage.TYPE_CHECK,
                ValidationStage.UNIT_TESTS,
            ]
        elif self.language == "cpp":
            return [
                ValidationStage.FORMAT_CHECK,
                ValidationStage.LINT,
                ValidationStage.BUILD,
                ValidationStage.UNIT_TESTS,
            ]
        else:
            return [ValidationStage.UNIT_TESTS]

    async def _run_stage(self, stage: ValidationStage) -> ValidationResult:
        """Run a specific validation stage"""
        import time
        start_time = time.time()

        try:
            if self.language == "python":
                output, errors = await self._run_python_stage(stage)
            elif self.language == "cpp":
                output, errors = await self._run_cpp_stage(stage)
            else:
                raise ValueError(f"Unsupported language: {self.language}")

            passed = len(errors) == 0

        except Exception as e:
            output = str(e)
            errors = [str(e)]
            passed = False

        duration = time.time() - start_time

        return ValidationResult(
            stage=stage,
            passed=passed,
            output=output,
            duration=duration,
            errors=errors
        )

    async def _run_python_stage(self, stage: ValidationStage) -> tuple[str, List[str]]:
        """Run Python-specific validation"""
        commands = {
            ValidationStage.FORMAT_CHECK: ["ruff", "format", "--check", "."],
            ValidationStage.LINT: ["ruff", "check", "."],
            ValidationStage.TYPE_CHECK: ["mypy", "src/"],
            ValidationStage.UNIT_TESTS: ["pytest", "--tb=short"],
        }

        cmd = commands.get(stage)
        if not cmd:
            return ("Skipped", [])

        return await self._run_command(cmd)

    async def _run_cpp_stage(self, stage: ValidationStage) -> tuple[str, List[str]]:
        """Run C++-specific validation"""
        commands = {
            ValidationStage.FORMAT_CHECK: ["clang-format", "--dry-run", "-Werror", "src/**/*.cpp"],
            ValidationStage.LINT: ["clang-tidy", "src/**/*.cpp"],
            ValidationStage.BUILD: ["cmake", "--build", "build"],
            ValidationStage.UNIT_TESTS: ["ctest", "--test-dir", "build", "--output-on-failure"],
        }

        cmd = commands.get(stage)
        if not cmd:
            return ("Skipped", [])

        return await self._run_command(cmd)

    async def _run_command(self, cmd: List[str]) -> tuple[str, List[str]]:
        """Execute command and capture output"""
        import asyncio

        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=self.project_root
        )

        stdout, stderr = await process.communicate()

        output = stdout.decode() + stderr.decode()

        errors = []
        if process.returncode != 0:
            errors = self._extract_errors(output)

        return (output, errors)

    def _extract_errors(self, output: str) -> List[str]:
        """Extract error messages from output"""
        # Simple extraction - look for lines with 'error:'
        errors = []
        for line in output.split('\n'):
            if 'error:' in line.lower() or 'failed' in line.lower():
                errors.append(line.strip())
        return errors

    def get_summary(self) -> Dict:
        """Get validation summary"""
        total = len(self.results)
        passed = sum(1 for r in self.results if r.passed)
        failed = total - passed
        total_duration = sum(r.duration for r in self.results)

        return {
            'total_stages': total,
            'passed': passed,
            'failed': failed,
            'total_duration': total_duration,
            'results': [
                {
                    'stage': r.stage.value,
                    'passed': r.passed,
                    'duration': r.duration,
                    'error_count': len(r.errors)
                }
                for r in self.results
            ]
        }
```

**Implementation Steps**:
1. Define validation stages
2. Implement language-specific validators
3. Create pipeline orchestration
4. Add async command execution
5. Implement error extraction
6. Add summary reporting
7. Write integration tests

**Deliverables**:
- [ ] `validation.py` with multi-stage pipeline
- [ ] Language-specific validators
- [ ] Summary reporting
- [ ] Integration tests

---

## Input Validation

### Prevent Injection Attacks

```yaml
- name: Validate inputs
  run: |
    # Sanitize user input from issues/comments
    INPUT="${{ github.event.issue.body }}"

    # Check for suspicious patterns
    if echo "$INPUT" | grep -E '(\$\(|\`|;|\||&)'; then
      echo "::error::Suspicious input detected"
      exit 1
    fi
```

### Limit AI Prompt Size
```python
def sanitize_prompt(prompt: str, max_length: int = 50000) -> str:
    """Sanitize and limit prompt size"""
    # Remove potential code injection
    sanitized = re.sub(r'[`$();|&]', '', prompt)

    # Limit length
    if len(sanitized) > max_length:
        sanitized = sanitized[:max_length] + "\n\n[Truncated]"

    return sanitized
```

## Audit Logging

### Log All AI Operations
```python
import logging
import json

logger = logging.getLogger("claude-code-audit")

def log_ai_operation(
    operation: str,
    user: str,
    prompt_summary: str,
    result: dict
):
    """Log AI operations for audit trail"""
    log_entry = {
        "timestamp": datetime.utcnow().isoformat(),
        "operation": operation,
        "user": user,
        "prompt_summary": prompt_summary[:200],
        "success": result.get("success", False),
        "files_modified": result.get("files_modified", []),
        "tokens_used": result.get("tokens_used", 0),
    }

    logger.info(json.dumps(log_entry))
```

## Code Review Requirements

### Human Oversight
- All AI-generated PRs require human review
- Critical paths (main branch) require 2+ approvals
- Security-sensitive code flagged for manual review

```yaml
# Branch protection rules
- Require pull request reviews before merging
  - Required approvals: 2
  - Dismiss stale approvals: true

- Require status checks to pass
  - ai-safety-check
  - security-scan
```
```

**Implementation Steps**:
1. Document secret management procedures
2. Create input validation utilities
3. Implement rate limiting
4. Add audit logging
5. Set up branch protection

**Deliverables**:
- [ ] Security best practices documentation
- [ ] Input validation implementation
- [ ] Rate limiting
- [ ] Audit logging system

### 7.2 Monitoring and Metrics

**Task**: Track AI workflow performance and costs

**File**: `.github/actions/claude-code-runner/scripts/metrics.py`

```python
"""
Metrics collection and monitoring for AI workflows.
"""

import json
import time
from pathlib import Path
from typing import Dict, List
from dataclasses import dataclass, asdict
from datetime import datetime


@dataclass
class WorkflowMetrics:
    """Metrics for a single workflow execution"""
    workflow_id: str
    workflow_name: str
    trigger: str
    task_type: str
    start_time: float
    end_time: float
    success: bool
    tokens_used: int
    retry_count: int
    files_modified: List[str]
    validation_passed: bool
    error_message: str = ""

    @property
    def duration(self) -> float:
        """Calculate duration in seconds"""
        return self.end_time - self.start_time

    @property
    def cost_estimate(self) -> float:
        """Estimate cost based on tokens (rough estimate)"""
        # Claude Sonnet pricing (approximate)
        cost_per_1k_tokens = 0.003  # $3 per million tokens
        return (self.tokens_used / 1000) * cost_per_1k_tokens


class MetricsCollector:
    """Collect and store workflow metrics"""

    def __init__(self, metrics_dir: Path):
        self.metrics_dir = metrics_dir
        self.metrics_dir.mkdir(parents=True, exist_ok=True)

    def record_workflow(self, metrics: WorkflowMetrics):
        """Record workflow metrics"""
        # Save individual metric
        timestamp = datetime.fromtimestamp(metrics.start_time).strftime("%Y%m%d_%H%M%S")
        filename = f"{metrics.workflow_name}_{timestamp}.json"

        filepath = self.metrics_dir / filename
        with open(filepath, 'w') as f:
            json.dump(asdict(metrics), f, indent=2)

    def get_summary(self, days: int = 7) -> Dict:
        """Get summary of metrics for the last N days"""
        cutoff_time = time.time() - (days * 24 * 3600)

        metrics_files = list(self.metrics_dir.glob("*.json"))

        all_metrics = []
        for filepath in metrics_files:
            with open(filepath) as f:
                data = json.load(f)
                if data['start_time'] >= cutoff_time:
                    all_metrics.append(WorkflowMetrics(**data))

        if not all_metrics:
            return {"error": "No metrics found"}

        total_runs = len(all_metrics)
        successful_runs = sum(1 for m in all_metrics if m.success)
        total_tokens = sum(m.tokens_used for m in all_metrics)
        total_cost = sum(m.cost_estimate for m in all_metrics)
        avg_duration = sum(m.duration for m in all_metrics) / total_runs

        # Group by task type
        by_task_type = {}
        for m in all_metrics:
            if m.task_type not in by_task_type:
                by_task_type[m.task_type] = []
            by_task_type[m.task_type].append(m)

        task_summaries = {}
        for task_type, metrics_list in by_task_type.items():
            task_summaries[task_type] = {
                "count": len(metrics_list),
                "success_rate": sum(1 for m in metrics_list if m.success) / len(metrics_list),
                "avg_tokens": sum(m.tokens_used for m in metrics_list) / len(metrics_list),
                "avg_duration": sum(m.duration for m in metrics_list) / len(metrics_list),
            }

        return {
            "period_days": days,
            "total_runs": total_runs,
            "successful_runs": successful_runs,
            "success_rate": successful_runs / total_runs,
            "total_tokens_used": total_tokens,
            "estimated_total_cost": total_cost,
            "average_duration_seconds": avg_duration,
            "by_task_type": task_summaries,
        }

    def export_for_dashboard(self, output_path: Path):
        """Export metrics in format suitable for dashboards"""
        summary = self.get_summary(days=30)

        with open(output_path, 'w') as f:
            json.dump(summary, f, indent=2)
```

**GitHub Action for Metrics**:

**File**: `.github/workflows/metrics-report.yaml`

```yaml
name: AI Workflow Metrics Report

on:
  schedule:
    - cron: '0 0 * * 0'  # Weekly on Sunday
  workflow_dispatch:

jobs:
  generate-report:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Generate metrics report
        run: |
          python3 .github/actions/claude-code-runner/scripts/metrics.py \
            --period 7 \
            --output /tmp/metrics-report.json

      - name: Create issue with report
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const metrics = JSON.parse(fs.readFileSync('/tmp/metrics-report.json', 'utf8'));

            const body = `# 🤖 AI Workflow Metrics Report

            **Period**: Last ${metrics.period_days} days

            ## Summary
            - **Total Runs**: ${metrics.total_runs}
            - **Success Rate**: ${(metrics.success_rate * 100).toFixed(1)}%
            - **Total Tokens Used**: ${metrics.total_tokens_used.toLocaleString()}
            - **Estimated Cost**: $${metrics.estimated_total_cost.toFixed(2)}
            - **Average Duration**: ${metrics.average_duration_seconds.toFixed(1)}s

            ## By Task Type
            ${Object.entries(metrics.by_task_type).map(([type, stats]) => `
            ### ${type}
            - Runs: ${stats.count}
            - Success Rate: ${(stats.success_rate * 100).toFixed(1)}%
            - Avg Tokens: ${stats.avg_tokens.toFixed(0)}
            - Avg Duration: ${stats.avg_duration.toFixed(1)}s
            `).join('\n')}

            ---
            *Generated automatically by AI Metrics workflow*
            `;

            await github.rest.issues.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: `AI Workflow Metrics - ${new Date().toISOString().split('T')[0]}`,
              body: body,
              labels: ['metrics', 'ai-automation']
            });
```

**Implementation Steps**:
1. Create metrics data structures
2. Implement metrics collection
3. Add summary and aggregation
4. Create dashboard export
5. Set up automated reporting
6. Write tests

**Deliverables**:
- [ ] `metrics.py` with collection and reporting
- [ ] Automated metrics workflow
- [ ] Dashboard export format
- [ ] Documentation

---

## Workflows

### 1. PR Automation (`ai-workflow.yaml`)

**Triggers**:
- Issue labeled with `ai-assist`
- Comment containing `@claude`
- Manual workflow dispatch

**Process**:
1. Analyzes issue description
2. Creates feature branch
3. Implements solution using Claude Code
4. Runs validation tests
5. Creates pull request
6. Comments on original issue

**Usage**:

```markdown
# Create an issue
Title: Add input validation to login form

Body:
The login form should validate:
- Email format
- Password length (min 8 chars)
- Required fields

@claude please implement this

# Add label "ai-assist"
```

**Result**: Automatic PR with implementation

### 2. CI Fix Automation (`ai-fix-ci.yaml`)

**Triggers**:
- CI workflow fails
- Manual workflow dispatch with run ID

**Process**:
1. Detects CI failure
2. Downloads error logs
3. Classifies error type (test, lint, build, type)
4. Generates fix using Claude Code
5. Validates fix locally
6. Commits and pushes fix
7. Comments on PR

**Example**:

```bash
# Automatic trigger when CI fails
# No manual intervention needed

# Manual trigger
gh workflow run ai-fix-ci.yaml -f run-id=12345
```

### 3. PR Review (`ai-pr-review.yaml`)

**Triggers**:
- PR labeled with `ai-review`
- Manual workflow dispatch

**Process**:
1. Fetches PR diff
2. Analyzes changed files
3. Runs Claude Code review
4. Posts review comment with findings

**Usage**:

```bash
# Create PR and add label "ai-review"
# Or use gh CLI
gh pr create --label ai-review

# Review is posted automatically
```

## Configuration

### CLAUDE.md

Project-specific context for AI assistant:

```markdown
# AI Assistant Workflow Guide - Your Project

## Project Context
- Language: Python 3.11
- Framework: FastAPI
- Database: PostgreSQL

## Code Standards
- Use type hints
- Write docstrings
- Minimum test coverage: 80%

## Custom Guidelines
[Your project-specific rules]
```

### MCP Servers

Advanced: Configure Model Context Protocol servers:

`.github/claude/mcp-config.json`:
```json
{
  "mcpServers": {
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "{{GITHUB_TOKEN}}"
      }
    }
  }
}
```

### Custom Slash Commands

Create custom commands in `.github/claude/commands/`:

`my-command.md`:
```markdown
# /my-command

Description of what this command does.

## Instructions
1. Step 1
2. Step 2

## Output Format
Expected output format
```

## Security

### Best Practices

1. **Secret Management**
   - Never commit API keys
   - Use GitHub Secrets
   - Rotate keys regularly

2. **Code Review**
   - Always review AI-generated PRs
   - Require human approval
   - Use branch protection

3. **Rate Limiting**
   - Monitor API usage
   - Set up alerts for unusual activity
   - Implement cost controls

4. **Input Validation**
   - Sanitize user input from issues/comments
   - Limit prompt size
   - Validate outputs

### Permissions

Workflows use these permissions:

```yaml
permissions:
  contents: write        # Commit fixes
  issues: write          # Comment on issues
  pull-requests: write   # Create PRs
  models: read          # Access AI models
  actions: read         # Read workflow runs
```

## Troubleshooting

### Common Issues

#### 1. "ANTHROPIC_API_KEY not found"

**Solution**:
```bash
# Check secret is set
gh secret list

# Set if missing
gh secret set ANTHROPIC_API_KEY
```

#### 2. Workflow not triggering

**Causes**:
- Missing label (ai-assist, ai-review)
- Incorrect trigger configuration
- Permissions issue

**Solution**:
```yaml
# Check workflow file
on:
  issues:
    types: [labeled]  # Ensure this matches

# Check permissions
permissions:
  contents: write  # Required for commits
```

#### 3. Validation failures

**Causes**:
- Tests failing
- Linting errors
- Type check errors

**Solution**:
- Review error logs
- Run validation locally
- Fix errors manually if AI cannot resolve

#### 4. High API costs

**Monitoring**:
```bash
# Check metrics report (generated weekly)
# Look for:
# - Token usage trends
# - Success rates
# - Average tokens per task
```

**Optimization**:
- Reduce prompt size
- Use more specific prompts
- Increase validation before AI calls

### Debug Mode

Enable debug logging:

```yaml
- name: Run Claude Code
  env:
    DEBUG: 'true'
    LOG_LEVEL: 'debug'
  # ...
```

### Support

- GitHub Issues: [link]
- Documentation: [link]
- Examples: [link]

## Metrics and Monitoring

Weekly automated metrics reports show:
- Total AI workflow runs
- Success rates
- Token usage and costs
- Average execution time
- Breakdown by task type

Access reports in repository issues with `metrics` label.

## Advanced Topics

### Custom Validation

Add custom validation stages:

```python
# .github/actions/custom-validation/validate.py

def custom_check():
    # Your validation logic
    pass
```

### Multi-Language Support

The system supports both Python and C++ projects with language-specific:
- Validation pipelines
- Fix templates
- Error parsers

### Extending Workflows

Add new task types:

1. Create prompt template in `.github/claude/prompts/templates/`
2. Add workflow file in `.github/workflows/`
3. Update `run_claude_code.py` with new task type
4. Document in CLAUDE.md

---

*For more details, see the [API Reference](API_REFERENCE.md) and [Examples](EXAMPLES.md)*
```

**Implementation Steps**:
1. Write comprehensive user guide
2. Create API reference documentation
3. Add troubleshooting guide
4. Create example repository
5. Record video tutorials

**Deliverables**:
- [ ] Complete user guide
- [ ] API reference
- [ ] Troubleshooting guide
- [ ] Example projects
- [ ] Video tutorials (optional)

---

## Phase 9: Rollout and Iteration (Week 5-6)

### Objective
Deploy the AI automation system and gather feedback for improvements.

### 9.1 Pilot Deployment

**Task**: Deploy to pilot projects and gather metrics

**Pilot Selection Criteria**:
1. Active development (frequent commits)
2. Good test coverage (>70%)
3. Well-documented codebase
4. Team willing to provide feedback

**Pilot Process**:

1. **Week 5, Day 1-2**: Deploy to 2-3 pilot projects
   - Enable AI workflows
   - Monitor closely
   - Collect feedback

2. **Week 5, Day 3-5**: Iterate based on feedback
   - Fix issues
   - Optimize prompts
   - Improve validation

3. **Week 5, Day 6-7**: Measure results
   - Compare metrics (before/after)
   - Document improvements
   - Prepare recommendations

**Deliverables**:
- [ ] Pilot deployment to 2-3 projects
- [ ] Feedback collection
- [ ] Performance metrics
- [ ] Improvement recommendations

### 9.2 Production Rollout

**Task**: Gradual rollout to all projects

**Rollout Stages**:

1. **Stage 1**: Observation mode (Week 6, Day 1-2)
   - AI creates PRs but doesn't auto-merge
   - Human review required for all changes
   - Collect success metrics

2. **Stage 2**: Limited automation (Week 6, Day 3-4)
   - Auto-fix for low-risk issues (linting, formatting)
   - Manual review for logic changes
   - Monitor closely

3. **Stage 3**: Full automation (Week 6, Day 5-7)
   - All workflows enabled
   - Automated fixes with validation
   - Continuous monitoring

**Success Criteria**:
- 90%+ success rate on CI fixes
- <5 minute average fix time
- 80%+ developer satisfaction
- Zero security incidents

**Deliverables**:
- [ ] Staged rollout plan
- [ ] Success metrics tracking
- [ ] Rollback procedures
- [ ] Production documentation

---

## Implementation Checklist

### Phase 1: Foundation (Week 1, Days 1-3)
- [ ] Create directory structure
- [ ] Develop `run_claude_code.py`
- [ ] Create `context_manager.py`
- [ ] Write `action.yaml` for composite action
- [ ] Create CLAUDE.md templates
- [ ] Write unit tests

### Phase 2: Cookiecutter Updates (Week 1, Days 4-5)
- [ ] Update Python template
- [ ] Update C++ template
- [ ] Enhance post-generation hooks
- [ ] Test template generation

### Phase 3: Core Workflows (Week 2, Days 1-4)
- [ ] Create PR automation workflow
- [ ] Create CI fix workflow
- [ ] Create PR review workflow
- [ ] Test all workflows

### Phase 4: Prompt Engineering (Week 2, Days 5-7)
- [ ] Create slash commands
- [ ] Create language-specific templates
- [ ] Write subagent system prompt
- [ ] Test prompts

### Phase 5: Validation (Week 3, Days 1-3)
- [ ] Develop error parser
- [ ] Implement retry logic
- [ ] Create validation pipeline
- [ ] Write tests

### Phase 6: MCP Integration (Week 3, Days 4-7)
- [ ] Set up MCP configuration
- [ ] Develop MCP manager
- [ ] Integrate with runner
- [ ] Test MCP servers

### Phase 7: Security (Week 4, Days 1-3)
- [ ] Document security practices
- [ ] Implement input validation
- [ ] Add rate limiting
- [ ] Create audit logging
- [ ] Set up monitoring

### Phase 8: Testing & Docs (Week 4, Days 4-7)
- [ ] Write integration tests
- [ ] Create user guide
- [ ] Write API reference
- [ ] Create examples
- [ ] Record tutorials

### Phase 9: Rollout (Week 5-6)
- [ ] Pilot deployment
- [ ] Gather feedback
- [ ] Iterate and improve
- [ ] Production rollout
- [ ] Monitor and optimize

---

## Risk Management

### Technical Risks

| Risk | Impact | Probability | Mitigation |
|:-----|:-------|:------------|:-----------|
| AI generates incorrect fixes | High | Medium | Multi-stage validation, human review |
| API rate limits exceeded | Medium | Low | Rate limiting, request queuing |
| Context overflow (200K tokens) | Medium | Medium | Intelligent context management |
| MCP server failures | Low | Low | Fallback to non-MCP mode |

### Operational Risks

| Risk | Impact | Probability | Mitigation |
|:-----|:-------|:------------|:-----------|
| High API costs | Medium | Medium | Cost monitoring, usage alerts |
| Developer resistance | High | Low | Training, gradual rollout |
| Security vulnerabilities | High | Low | Input validation, code review |
| Workflow downtime | Medium | Low | Fallback procedures, monitoring |

---

## Success Metrics

### Performance Metrics

| Metric | Baseline | Target | Measurement |
|:-------|:---------|:-------|:------------|
| CI failure resolution time | 30 min | 5 min | Workflow duration |
| Code review time | 2 hours | 15 min | Time to first review |
| Issue-to-PR time | 4 hours | 10 min | Issue creation to PR |
| Success rate | N/A | 90% | Successful workflows / total |

### Quality Metrics

| Metric | Target | Measurement |
|:-------|:-------|:------------|
| Test coverage maintained | >80% | pytest-cov |
| Code quality score | >8/10 | SonarQube / CodeClimate |
| Security vulnerabilities | 0 critical | Security scans |
| Human intervention rate | <20% | Manual fixes / total runs |

### Cost Metrics

| Metric | Target | Measurement |
|:-------|:-------|:------------|
| Cost per fix | <$0.10 | Tokens used × pricing |
| Monthly API cost | <$100 | Anthropic billing |
| Developer time saved | >10 hours/week | Surveys, time tracking |
| ROI | >5x | (Time saved × hourly rate) / API cost |

---

## Future Enhancements

### Post-Launch Improvements

1. **Multi-Agent System** (Phase 10, Week 7-8)
   - Specialized agents for different tasks
   - Agent orchestration and communication
   - Parallel task execution

2. **Learning System** (Phase 11, Week 9-10)
   - Capture successful fixes
   - Build knowledge base
   - Improve prompts based on history

3. **Advanced Analytics** (Phase 12, Week 11-12)
   - Real-time dashboards
   - Predictive failure detection
   - Cost optimization recommendations

4. **IDE Integration** (Future)
   - VS Code extension
   - JetBrains plugin
   - Local AI assistance

---

## Conclusion

This development plan provides a comprehensive roadmap for implementing AI-powered workflow automation using Claude Code CLI. The phased approach ensures:

1. **Solid Foundation**: Core infrastructure and security from day one
2. **Iterative Development**: Continuous feedback and improvement
3. **Risk Mitigation**: Gradual rollout with monitoring
4. **Measurable Success**: Clear metrics and KPIs
5. **Scalability**: Architecture supports future enhancements

### Next Steps

1. Review and approve this plan
2. Set up development environment
3. Begin Phase 1 implementation
4. Schedule regular progress reviews
5. Establish communication channels for feedback

### Resources Required

- **Development**: 1-2 engineers (6 weeks)
- **Testing**: 1 QA engineer (2 weeks)
- **Documentation**: Technical writer (1 week)
- **API Costs**: ~$100-200 for testing and pilot
- **Infrastructure**: GitHub Actions (existing)

---

**Document Version**: 1.0
**Last Updated**: 2025-10-15
**Status**: Ready for Review
**Author**: Claude Code AI Assistant
