# Security Guidelines and Implementation

## Overview

This document outlines the comprehensive security measures implemented for the AI automation system. Security is a critical consideration when integrating AI capabilities into CI/CD workflows, as it involves handling code changes, API keys, and automated system access.

## Security Architecture

### Defense in Depth

```
Input Validation Layer
    ↓
Authentication & Authorization
    ↓
Permission Management
    ↓
Rate Limiting & Cost Controls
    ↓
Audit Logging & Monitoring
    ↓
Code Review & Human Oversight
    ↓
Secure Deployment Practices
```

## Input Validation and Sanitization

### Prevent Injection Attacks

#### GitHub Actions Implementation

```yaml
# .github/workflows/security-validation.yaml
name: Security Validation

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  validate-inputs:
    runs-on: ubuntu-latest
    steps:
      - name: Validate inputs
        run: |
          # Sanitize user input from issues/comments
          INPUT="${{ github.event.issue.body || github.event.comment.body }}"

          # Check for suspicious patterns
          if echo "$INPUT" | grep -E '(\$\(|\`|;|\||&)'; then
            echo "::error::Suspicious input detected - potential command injection"
            exit 1
          fi

          # Check for file path traversal attempts
          if echo "$INPUT" | grep -E '\.\./|\.\.\%2F'; then
            echo "::error::Path traversal attempt detected"
            exit 1
          fi

          # Check for excessive length
          if [ ${#INPUT} -gt 50000 ]; then
            echo "::error::Input too long - potential DoS attempt"
            exit 1
          fi
```

#### Python Implementation

```python
import re
import html
from typing import Optional, List
from pathlib import Path

class InputValidator:
    """Validates and sanitizes user inputs"""

    # Dangerous patterns
    DANGEROUS_PATTERNS = [
        r'\$\(',           # Command substitution
        r'`[^`]*`',        # Backtick execution
        r'[;&|]',          # Command chaining
        r'\.\./',          # Path traversal
        r'file://',        # File protocol
        r'javascript:',    # JavaScript protocol
        r'data:',          # Data protocol
    ]

    # Max input sizes
    MAX_PROMPT_LENGTH = 50000
    MAX_FILENAME_LENGTH = 255

    def __init__(self):
        self.compiled_patterns = [re.compile(pattern, re.IGNORECASE) for pattern in self.DANGEROUS_PATTERNS]

    def sanitize_prompt(self, prompt: str, max_length: Optional[int] = None) -> str:
        """
        Sanitize and limit prompt size.

        Args:
            prompt: Input prompt to sanitize
            max_length: Maximum allowed length

        Returns:
            Sanitized prompt
        """
        if max_length is None:
            max_length = self.MAX_PROMPT_LENGTH

        # Remove potential code injection vectors
        sanitized = prompt

        # Remove or escape dangerous patterns
        for pattern in self.compiled_patterns:
            sanitized = re.sub(pattern, '', sanitized)

        # HTML escape to prevent XSS
        sanitized = html.escape(sanitized)

        # Limit length
        if len(sanitized) > max_length:
            sanitized = sanitized[:max_length] + "\n\n[Input truncated due to length]"

        return sanitized.strip()

    def validate_filename(self, filename: str) -> bool:
        """
        Validate filename for security.

        Args:
            filename: Filename to validate

        Returns:
            True if safe, False otherwise
        """
        # Check length
        if len(filename) > self.MAX_FILENAME_LENGTH:
            return False

        # Check for dangerous patterns
        dangerous_chars = ['..', '/', '\\', ':', '*', '?', '"', '<', '>', '|']
        for char in dangerous_chars:
            if char in filename:
                return False

        # Check for reserved names (Windows)
        reserved_names = [
            'CON', 'PRN', 'AUX', 'NUL',
            'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
            'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9'
        ]
        if filename.upper() in reserved_names:
            return False

        return True

    def validate_file_path(self, file_path: str, allowed_directories: List[Path]) -> bool:
        """
        Validate that file path is within allowed directories.

        Args:
            file_path: File path to validate
            allowed_directories: List of allowed base directories

        Returns:
            True if safe, False otherwise
        """
        try:
            path = Path(file_path).resolve()

            # Check if path is within any allowed directory
            for allowed_dir in allowed_directories:
                allowed_resolved = allowed_dir.resolve()
                try:
                    path.relative_to(allowed_resolved)
                    return True
                except ValueError:
                    continue

            return False
        except (OSError, ValueError):
            return False

    def extract_code_blocks(self, text: str) -> List[str]:
        """
        Safely extract code blocks from user input.

        Args:
            text: Input text containing code blocks

        Returns:
            List of code blocks
        """
        code_blocks = []

        # Match markdown code blocks
        pattern = r'```(?:\w+)?\n(.*?)\n```'
        matches = re.findall(pattern, text, re.DOTALL)

        for match in matches:
            # Validate code block content
            if self._is_safe_code(match):
                code_blocks.append(match)

        return code_blocks

    def _is_safe_code(self, code: str) -> bool:
        """Check if code block contains dangerous content"""
        dangerous_imports = [
            'os.system', 'subprocess.call', 'subprocess.run',
            'eval', 'exec', '__import__', 'open', 'file',
            'socket', 'urllib', 'requests', 'http'
        ]

        code_lower = code.lower()
        for dangerous in dangerous_imports:
            if dangerous in code_lower:
                return False

        return True
```

## Authentication and Authorization

### API Key Management

#### GitHub Secrets Configuration

```yaml
# .github/workflows/ai-workflow.yaml
name: AI Workflow

permissions:
  contents: write
  issues: write
  pull-requests: write
  actions: read

jobs:
  ai-task:
    runs-on: ubuntu-latest
    steps:
      - name: Validate API key
        run: |
          if [ -z "$ANTHROPIC_API_KEY" ]; then
            echo "::error::ANTHROPIC_API_KEY is not set"
            exit 1
          fi

          # Basic API key format validation
          if [[ ! "$ANTHROPIC_API_KEY" =~ ^sk-ant- ]]; then
            echo "::error::Invalid API key format"
            exit 1
          fi
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Configure Claude Code with timeout
        timeout-minutes: 10
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
        run: |
          # Set timeout for API calls
          export ANTHROPIC_TIMEOUT=300

          # Configure Claude Code
          claude auth login
```

#### Secure Token Management

```python
import os
from typing import Optional
from cryptography.fernet import Fernet
import base64
import json

class SecureTokenManager:
    """Manages API tokens securely"""

    def __init__(self, encryption_key: Optional[bytes] = None):
        if encryption_key is None:
            # Use environment-specific key
            key_env = os.environ.get('ENCRYPTION_KEY')
            if key_env:
                encryption_key = base64.urlsafe_b64decode(key_env.encode())
            else:
                # Generate new key for development
                encryption_key = Fernet.generate_key()

        self.cipher = Fernet(encryption_key)

    def encrypt_token(self, token: str) -> str:
        """Encrypt API token"""
        encrypted = self.cipher.encrypt(token.encode())
        return base64.urlsafe_b64encode(encrypted).decode()

    def decrypt_token(self, encrypted_token: str) -> str:
        """Decrypt API token"""
        encrypted_bytes = base64.urlsafe_b64decode(encrypted_token.encode())
        decrypted = self.cipher.decrypt(encrypted_bytes)
        return decrypted.decode()

    def validate_token_format(self, token: str, provider: str = 'anthropic') -> bool:
        """Validate token format for specific provider"""
        if provider == 'anthropic':
            return token.startswith('sk-ant-') and len(token) > 50
        # Add other providers as needed
        return False

    def mask_token(self, token: str, visible_chars: int = 8) -> str:
        """Mask token for logging"""
        if len(token) <= visible_chars:
            return '*' * len(token)
        return token[:visible_chars] + '*' * (len(token) - visible_chars)
```

## Permission Management

### GitHub Actions Permissions

```yaml
# Minimum required permissions for workflows
permissions:
  contents: write        # Commit fixes
  issues: write          # Comment on issues
  pull-requests: write   # Create PRs
  models: read          # Access AI models
  actions: read         # Read workflow runs
  checks: read          # Read check runs
  deployments: read     # Read deployment status

# Security: Don't allow write access to:
# - admin: Full repository admin access
# - packages: Package publishing
# - pages: GitHub Pages publishing
# - workflows: Workflow file modification
```

### Branch Protection Rules

```yaml
# .github/workflows/setup-branch-protection.yaml
name: Setup Branch Protection

on:
  workflow_dispatch:
    inputs:
      branch:
        description: 'Branch to protect'
        required: true
        default: 'main'

jobs:
  setup-protection:
    runs-on: ubuntu-latest
    permissions:
      admin: write  # Required for branch protection
    steps:
      - name: Configure branch protection
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.repos.updateBranchProtection({
              owner: context.repo.owner,
              repo: context.repo.repo,
              branch: context.payload.inputs.branch,
              required_status_checks: {
                strict: true,
                contexts: [
                  'ci/python',
                  'ci/cpp',
                  'ai-safety-check',
                  'security-scan'
                ]
              },
              enforce_admins: true,
              required_pull_request_reviews: {
                required_approving_review_count: 2,
                dismiss_stale_reviews: true,
                require_code_owner_reviews: true,
                dismissal_restrictions: {
                  users: [],
                  teams: ['core-maintainers']
                }
              },
              restrictions: {
                users: [],
                teams: ['core-maintainers']
              }
            });
```

## Rate Limiting and Cost Controls

### API Usage Monitoring

```python
import time
import asyncio
from typing import Dict, Optional
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from collections import defaultdict, deque

@dataclass
class UsageMetrics:
    """API usage metrics"""
    timestamp: datetime
    tokens_used: int
    cost_usd: float
    request_duration: float
    success: bool

class RateLimiter:
    """Rate limiting for API calls"""

    def __init__(
        self,
        max_requests_per_minute: int = 60,
        max_tokens_per_minute: int = 100000,
        max_cost_per_hour: float = 10.0
    ):
        self.max_requests_per_minute = max_requests_per_minute
        self.max_tokens_per_minute = max_tokens_per_minute
        self.max_cost_per_hour = max_cost_per_hour

        self.requests = deque()
        self.tokens = deque()
        self.costs = deque()
        self.usage_history: list[UsageMetrics] = []

    async def acquire(self, estimated_tokens: int = 1000) -> bool:
        """
        Acquire permission to make API call.

        Args:
            estimated_tokens: Estimated tokens for this request

        Returns:
            True if request allowed, False otherwise
        """
        now = datetime.utcnow()
        minute_ago = now - timedelta(minutes=1)
        hour_ago = now - timedelta(hours=1)

        # Clean old entries
        self._clean_old_entries(minute_ago, hour_ago)

        # Check rate limits
        if len(self.requests) >= self.max_requests_per_minute:
            return False

        total_tokens = sum(self.tokens)
        if total_tokens + estimated_tokens > self.max_tokens_per_minute:
            return False

        total_cost = sum(self.costs)
        estimated_cost = self._estimate_cost(estimated_tokens)
        if total_cost + estimated_cost > self.max_cost_per_hour:
            return False

        # Record request
        self.requests.append(now)
        self.tokens.append(estimated_tokens)
        self.costs.append(estimated_cost)

        return True

    def _clean_old_entries(self, minute_ago: datetime, hour_ago: datetime):
        """Remove old entries from tracking"""
        # Clean requests (minute window)
        while self.requests and self.requests[0] < minute_ago:
            self.requests.popleft()
            self.tokens.popleft()

        # Clean costs (hour window)
        while self.costs and self.costs[0] < hour_ago:
            self.costs.popleft()

    def _estimate_cost(self, tokens: int) -> float:
        """Estimate cost based on token usage"""
        # Claude Sonnet pricing (approximate)
        cost_per_1k_tokens = 0.003  # $3 per million tokens
        return (tokens / 1000) * cost_per_1k_tokens

    def record_usage(self, metrics: UsageMetrics):
        """Record actual usage metrics"""
        self.usage_history.append(metrics)

        # Keep only last 24 hours
        day_ago = datetime.utcnow() - timedelta(days=1)
        self.usage_history = [
            m for m in self.usage_history if m.timestamp > day_ago
        ]

    def get_usage_stats(self) -> Dict:
        """Get current usage statistics"""
        now = datetime.utcnow()
        minute_ago = now - timedelta(minutes=1)
        hour_ago = now - timedelta(hours=1)
        day_ago = now - timedelta(days=1)

        recent_requests = [m for m in self.usage_history if m.timestamp > minute_ago]
        recent_tokens = sum(m.tokens_used for m in recent_requests)
        recent_cost = sum(m.cost_usd for m in self.usage_history if m.timestamp > hour_ago)

        return {
            'requests_per_minute': len(recent_requests),
            'tokens_per_minute': recent_tokens,
            'cost_per_hour': recent_cost,
            'success_rate': sum(1 for m in recent_requests if m.success) / len(recent_requests) if recent_requests else 0,
            'average_duration': sum(m.request_duration for m in recent_requests) / len(recent_requests) if recent_requests else 0
        }

class CostAlertManager:
    """Manages cost alerts and notifications"""

    def __init__(self, daily_budget: float = 50.0, alert_thresholds: list = None):
        self.daily_budget = daily_budget
        self.alert_thresholds = alert_thresholds or [0.5, 0.75, 0.9, 1.0]
        self.alerts_sent = set()

    async def check_budget(self, current_cost: float) -> Optional[str]:
        """Check if budget alerts should be sent"""
        budget_usage = current_cost / self.daily_budget

        for threshold in self.alert_thresholds:
            alert_key = f"threshold_{threshold}"
            if budget_usage >= threshold and alert_key not in self.alerts_sent:
                self.alerts_sent.add(alert_key)
                return self._create_alert_message(budget_usage, threshold)

        return None

    def _create_alert_message(self, usage: float, threshold: float) -> str:
        """Create budget alert message"""
        if threshold >= 1.0:
            return f"🚨 BUDGET EXCEEDED: Usage is {usage:.1%} of daily budget"
        elif threshold >= 0.9:
            return f"⚠️ HIGH USAGE: Usage is {usage:.1%} of daily budget"
        else:
            return f"ℹ️ USAGE UPDATE: Usage is {usage:.1%} of daily budget"
```

## Audit Logging

### Comprehensive Logging System

```python
import json
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path
import hashlib

class AuditLogger:
    """Comprehensive audit logging for AI operations"""

    def __init__(self, log_dir: Path):
        self.log_dir = log_dir
        self.log_dir.mkdir(parents=True, exist_ok=True)

        # Configure logging
        self.logger = logging.getLogger("claude-code-audit")
        self.logger.setLevel(logging.INFO)

        # File handler for audit logs
        handler = logging.FileHandler(log_dir / "audit.log")
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        handler.setFormatter(formatter)
        self.logger.addHandler(handler)

    def log_ai_operation(
        self,
        operation: str,
        user: str,
        prompt_summary: str,
        result: Dict[str, Any],
        metadata: Optional[Dict] = None
    ):
        """Log AI operations for audit trail"""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "operation": operation,
            "user": user,
            "prompt_hash": self._hash_sensitive_data(prompt_summary),
            "prompt_summary": prompt_summary[:200],  # First 200 chars
            "success": result.get("success", False),
            "files_modified": result.get("files_modified", []),
            "tokens_used": result.get("tokens_used", 0),
            "cost_estimate": result.get("cost_estimate", 0.0),
            "duration": result.get("duration", 0.0),
            "error_message": result.get("error", "")[:200] if result.get("error") else "",
            "metadata": metadata or {}
        }

        # Log to file
        self.logger.info(json.dumps(log_entry))

        # Also save as separate JSON file for analysis
        timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
        filename = f"operation_{operation}_{timestamp}.json"
        with open(self.log_dir / filename, 'w') as f:
            json.dump(log_entry, f, indent=2)

    def log_security_event(
        self,
        event_type: str,
        severity: str,
        description: str,
        source: str,
        metadata: Optional[Dict] = None
    ):
        """Log security events"""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "event_type": event_type,
            "severity": severity,  # low, medium, high, critical
            "description": description,
            "source": source,
            "metadata": metadata or {}
        }

        self.logger.warning(f"SECURITY: {json.dumps(log_entry)}")

        # Save critical events separately
        if severity in ["high", "critical"]:
            timestamp = datetime.utcnow().strftime("%Y%m%d_%H%M%S")
            filename = f"security_{event_type}_{timestamp}.json"
            with open(self.log_dir / filename, 'w') as f:
                json.dump(log_entry, f, indent=2)

    def log_file_access(
        self,
        file_path: str,
        operation: str,  # read, write, delete
        user: str,
        success: bool
    ):
        """Log file access operations"""
        log_entry = {
            "timestamp": datetime.utcnow().isoformat(),
            "operation": "file_access",
            "file_path": file_path,
            "access_type": operation,
            "user": user,
            "success": success
        }

        self.logger.info(f"FILE_ACCESS: {json.dumps(log_entry)}")

    def _hash_sensitive_data(self, data: str) -> str:
        """Hash sensitive data for logging"""
        return hashlib.sha256(data.encode()).hexdigest()[:16]

    def generate_audit_report(self, hours: int = 24) -> Dict:
        """Generate audit report for specified time period"""
        cutoff_time = datetime.utcnow() - timedelta(hours=hours)

        # Analyze recent logs
        recent_operations = []
        security_events = []

        # This would parse the actual log files
        # For now, return structure
        return {
            "period_hours": hours,
            "total_operations": len(recent_operations),
            "successful_operations": sum(1 for op in recent_operations if op["success"]),
            "total_cost": sum(op["cost_estimate"] for op in recent_operations),
            "total_tokens": sum(op["tokens_used"] for op in recent_operations),
            "files_modified": list(set(
                file for op in recent_operations for file in op["files_modified"]
            )),
            "security_events": security_events,
            "top_users": self._get_top_users(recent_operations),
            "error_rate": self._calculate_error_rate(recent_operations)
        }

    def _get_top_users(self, operations: list) -> list:
        """Get users with most operations"""
        user_counts = defaultdict(int)
        for op in operations:
            user_counts[op["user"]] += 1
        return sorted(user_counts.items(), key=lambda x: x[1], reverse=True)[:10]

    def _calculate_error_rate(self, operations: list) -> float:
        """Calculate error rate"""
        if not operations:
            return 0.0
        errors = sum(1 for op in operations if not op["success"])
        return errors / len(operations)
```

## Code Review and Human Oversight

### Automated Code Review Integration

```yaml
# .github/workflows/ai-review-requirement.yaml
name: AI Review Requirement

on:
  pull_request:
    types: [opened, synchronize]

jobs:
  require-ai-review:
    runs-on: ubuntu-latest
    steps:
      - name: Check for AI-generated changes
        uses: actions/github-script@v7
        with:
          script: |
            const { data: files } = await github.rest.pulls.listFiles({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: context.issue.number
            });

            // Check if any files were modified by AI
            const aiModifiedFiles = files.filter(file =>
              file.filename.startsWith('.github/') ||
              file.filename === 'CLAUDE.md'
            );

            if (aiModifiedFiles.length > 0) {
              // Add label for required review
              await github.rest.issues.addLabels({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
                labels: ['requires-ai-review']
              });

              // Comment on PR
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: context.issue.number,
                body: `## 🔍 AI-Generated Changes Detected

                This PR contains changes made by AI automation. Please review carefully:

                **Files modified by AI:**
                ${aiModifiedFiles.map(f => `- \`${f.filename}\``).join('\n')}

                **Required reviews:**
                - [ ] Code quality and correctness
                - [ ] Security implications
                - [ ] Performance impact
                - [ ] Testing adequacy

                **Additional checks:**
                - [ ] All tests pass
                - [ ] No hardcoded secrets
                - [ ] Dependencies are secure
                - [ ] Documentation updated

                ---
                ⚠️ This PR requires at least 2 human approvals before merging.`
              });
            }
```

### Security Scan Integration

```yaml
# .github/workflows/security-scan.yaml
name: Security Scan

on:
  pull_request:
    types: [opened, synchronize]
  push:
    branches: [main]

jobs:
  security-scan:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Run Trivy vulnerability scanner
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          format: 'sarif'
          output: 'trivy-results.sarif'

      - name: Upload Trivy scan results
        uses: github/codeql-action/upload-sarif@v3
        if: always()
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Run Bandit security scan (Python)
        if: hashFiles('**/*.py') != ''
        run: |
          pip install bandit
          bandit -r . -f json -o bandit-report.json || true

      - name: Run CodeQL Analysis
        uses: github/codeql-action/init@v3
        with:
          languages: python, cpp

      - name: Perform CodeQL Analysis
        uses: github/codeql-action/analyze@v3

      - name: Security check summary
        if: always()
        run: |
          echo "## Security Scan Summary" >> $GITHUB_STEP_SUMMARY
          echo "" >> $GITHUB_STEP_SUMMARY

          if [ -f "trivy-results.sarif" ]; then
            echo "### Trivy Results" >> $GITHUB_STEP_SUMMARY
            vulnerabilities=$(jq '.runs[0].results | length' trivy-results.sarif 2>/dev/null || echo "0")
            echo "- Vulnerabilities found: $vulnerabilities" >> $GITHUB_STEP_SUMMARY
          fi

          if [ -f "bandit-report.json" ]; then
            echo "### Bandit Results" >> $GITHUB_STEP_SUMMARY
            high_severity=$(jq '.results[] | select(.issue_severity == "HIGH") | .test_name' bandit-report.json | wc -l)
            echo "- High severity issues: $high_severity" >> $GITHUB_STEP_SUMMARY
          fi
```

## Best Practices Checklist

### Security Requirements

- [ ] **Input Validation**: All user inputs are validated and sanitized
- [ ] **Authentication**: API keys stored securely with proper validation
- [ ] **Authorization**: Minimum required permissions for workflows
- [ ] **Rate Limiting**: API usage is monitored and limited
- [ ] **Audit Logging**: All operations are logged for security review
- [ ] **Code Review**: AI-generated changes require human review
- [ ] **Secret Management**: No hardcoded secrets in code
- [ ] **Dependency Security**: Dependencies are scanned for vulnerabilities
- [ ] **Branch Protection**: Main branches are protected
- [ ] **Security Scanning**: Automated security scans in CI/CD

### Monitoring Requirements

- [ ] **Cost Monitoring**: Track API costs and set budgets
- [ ] **Usage Metrics**: Monitor token usage and request patterns
- [ ] **Error Rates**: Track and alert on high error rates
- [ ] **Performance**: Monitor response times and throughput
- [ ] **Security Events**: Alert on suspicious activities
- [ ] **Compliance**: Ensure adherence to security policies

### Incident Response

- [ ] **Incident Plan**: Documented security incident response plan
- [ ] **Alerting**: Automated alerts for security events
- [ ] **Isolation**: Ability to quickly isolate affected systems
- [ ] **Forensics**: Preserve logs for forensic analysis
- [ ] **Communication**: Plan for communicating security incidents
- [ ] **Recovery**: Procedures for system recovery

---

*Document Version*: 1.0
*Last Updated*: 2025-10-15