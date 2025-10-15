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
