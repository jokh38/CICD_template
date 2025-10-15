# Validation and Error Handling

## Overview

This document describes the comprehensive validation system and error handling mechanisms used throughout the AI automation workflow. The system implements multi-stage validation, intelligent error parsing, and robust retry logic to ensure reliable and safe AI operations.

## Validation Architecture

### Multi-Layer Validation

```
Input Validation
    ↓
Pre-execution Validation
    ↓
AI Operation Execution
    ↓
Post-execution Validation
    ↓
Integration Testing
    ↓
Production Deployment
```

### Validation Stages

1. **Input Validation**: Sanitize and validate all inputs
2. **Pre-execution Validation**: Check prerequisites
3. **Runtime Validation**: Monitor AI operations
4. **Post-execution Validation**: Verify results
5. **Integration Validation**: End-to-end testing
6. **Production Validation**: Safety checks before deployment

## Error Parsing and Classification

### Error Types

```python
from enum import Enum

class ErrorType(Enum):
    """Classification of error types"""
    TEST_FAILURE = "test-failure"
    LINT_ERROR = "lint-error"
    TYPE_ERROR = "type-error"
    BUILD_ERROR = "build-error"
    IMPORT_ERROR = "import-error"
    RUNTIME_ERROR = "runtime-error"
    SECURITY_ERROR = "security-error"
    CONFIGURATION_ERROR = "configuration-error"
    UNKNOWN = "unknown"
```

### Error Data Structure

```python
from dataclasses import dataclass
from typing import Optional, List
from datetime import datetime

@dataclass
class ParsedError:
    """Structured error information"""
    error_type: ErrorType
    file_path: Optional[str]
    line_number: Optional[int]
    column_number: Optional[int]
    error_message: str
    context: str
    suggestion: Optional[str] = None
    severity: str = "error"  # error, warning, info
    timestamp: datetime = None

    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.utcnow()
```

### Error Parser Implementation

```python
import re
from typing import Dict, List, Pattern

class ErrorLogParser:
    """Parse and classify error logs from CI/CD pipelines"""

    # Regex patterns for different error types
    PATTERNS = {
        ErrorType.TEST_FAILURE: [
            r'(FAILED|ERROR|AssertionError)\s+(.+?):(\d+)',
            r'pytest.*?FAILED.*?::(.+)',
            r'EXPECT_\w+.*?failed.*?at (.+?):(\d+)',
            r'assertion.*?failed.*?at (.+?):(\d+)',
        ],
        ErrorType.LINT_ERROR: [
            r'(.+?):(\d+):(\d+):\s+(E\d+|F\d+|W\d+)',  # Ruff/Flake8
            r'(.+?):(\d+):(\d+):\s+error:',  # clang-tidy
            r'(.+?):(\d+):\s+(warning|error):',  # General linting
        ],
        ErrorType.TYPE_ERROR: [
            r'(.+?):(\d+):\s+error:.*?\[.*?\]',  # mypy
            r'TypeError:.*?in file "(.+?)" line (\d+)',
            r'Incompatible types in assignment',
        ],
        ErrorType.BUILD_ERROR: [
            r'(.+?):(\d+):(\d+):\s+(fatal\s+)?error:',  # Compiler
            r'CMake Error at (.+?):(\d+)',
            r'undefined reference to',
            r'cannot find -l',
            r'No such file or directory',
        ],
        ErrorType.IMPORT_ERROR: [
            r'ImportError:\s+(.+)',
            r'ModuleNotFoundError:\s+No module named ["\'](.+?)["\']',
            r'No module named',
            r'cannot import name',
        ],
        ErrorType.SECURITY_ERROR: [
            r'CVE-\d{4}-\d+',
            r'security vulnerability',
            r'unauthorized access',
            r'authentication failed',
        ],
    }

    def __init__(self):
        self.compiled_patterns = self._compile_patterns()

    def _compile_patterns(self) -> Dict[ErrorType, List[Pattern]]:
        """Compile regex patterns for performance"""
        compiled = {}
        for error_type, patterns in self.PATTERNS.items():
            compiled[error_type] = [re.compile(pattern, re.MULTILINE) for pattern in patterns]
        return compiled

    def parse(self, error_log: str) -> List[ParsedError]:
        """
        Parse error log and extract structured errors.

        Args:
            error_log: Raw error log text

        Returns:
            List of parsed errors
        """
        errors = []

        for error_type, patterns in self.compiled_patterns.items():
            for pattern in patterns:
                matches = pattern.finditer(error_log)
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
                column_number=None,
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
        line_number = None
        column_number = None

        if len(groups) > 1 and groups[1] and groups[1].isdigit():
            line_number = int(groups[1])
        if len(groups) > 2 and groups[2] and groups[2].isdigit():
            column_number = int(groups[2])

        # Extract context around error (3 lines before and after)
        context = self._extract_context(match.start(), full_log)

        return ParsedError(
            error_type=error_type,
            file_path=file_path,
            line_number=line_number,
            column_number=column_number,
            error_message=match.group(0),
            context=context,
            suggestion=self._get_suggestion(error_type, match.group(0))
        )

    def _extract_context(self, position: int, full_text: str, lines: int = 3) -> str:
        """Extract surrounding lines for context"""
        lines_list = full_text[:position].split('\n')
        start_line = max(0, len(lines_list) - lines - 1)

        lines_after = full_text[position:].split('\n')[:lines]

        context_lines = lines_list[start_line:] + lines_after
        return '\n'.join(context_lines)

    def _get_suggestion(self, error_type: ErrorType, error_message: str) -> Optional[str]:
        """Get fix suggestion based on error type and message"""
        suggestions = {
            ErrorType.TEST_FAILURE: "Review test logic or update expected values",
            ErrorType.LINT_ERROR: "Run 'ruff check --fix' or 'clang-format -i'",
            ErrorType.TYPE_ERROR: "Add or fix type annotations",
            ErrorType.BUILD_ERROR: "Check includes, dependencies, and CMakeLists.txt",
            ErrorType.IMPORT_ERROR: "Install missing dependencies or fix import paths",
            ErrorType.SECURITY_ERROR: "Review security implications and apply patches",
        }

        base_suggestion = suggestions.get(error_type)

        # More specific suggestions based on error content
        if "unused" in error_message.lower():
            return "Remove unused import or variable"
        elif "undefined reference" in error_message.lower():
            return "Link missing library or implement function"
        elif "no such file" in error_message.lower():
            return "Create missing file or fix path"
        elif "permission denied" in error_message.lower():
            return "Check file permissions"

        return base_suggestion

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
                    if error.column_number:
                        prompt += f":{error.column_number}"
                    prompt += "\n"

                prompt += f"- Severity: {error.severity}\n"
                prompt += f"- Message: {error.error_message}\n"

                if error.suggestion:
                    prompt += f"- Suggestion: {error.suggestion}\n"

                prompt += f"\n```\n{error.context}\n```\n\n"

        return prompt
```

## Validation Pipeline

### Pipeline Architecture

```python
from enum import Enum
from dataclasses import dataclass
from typing import List, Dict, Optional, Callable
from pathlib import Path
import asyncio
import time

class ValidationStage(Enum):
    """Validation stages"""
    FORMAT_CHECK = "format"
    LINT = "lint"
    TYPE_CHECK = "type"
    BUILD = "build"
    UNIT_TESTS = "tests"
    INTEGRATION_TESTS = "integration"
    SECURITY_SCAN = "security"
    PERFORMANCE_TEST = "performance"

@dataclass
class ValidationResult:
    """Result from a validation stage"""
    stage: ValidationStage
    passed: bool
    output: str
    duration: float
    errors: List[str]
    warnings: List[str]
    metrics: Dict[str, any] = None

class ValidationPipeline:
    """Run validation checks in sequence with intelligent skipping"""

    def __init__(self, project_root: Path, language: str):
        self.project_root = project_root
        self.language = language
        self.results: List[ValidationResult] = []
        self.custom_validators: Dict[ValidationStage, Callable] = {}

    def register_validator(self, stage: ValidationStage, validator: Callable):
        """Register a custom validator for a stage"""
        self.custom_validators[stage] = validator

    async def run_all(
        self,
        stages: Optional[List[ValidationStage]] = None,
        fail_fast: bool = True
    ) -> bool:
        """
        Run all validation stages.

        Args:
            stages: Specific stages to run, or None for all
            fail_fast: Stop on first failure

        Returns:
            True if all stages pass
        """
        if stages is None:
            stages = self._get_default_stages()

        all_passed = True

        for stage in stages:
            # Skip stage if prerequisites not met
            if not self._should_run_stage(stage):
                print(f"Skipping {stage.value} - prerequisites not met")
                continue

            result = await self._run_stage(stage)
            self.results.append(result)

            if not result.passed and fail_fast:
                all_passed = False
                print(f"Validation failed at {stage.value} stage")
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

    def _should_run_stage(self, stage: ValidationStage) -> bool:
        """Check if stage should run based on prerequisites"""
        # Example: Don't run tests if build failed
        if stage in [ValidationStage.UNIT_TESTS, ValidationStage.INTEGRATION_TESTS]:
            build_result = self._get_last_result(ValidationStage.BUILD)
            if build_result and not build_result.passed:
                return False

        # Don't run type checking if linting failed
        if stage == ValidationStage.TYPE_CHECK:
            lint_result = self._get_last_result(ValidationStage.LINT)
            if lint_result and not lint_result.passed:
                return False

        return True

    def _get_last_result(self, stage: ValidationStage) -> Optional[ValidationResult]:
        """Get the last result for a specific stage"""
        for result in reversed(self.results):
            if result.stage == stage:
                return result
        return None

    async def _run_stage(self, stage: ValidationStage) -> ValidationResult:
        """Run a specific validation stage"""
        start_time = time.time()

        try:
            # Use custom validator if registered
            if stage in self.custom_validators:
                output, errors, warnings, metrics = await self.custom_validators[stage]()
            else:
                if self.language == "python":
                    output, errors, warnings, metrics = await self._run_python_stage(stage)
                elif self.language == "cpp":
                    output, errors, warnings, metrics = await self._run_cpp_stage(stage)
                else:
                    raise ValueError(f"Unsupported language: {self.language}")

            passed = len(errors) == 0

        except Exception as e:
            output = str(e)
            errors = [str(e)]
            warnings = []
            passed = False
            metrics = {}

        duration = time.time() - start_time

        return ValidationResult(
            stage=stage,
            passed=passed,
            output=output,
            duration=duration,
            errors=errors,
            warnings=warnings,
            metrics=metrics
        )

    async def _run_python_stage(self, stage: ValidationStage) -> tuple:
        """Run Python-specific validation"""
        commands = {
            ValidationStage.FORMAT_CHECK: ["ruff", "format", "--check", "."],
            ValidationStage.LINT: ["ruff", "check", "."],
            ValidationStage.TYPE_CHECK: ["mypy", "src/"],
            ValidationStage.UNIT_TESTS: ["pytest", "--tb=short", "--cov=src"],
            ValidationStage.SECURITY_SCAN: ["bandit", "-r", "src/"],
            ValidationStage.PERFORMANCE_TEST: ["pytest", "tests/performance/", "-v"],
        }

        cmd = commands.get(stage)
        if not cmd:
            return ("Skipped", [], [], {})

        return await self._run_command_with_metrics(cmd, stage)

    async def _run_cpp_stage(self, stage: ValidationStage) -> tuple:
        """Run C++-specific validation"""
        commands = {
            ValidationStage.FORMAT_CHECK: ["clang-format", "--dry-run", "-Werror", "src/**/*.cpp"],
            ValidationStage.LINT: ["clang-tidy", "src/**/*.cpp"],
            ValidationStage.BUILD: ["cmake", "--build", "build"],
            ValidationStage.UNIT_TESTS: ["ctest", "--test-dir", "build", "--output-on-failure"],
            ValidationStage.SECURITY_SCAN: ["cppcheck", "--enable=all", "src/"],
        }

        cmd = commands.get(stage)
        if not cmd:
            return ("Skipped", [], [], {})

        return await self._run_command_with_metrics(cmd, stage)

    async def _run_command_with_metrics(self, cmd: List[str], stage: ValidationStage) -> tuple:
        """Execute command and capture output with metrics"""
        import asyncio

        process = await asyncio.create_subprocess_exec(
            *cmd,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=self.project_root
        )

        stdout, stderr = await process.communicate()

        output = stdout.decode() + stderr.decode()

        # Extract errors and warnings
        errors = self._extract_errors(output)
        warnings = self._extract_warnings(output)

        # Calculate metrics
        metrics = self._calculate_metrics(output, stage, process.returncode)

        return (output, errors, warnings, metrics)

    def _extract_errors(self, output: str) -> List[str]:
        """Extract error messages from output"""
        errors = []
        for line in output.split('\n'):
            if any(keyword in line.lower() for keyword in ['error:', 'failed', 'error:', 'traceback']):
                errors.append(line.strip())
        return errors

    def _extract_warnings(self, output: str) -> List[str]:
        """Extract warning messages from output"""
        warnings = []
        for line in output.split('\n'):
            if any(keyword in line.lower() for keyword in ['warning:', 'warn']):
                warnings.append(line.strip())
        return warnings

    def _calculate_metrics(self, output: str, stage: ValidationStage, return_code: int) -> Dict:
        """Calculate validation metrics"""
        metrics = {
            'return_code': return_code,
            'output_lines': len(output.split('\n')),
            'output_size': len(output),
        }

        # Stage-specific metrics
        if stage == ValidationStage.UNIT_TESTS:
            metrics.update(self._extract_test_metrics(output))
        elif stage == ValidationStage.LINT:
            metrics.update(self._extract_lint_metrics(output))
        elif stage == ValidationStage.TYPE_CHECK:
            metrics.update(self._extract_type_check_metrics(output))

        return metrics

    def _extract_test_metrics(self, output: str) -> Dict:
        """Extract test-specific metrics"""
        metrics = {}

        # Look for pytest output patterns
        import re

        # Test count
        test_match = re.search(r'(\d+) passed', output)
        if test_match:
            metrics['tests_passed'] = int(test_match.group(1))

        failed_match = re.search(r'(\d+) failed', output)
        if failed_match:
            metrics['tests_failed'] = int(failed_match.group(1))

        # Coverage
        coverage_match = re.search(r'(\d+)%', output)
        if coverage_match:
            metrics['coverage_percentage'] = int(coverage_match.group(1))

        return metrics

    def _extract_lint_metrics(self, output: str) -> Dict:
        """Extract linting-specific metrics"""
        metrics = {}

        # Count different types of issues
        error_count = len(re.findall(r'[EF]\d+', output))
        warning_count = len(re.findall(r'W\d+', output))

        metrics['lint_errors'] = error_count
        metrics['lint_warnings'] = warning_count

        return metrics

    def _extract_type_check_metrics(self, output: str) -> Dict:
        """Extract type checking-specific metrics"""
        metrics = {}

        # Count type errors
        error_count = len(re.findall(r'error:', output, re.IGNORECASE))

        metrics['type_errors'] = error_count

        return metrics

    def get_summary(self) -> Dict:
        """Get validation summary"""
        total = len(self.results)
        passed = sum(1 for r in self.results if r.passed)
        failed = total - passed
        total_duration = sum(r.duration for r in self.results)
        total_errors = sum(len(r.errors) for r in self.results)
        total_warnings = sum(len(r.warnings) for r in self.results)

        return {
            'total_stages': total,
            'passed_stages': passed,
            'failed_stages': failed,
            'total_duration': total_duration,
            'total_errors': total_errors,
            'total_warnings': total_warnings,
            'success_rate': passed / total if total > 0 else 0,
            'results': [
                {
                    'stage': r.stage.value,
                    'passed': r.passed,
                    'duration': r.duration,
                    'error_count': len(r.errors),
                    'warning_count': len(r.warnings),
                    'metrics': r.metrics or {}
                }
                for r in self.results
            ]
        }
```

## Retry Logic with Backoff

### Retry Strategies

```python
from enum import Enum
from dataclasses import dataclass
from typing import Callable, Optional, Any, List
import asyncio
import time
import random

class RetryStrategy(Enum):
    """Retry strategies"""
    EXPONENTIAL_BACKOFF = "exponential"
    LINEAR_BACKOFF = "linear"
    CONSTANT = "constant"
    JITTER = "jitter"  # Exponential with jitter

@dataclass
class RetryConfig:
    """Configuration for retry behavior"""
    max_attempts: int = 3
    base_delay: float = 1.0  # seconds
    max_delay: float = 60.0
    strategy: RetryStrategy = RetryStrategy.EXPONENTIAL_BACKOFF
    retry_on_exceptions: tuple = (Exception,)
    jitter_factor: float = 0.1  # For jitter strategy
    retry_on_status_codes: List[int] = None  # For HTTP retries

class RetryHandler:
    """Handle retries with various backoff strategies"""

    def __init__(self, config: Optional[RetryConfig] = None):
        self.config = config or RetryConfig()
        self.attempt_count = 0
        self.total_delay = 0.0
        self.retry_history: List[Dict] = []

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
            attempt_start = time.time()

            try:
                result = await func(*args, **kwargs)

                # Check if result indicates success
                if self._is_success(result):
                    # Record successful attempt
                    self.retry_history.append({
                        'attempt': attempt,
                        'success': True,
                        'duration': time.time() - attempt_start,
                        'delay': 0
                    })
                    return result
                else:
                    last_exception = Exception(f"Validation failed on attempt {attempt}")
                    self._record_failed_attempt(attempt, attempt_start, last_exception)

            except self.config.retry_on_exceptions as e:
                last_exception = e
                self._record_failed_attempt(attempt, attempt_start, e)

            # Don't sleep after last attempt
            if attempt < self.config.max_attempts:
                delay = self._calculate_delay(attempt)
                print(f"Attempt {attempt} failed: {str(last_exception)}")
                print(f"Retrying in {delay:.2f} seconds...")
                await asyncio.sleep(delay)
                self.total_delay += delay

        # All retries exhausted
        raise last_exception or Exception("All retry attempts failed")

    def _record_failed_attempt(self, attempt: int, start_time: float, exception: Exception):
        """Record a failed attempt for debugging"""
        self.retry_history.append({
            'attempt': attempt,
            'success': False,
            'duration': time.time() - start_time,
            'delay': self._calculate_delay(attempt) if attempt < self.config.max_attempts else 0,
            'error': str(exception),
            'error_type': type(exception).__name__
        })

    def _calculate_delay(self, attempt: int) -> float:
        """Calculate delay based on retry strategy"""
        if self.config.strategy == RetryStrategy.EXPONENTIAL_BACKOFF:
            delay = self.config.base_delay * (2 ** (attempt - 1))
        elif self.config.strategy == RetryStrategy.LINEAR_BACKOFF:
            delay = self.config.base_delay * attempt
        elif self.config.strategy == RetryStrategy.JITTER:
            # Exponential backoff with jitter
            base_delay = self.config.base_delay * (2 ** (attempt - 1))
            jitter = base_delay * self.config.jitter_factor * random.random()
            delay = base_delay + jitter
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
        successful_attempts = sum(1 for attempt in self.retry_history if attempt['success'])

        return {
            'total_attempts': self.attempt_count,
            'successful_attempts': successful_attempts,
            'failed_attempts': self.attempt_count - successful_attempts,
            'total_delay': self.total_delay,
            'average_delay': self.total_delay / max(1, self.attempt_count - 1),
            'success_rate': successful_attempts / self.attempt_count if self.attempt_count > 0 else 0,
            'retry_history': self.retry_history
        }

# HTTP-specific retry handler
class HTTPRetryHandler(RetryHandler):
    """Retry handler with HTTP status code support"""

    def _is_success(self, result: Any) -> bool:
        """Check HTTP response success"""
        if hasattr(result, 'status_code'):
            return 200 <= result.status_code < 300
        return super()._is_success(result)

    async def execute_with_retry(
        self,
        func: Callable,
        *args,
        **kwargs
    ) -> Any:
        """Execute with HTTP-specific retry logic"""
        last_exception = None

        for attempt in range(1, self.config.max_attempts + 1):
            self.attempt_count = attempt
            attempt_start = time.time()

            try:
                result = await func(*args, **kwargs)

                if self._is_success(result):
                    return result
                elif (self.config.retry_on_status_codes and
                      hasattr(result, 'status_code') and
                      result.status_code in self.config.retry_on_status_codes):
                    last_exception = Exception(f"HTTP {result.status_code}: {result.text}")
                    self._record_failed_attempt(attempt, attempt_start, last_exception)
                else:
                    # Non-retryable status code
                    return result

            except self.config.retry_on_exceptions as e:
                last_exception = e
                self._record_failed_attempt(attempt, attempt_start, e)

            # Don't sleep after last attempt
            if attempt < self.config.max_attempts:
                delay = self._calculate_delay(attempt)
                await asyncio.sleep(delay)
                self.total_delay += delay

        raise last_exception or Exception("All retry attempts failed")
```

## Integration Testing

### End-to-End Validation

```python
class IntegrationValidator:
    """End-to-end validation for AI workflows"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.test_scenarios = []

    def add_scenario(self, scenario: 'TestScenario'):
        """Add a test scenario"""
        self.test_scenarios.append(scenario)

    async def run_all_scenarios(self) -> Dict:
        """Run all integration test scenarios"""
        results = {}

        for scenario in self.test_scenarios:
            print(f"Running scenario: {scenario.name}")
            try:
                result = await scenario.run(self.project_root)
                results[scenario.name] = {
                    'success': True,
                    'result': result,
                    'duration': result.get('duration', 0)
                }
            except Exception as e:
                results[scenario.name] = {
                    'success': False,
                    'error': str(e),
                    'duration': 0
                }

        return {
            'total_scenarios': len(self.test_scenarios),
            'successful_scenarios': sum(1 for r in results.values() if r['success']),
            'results': results
        }

class TestScenario:
    """Base class for test scenarios"""

    def __init__(self, name: str):
        self.name = name

    async def run(self, project_root: Path) -> Dict:
        """Run the test scenario"""
        raise NotImplementedError

class ScenarioPRWorkflow(TestScenario):
    """Test scenario for PR workflow"""

    def __init__(self):
        super().__init__("pr_workflow")

    async def run(self, project_root: Path) -> Dict:
        """Test PR creation workflow"""
        start_time = time.time()

        # Create test issue
        # Trigger AI workflow
        # Verify PR creation
        # Validate PR content

        duration = time.time() - start_time

        return {
            'duration': duration,
            'pr_created': True,
            'validation_passed': True,
            'files_modified': 3
        }

class ScenarioCIFix(TestScenario):
    """Test scenario for CI fix workflow"""

    def __init__(self):
        super().__init__("ci_fix")

    async def run(self, project_root: Path) -> Dict:
        """Test CI fix workflow"""
        start_time = time.time()

        # Introduce deliberate error
        # Trigger CI
        # Wait for AI fix
        # Verify fix

        duration = time.time() - start_time

        return {
            'duration': duration,
            'error_introduced': True,
            'fix_applied': True,
            'ci_passed': True
        }
```

## Best Practices

### Error Handling Guidelines

1. **Specific Error Types**: Use specific exception types for different error scenarios
2. **Context Preservation**: Maintain context throughout error handling
3. **Graceful Degradation**: Continue with partial success when possible
4. **Clear Error Messages**: Provide actionable error messages
5. **Error Aggregation**: Collect and report multiple errors when appropriate

### Validation Best Practices

1. **Early Validation**: Validate inputs early in the pipeline
2. **Incremental Validation**: Validate at each stage of processing
3. **Comprehensive Coverage**: Validate all aspects of the system
4. **Performance Considerations**: Optimize validation for speed
5. **Feedback Loops**: Use validation results to improve the system

### Retry Strategy Guidelines

1. **Exponential Backoff**: Use exponential backoff for API calls
2. **Jitter**: Add jitter to avoid thundering herd problems
3. **Circuit Breaking**: Stop retrying after consecutive failures
4. **Idempotency**: Ensure operations are idempotent
5. **Monitoring**: Track retry metrics for optimization

---

*Document Version*: 1.0
*Last Updated*: 2025-10-15