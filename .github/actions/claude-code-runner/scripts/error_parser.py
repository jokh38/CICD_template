#!/usr/bin/env python3
"""
Advanced error parsing and retry logic for AI workflow automation.
Implements intelligent error classification, adaptive retry strategies, and
contextual error recovery for Claude Code CLI integration.
"""

import json
import re
import sys
import time
import hashlib
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple, Union
from enum import Enum
from dataclasses import dataclass, asdict


class ErrorSeverity(Enum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"
    CRITICAL = "critical"


class ErrorCategory(Enum):
    SYNTAX = "syntax"
    DEPENDENCY = "dependency"
    CONFIGURATION = "configuration"
    RUNTIME = "runtime"
    NETWORK = "network"
    PERMISSION = "permission"
    TIMEOUT = "timeout"
    SYSTEM = "system"
    UNKNOWN = "unknown"


@dataclass
class ParsedError:
    """Structured representation of a parsed error"""
    raw_message: str
    category: ErrorCategory
    severity: ErrorSeverity
    file_path: Optional[str] = None
    line_number: Optional[int] = None
    error_code: Optional[str] = None
    context: Optional[Dict[str, Any]] = None
    suggested_fix: Optional[str] = None
    retry_recommended: bool = True
    estimated_fix_time: Optional[int] = None  # in seconds


@dataclass
class RetryStrategy:
    """Retry strategy configuration"""
    max_attempts: int
    base_delay: float
    max_delay: float
    exponential_base: float
    jitter: bool
    backoff_multiplier: float = 2.0


class ErrorClassifier:
    """Classifies errors into categories and severity levels"""

    def __init__(self):
        self.patterns = self._initialize_patterns()

    def _initialize_patterns(self) -> Dict[ErrorCategory, List[Dict[str, Any]]]:
        """Initialize error classification patterns"""
        return {
            ErrorCategory.SYNTAX: [
                {
                    "pattern": r"SyntaxError|syntax error|invalid syntax",
                    "severity": ErrorSeverity.HIGH,
                    "retry": False,
                    "fix_time": 300
                },
                {
                    "pattern": r"IndentationError|unexpected indent",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": False,
                    "fix_time": 180
                },
                {
                    "pattern": r"TypeError|type error",
                    "severity": ErrorSeverity.HIGH,
                    "retry": False,
                    "fix_time": 240
                }
            ],
            ErrorCategory.DEPENDENCY: [
                {
                    "pattern": r"ModuleNotFoundError|ImportError|No module named",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": False,
                    "fix_time": 120
                },
                {
                    "pattern": r"pip install.*failed|dependency.*not found",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": True,
                    "fix_time": 180
                },
                {
                    "pattern": r"cmake.*not found|make.*not found|gcc.*not found",
                    "severity": ErrorSeverity.HIGH,
                    "retry": False,
                    "fix_time": 600
                }
            ],
            ErrorCategory.CONFIGURATION: [
                {
                    "pattern": r"config.*error|configuration.*invalid",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": False,
                    "fix_time": 240
                },
                {
                    "pattern": r"environment.*variable.*not set|ENV.*missing",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": False,
                    "fix_time": 180
                }
            ],
            ErrorCategory.NETWORK: [
                {
                    "pattern": r"Connection.*refused|Network.*unreachable|timeout",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": True,
                    "fix_time": 60
                },
                {
                    "pattern": r"HTTP.*[45]\d\d|request.*failed",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": True,
                    "fix_time": 90
                }
            ],
            ErrorCategory.PERMISSION: [
                {
                    "pattern": r"Permission.*denied|access.*denied|Unauthorized",
                    "severity": ErrorSeverity.HIGH,
                    "retry": False,
                    "fix_time": 300
                },
                {
                    "pattern": r"read.*permission|write.*permission",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": False,
                    "fix_time": 180
                }
            ],
            ErrorCategory.TIMEOUT: [
                {
                    "pattern": r"timeout|timed out|time.*out",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": True,
                    "fix_time": 60
                }
            ],
            ErrorCategory.RUNTIME: [
                {
                    "pattern": r"RuntimeError|runtime.*error|execution.*failed",
                    "severity": ErrorSeverity.HIGH,
                    "retry": True,
                    "fix_time": 180
                },
                {
                    "pattern": r"AssertionError|assert.*failed",
                    "severity": ErrorSeverity.HIGH,
                    "retry": False,
                    "fix_time": 240
                }
            ],
            ErrorCategory.SYSTEM: [
                {
                    "pattern": r"OutOfMemoryError|memory.*error|disk.*full",
                    "severity": ErrorSeverity.CRITICAL,
                    "retry": False,
                    "fix_time": 600
                },
                {
                    "pattern": r"FileNotFoundError|file.*not found",
                    "severity": ErrorSeverity.MEDIUM,
                    "retry": False,
                    "fix_time": 120
                }
            ]
        }

    def classify_error(self, error_message: str) -> ParsedError:
        """Classify an error message into structured format"""

        # Extract file path and line number if present
        file_path, line_number = self._extract_location(error_message)

        # Extract error code if present
        error_code = self._extract_error_code(error_message)

        # Determine category and severity
        category, severity, retry_recommended, fix_time = self._categorize_error(error_message)

        # Generate suggested fix based on category
        suggested_fix = self._generate_fix_suggestion(error_message, category)

        # Extract additional context
        context = self._extract_context(error_message)

        return ParsedError(
            raw_message=error_message,
            category=category,
            severity=severity,
            file_path=file_path,
            line_number=line_number,
            error_code=error_code,
            context=context,
            suggested_fix=suggested_fix,
            retry_recommended=retry_recommended,
            estimated_fix_time=fix_time
        )

    def _extract_location(self, error_message: str) -> Tuple[Optional[str], Optional[int]]:
        """Extract file path and line number from error message"""
        # Common patterns for file:line references
        patterns = [
            r"File \"([^\"]+)\", line (\d+)",
            r"([^\s:]+):(\d+):",
            r"at ([^\s:]+):(\d+)",
            r"line (\d+) in ([^\s]+)"
        ]

        for pattern in patterns:
            match = re.search(pattern, error_message)
            if match:
                groups = match.groups()
                if len(groups) == 2:
                    # Determine order based on pattern
                    if "line" in pattern:
                        return groups[1], int(groups[0])
                    else:
                        return groups[0], int(groups[1])

        return None, None

    def _extract_error_code(self, error_message: str) -> Optional[str]:
        """Extract error codes from error message"""
        # Look for common error code patterns
        patterns = [
            r"[Ee]rror\s+([A-Z]\d{3,4})",
            r"[Ee]rrcode:\s*(\d+)",
            r"exit\s+code:\s*(\d+)",
            r"status:\s*(\d+)"
        ]

        for pattern in patterns:
            match = re.search(pattern, error_message)
            if match:
                return match.group(1)

        return None

    def _categorize_error(self, error_message: str) -> Tuple[ErrorCategory, ErrorSeverity, bool, int]:
        """Categorize error and determine retry strategy"""

        for category, patterns in self.patterns.items():
            for pattern_info in patterns:
                if re.search(pattern_info["pattern"], error_message, re.IGNORECASE):
                    return (
                        category,
                        pattern_info["severity"],
                        pattern_info["retry"],
                        pattern_info["fix_time"]
                    )

        # Default classification
        return ErrorCategory.UNKNOWN, ErrorSeverity.MEDIUM, True, 180

    def _generate_fix_suggestion(self, error_message: str, category: ErrorCategory) -> Optional[str]:
        """Generate fix suggestions based on error category"""

        suggestions = {
            ErrorCategory.SYNTAX: "Check for syntax errors, typos, or incorrect language constructs",
            ErrorCategory.DEPENDENCY: "Install missing dependencies or update package versions",
            ErrorCategory.CONFIGURATION: "Review and fix configuration files or environment variables",
            ErrorCategory.NETWORK: "Check network connectivity and firewall settings",
            ErrorCategory.PERMISSION: "Verify file/directory permissions and access rights",
            ErrorCategory.TIMEOUT: "Increase timeout values or optimize performance",
            ErrorCategory.RUNTIME: "Debug runtime logic and check program flow",
            ErrorCategory.SYSTEM: "Check system resources and disk space",
            ErrorCategory.UNKNOWN: "Review error logs and investigate root cause"
        }

        return suggestions.get(category)

    def _extract_context(self, error_message: str) -> Dict[str, Any]:
        """Extract additional context from error message"""
        context = {}

        # Extract stack trace information
        if "Traceback" in error_message:
            context["has_stack_trace"] = True
            lines = error_message.split('\n')
            context["stack_depth"] = len([l for l in lines if l.strip().startswith('File')])

        # Extract command or script name
        command_match = re.search(r"command ['\"]([^'\"]+)['\"]", error_message)
        if command_match:
            context["command"] = command_match.group(1)

        # Extract working directory if mentioned
        dir_match = re.search(r"directory ['\"]([^'\"]+)['\"]", error_message)
        if dir_match:
            context["directory"] = dir_match.group(1)

        return context


class RetryManager:
    """Manages retry logic with adaptive strategies"""

    def __init__(self):
        self.strategies = {
            ErrorCategory.SYNTAX: RetryStrategy(1, 0, 0, 1, False),  # No retry for syntax
            ErrorCategory.DEPENDENCY: RetryStrategy(3, 2, 30, 2, True),
            ErrorCategory.CONFIGURATION: RetryStrategy(2, 1, 10, 1.5, True),
            ErrorCategory.NETWORK: RetryStrategy(5, 1, 60, 2, True),
            ErrorCategory.PERMISSION: RetryStrategy(1, 0, 0, 1, False),  # No retry for permission
            ErrorCategory.TIMEOUT: RetryStrategy(3, 5, 120, 2.5, True),
            ErrorCategory.RUNTIME: RetryStrategy(3, 2, 45, 2, True),
            ErrorCategory.SYSTEM: RetryStrategy(2, 5, 180, 2, True),
            ErrorCategory.UNKNOWN: RetryStrategy(3, 1, 30, 2, True)
        }

        self.retry_history = {}

    def get_retry_strategy(self, error: ParsedError) -> RetryStrategy:
        """Get appropriate retry strategy for an error"""
        return self.strategies.get(error.category, self.strategies[ErrorCategory.UNKNOWN])

    def should_retry(self, error: ParsedError, attempt: int) -> bool:
        """Determine if an error should be retried"""
        if not error.retry_recommended:
            return False

        strategy = self.get_retry_strategy(error)
        return attempt < strategy.max_attempts

    def calculate_delay(self, error: ParsedError, attempt: int) -> float:
        """Calculate delay before next retry"""
        strategy = self.get_retry_strategy(error)

        # Exponential backoff with jitter
        delay = strategy.base_delay * (strategy.exponential_base ** attempt)
        delay = min(delay, strategy.max_delay)

        if strategy.jitter:
            # Add ±25% jitter
            jitter_range = delay * 0.25
            delay += (hash(str(error.raw_message) + str(attempt)) % 1000) / 1000 * jitter_range - jitter_range / 2

        return max(0, delay)

    def record_retry_attempt(self, error_id: str, attempt: int, success: bool):
        """Record retry attempt for learning"""
        if error_id not in self.retry_history:
            self.retry_history[error_id] = []

        self.retry_history[error_id].append({
            "attempt": attempt,
            "success": success,
            "timestamp": datetime.now().isoformat()
        })

    def get_retry_statistics(self) -> Dict[str, Any]:
        """Get retry statistics for optimization"""
        if not self.retry_history:
            return {}

        stats = {
            "total_errors": len(self.retry_history),
            "successful_retries": 0,
            "failed_retries": 0,
            "average_attempts": 0,
            "most_problematic_categories": {}
        }

        total_attempts = 0
        category_attempts = {}

        for error_id, attempts in self.retry_history.items():
            successful = any(a["success"] for a in attempts)
            if successful:
                stats["successful_retries"] += 1
            else:
                stats["failed_retries"] += 1

            stats["average_attempts"] += len(attempts)
            total_attempts += len(attempts)

        if stats["total_errors"] > 0:
            stats["average_attempts"] /= stats["total_errors"]

        return stats


class ErrorCache:
    """Caches error analyses for performance optimization"""

    def __init__(self, cache_dir: Path = Path(".github/cache/errors")):
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.cache_ttl = timedelta(hours=24)  # Cache for 24 hours

    def _get_error_hash(self, error_message: str) -> str:
        """Generate hash for error message"""
        return hashlib.md5(error_message.encode()).hexdigest()

    def _get_cache_path(self, error_hash: str) -> Path:
        """Get cache file path for error hash"""
        return self.cache_dir / f"{error_hash}.json"

    def get_cached_analysis(self, error_message: str) -> Optional[ParsedError]:
        """Get cached error analysis if available and not expired"""
        error_hash = self._get_error_hash(error_message)
        cache_path = self._get_cache_path(error_hash)

        if not cache_path.exists():
            return None

        try:
            with open(cache_path, 'r') as f:
                cache_data = json.load(f)

            # Check if cache is still valid
            cache_time = datetime.fromisoformat(cache_data["timestamp"])
            if datetime.now() - cache_time > self.cache_ttl:
                cache_path.unlink()  # Remove expired cache
                return None

            # Reconstruct ParsedError object
            data = cache_data["error_data"]
            return ParsedError(
                raw_message=data["raw_message"],
                category=ErrorCategory(data["category"]),
                severity=ErrorSeverity(data["severity"]),
                file_path=data.get("file_path"),
                line_number=data.get("line_number"),
                error_code=data.get("error_code"),
                context=data.get("context"),
                suggested_fix=data.get("suggested_fix"),
                retry_recommended=data.get("retry_recommended", True),
                estimated_fix_time=data.get("estimated_fix_time")
            )

        except Exception as e:
            print(f"Warning: Failed to load cache for {error_hash}: {e}", file=sys.stderr)
            return None

    def cache_analysis(self, error: ParsedError):
        """Cache error analysis for future use"""
        error_hash = self._get_error_hash(error.raw_message)
        cache_path = self._get_cache_path(error_hash)

        try:
            cache_data = {
                "timestamp": datetime.now().isoformat(),
                "error_data": asdict(error)
            }

            with open(cache_path, 'w') as f:
                json.dump(cache_data, f, indent=2)

        except Exception as e:
            print(f"Warning: Failed to cache analysis for {error_hash}: {e}", file=sys.stderr)

    def cleanup_expired_cache(self):
        """Remove expired cache entries"""
        for cache_file in self.cache_dir.glob("*.json"):
            try:
                with open(cache_file, 'r') as f:
                    cache_data = json.load(f)

                cache_time = datetime.fromisoformat(cache_data["timestamp"])
                if datetime.now() - cache_time > self.cache_ttl:
                    cache_file.unlink()

            except Exception as e:
                print(f"Warning: Failed to process cache file {cache_file}: {e}", file=sys.stderr)


class AdvancedErrorParser:
    """Main class for advanced error parsing and retry management"""

    def __init__(self, cache_dir: Optional[Path] = None):
        self.classifier = ErrorClassifier()
        self.retry_manager = RetryManager()
        self.cache = ErrorCache(cache_dir) if cache_dir else ErrorCache()

    def parse_errors(self, error_output: str) -> List[ParsedError]:
        """Parse multiple errors from output string"""
        errors = []

        # Split error output into individual error messages
        error_messages = self._split_error_messages(error_output)

        for error_msg in error_messages:
            # Check cache first
            cached_error = self.cache.get_cached_analysis(error_msg)
            if cached_error:
                errors.append(cached_error)
                continue

            # Parse and classify error
            parsed_error = self.classifier.classify_error(error_msg)

            # Cache the analysis
            self.cache.cache_analysis(parsed_error)

            errors.append(parsed_error)

        return errors

    def _split_error_messages(self, error_output: str) -> List[str]:
        """Split error output into individual error messages"""
        # Common error message separators
        separators = [
            r'\n\s*\n',  # Double newlines
            r';\s*',     # Semicolons
            r'\|\s*',    # Pipe characters
            r'---+',     # Dashes
        ]

        messages = [error_output.strip()]

        for separator in separators:
            new_messages = []
            for msg in messages:
                new_messages.extend(re.split(separator, msg))
            messages = [m.strip() for m in new_messages if m.strip()]

        return messages

    def should_retry_execution(self, errors: List[ParsedError], attempt: int) -> bool:
        """Determine if execution should be retried based on errors"""
        if not errors:
            return False

        # Check if any error allows retry
        for error in errors:
            if self.retry_manager.should_retry(error, attempt):
                return True

        return False

    def calculate_retry_delay(self, errors: List[ParsedError], attempt: int) -> float:
        """Calculate delay before retry based on errors"""
        if not errors:
            return 0

        # Use the maximum delay from all errors
        max_delay = 0
        for error in errors:
            delay = self.retry_manager.calculate_delay(error, attempt)
            max_delay = max(max_delay, delay)

        return max_delay

    def generate_error_summary(self, errors: List[ParsedError]) -> Dict[str, Any]:
        """Generate summary of errors for reporting"""
        if not errors:
            return {"total_errors": 0, "errors": []}

        summary = {
            "total_errors": len(errors),
            "severity_breakdown": {},
            "category_breakdown": {},
            "files_affected": set(),
            "estimated_total_fix_time": 0,
            "retry_recommended": False,
            "errors": []
        }

        for error in errors:
            # Count by severity
            severity = error.severity.value
            summary["severity_breakdown"][severity] = summary["severity_breakdown"].get(severity, 0) + 1

            # Count by category
            category = error.category.value
            summary["category_breakdown"][category] = summary["category_breakdown"].get(category, 0) + 1

            # Track affected files
            if error.file_path:
                summary["files_affected"].add(error.file_path)

            # Sum fix times
            if error.estimated_fix_time:
                summary["estimated_total_fix_time"] += error.estimated_fix_time

            # Check if any error recommends retry
            if error.retry_recommended:
                summary["retry_recommended"] = True

            # Add error details
            summary["errors"].append({
                "message": error.raw_message,
                "category": error.category.value,
                "severity": error.severity.value,
                "file_path": error.file_path,
                "line_number": error.line_number,
                "suggested_fix": error.suggested_fix,
                "retry_recommended": error.retry_recommended
            })

        # Convert set to list for JSON serialization
        summary["files_affected"] = list(summary["files_affected"])

        return summary

    def cleanup(self):
        """Cleanup resources"""
        self.cache.cleanup_expired_cache()


def main():
    """Main entry point for command-line usage"""
    if len(sys.argv) < 2:
        print("Usage: python error_parser.py <error_output_file> [--retry-attempt N]", file=sys.stderr)
        sys.exit(1)

    error_file = Path(sys.argv[1])
    retry_attempt = 0

    if len(sys.argv) > 2 and sys.argv[2] == "--retry-attempt" and len(sys.argv) > 3:
        retry_attempt = int(sys.argv[3])

    if not error_file.exists():
        print(f"Error: Error file {error_file} not found", file=sys.stderr)
        sys.exit(1)

    try:
        # Read error output
        with open(error_file, 'r') as f:
            error_output = f.read()

        # Parse errors
        parser = AdvancedErrorParser()
        errors = parser.parse_errors(error_output)

        # Generate analysis
        summary = parser.generate_error_summary(errors)

        # Determine retry strategy
        should_retry = parser.should_retry_execution(errors, retry_attempt)
        retry_delay = parser.calculate_retry_delay(errors, retry_attempt)

        # Output results
        result = {
            "success": False,
            "errors_parsed": True,
            "total_errors": len(errors),
            "should_retry": should_retry,
            "retry_delay": retry_delay,
            "retry_attempt": retry_attempt,
            "error_summary": summary,
            "retry_statistics": parser.retry_manager.get_retry_statistics()
        }

        print(json.dumps(result, indent=2))

        # Set appropriate exit code
        sys.exit(0 if not errors or should_retry else 1)

    except Exception as e:
        print(f"Error parsing errors: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()