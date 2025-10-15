#!/usr/bin/env python3
"""
Security Manager for Claude Code Integration

This module provides comprehensive security management including access control,
secret scanning, security policy enforcement, and audit logging for Claude Code operations.
"""

import json
import hashlib
import hmac
import subprocess
import asyncio
import sys
import os
import logging
import re
from pathlib import Path
from typing import Dict, List, Any, Optional, Set, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
from datetime import datetime, timedelta
import base64


class SecurityLevel(Enum):
    """Security levels for operations"""
    PUBLIC = "public"
    INTERNAL = "internal"
    CONFIDENTIAL = "confidential"
    RESTRICTED = "restricted"


class Permission(Enum):
    """User permissions"""
    READ = "read"
    WRITE = "write"
    ADMIN = "admin"
    SECURITY_ADMIN = "security_admin"


class OperationType(Enum):
    """Types of operations that can be performed"""
    READ_FILE = "read_file"
    WRITE_FILE = "write_file"
    EXECUTE_COMMAND = "execute_command"
    MODIFY_CODE = "modify_code"
    RUN_TESTS = "run_tests"
    ACCESS_SECRETS = "access_secrets"
    MODIFY_WORKFLOW = "modify_workflow"
    CROSS_PROJECT = "cross_project"


@dataclass
class SecurityPolicy:
    """Security policy configuration"""
    name: str
    description: str
    security_level: SecurityLevel
    required_permissions: List[Permission]
    allowed_operations: List[OperationType]
    restricted_patterns: List[str]
    max_file_size_mb: int
    allowed_file_extensions: List[str]
    secret_detection_enabled: bool
    audit_logging: bool
    approval_required: bool


@dataclass
class SecurityContext:
    """Security context for an operation"""
    user: str
    repository: str
    branch: str
    commit_hash: str
    operation: OperationType
    target_paths: List[str]
    timestamp: datetime
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None


@dataclass
class SecurityViolation:
    """Security violation record"""
    timestamp: datetime
    user: str
    operation: OperationType
    violation_type: str
    description: str
    severity: str  # low, medium, high, critical
    file_path: Optional[str] = None
    blocked: bool = True


@dataclass
class AuditLog:
    """Audit log entry"""
    timestamp: datetime
    user: str
    operation: OperationType
    target: str
    result: str  # success, failure, blocked
    details: Dict[str, Any]
    security_level: SecurityLevel


class SecurityManager:
    """Manages security policies and enforcement"""

    def __init__(self, config_dir: Optional[Path] = None):
        self.config_dir = config_dir or Path(".github/security")
        self.policies_file = self.config_dir / "policies.json"
        self.secrets_file = self.config_dir / "secrets_patterns.json"
        self.audit_log_file = self.config_dir / "audit.log"
        self.violations_file = self.config_dir / "violations.json"

        self.policies: Dict[str, SecurityPolicy] = {}
        self.secrets_patterns: List[re.Pattern] = []
        self.audit_logs: List[AuditLog] = []
        self.violations: List[SecurityViolation] = []

        self.logger = self._setup_logging()

        # Initialize security
        self._initialize_security()

    def _setup_logging(self) -> logging.Logger:
        """Setup logging configuration"""
        logger = logging.getLogger("security_manager")
        logger.setLevel(logging.INFO)

        if not logger.handlers:
            handler = logging.StreamHandler(sys.stderr)
            formatter = logging.Formatter(
                '%(asctime)s - %s - %s - %s',
                '%Y-%m-%d %H:%M:%S'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        return logger

    def _initialize_security(self):
        """Initialize security configuration"""
        # Create config directory
        self.config_dir.mkdir(parents=True, exist_ok=True)

        # Load policies
        self._load_policies()

        # Load secrets patterns
        self._load_secrets_patterns()

        # Load audit logs
        self._load_audit_logs()

        # Load violations
        self._load_violations()

    def _load_policies(self):
        """Load security policies"""
        if self.policies_file.exists():
            try:
                with open(self.policies_file, 'r') as f:
                    policies_data = json.load(f)

                for policy_name, policy_data in policies_data.items():
                    self.policies[policy_name] = SecurityPolicy(
                        name=policy_name,
                        description=policy_data['description'],
                        security_level=SecurityLevel(policy_data['security_level']),
                        required_permissions=[Permission(p) for p in policy_data['required_permissions']],
                        allowed_operations=[OperationType(op) for op in policy_data['allowed_operations']],
                        restricted_patterns=policy_data.get('restricted_patterns', []),
                        max_file_size_mb=policy_data.get('max_file_size_mb', 10),
                        allowed_file_extensions=policy_data.get('allowed_file_extensions', []),
                        secret_detection_enabled=policy_data.get('secret_detection_enabled', True),
                        audit_logging=policy_data.get('audit_logging', True),
                        approval_required=policy_data.get('approval_required', False)
                    )
            except (json.JSONDecodeError, KeyError, ValueError) as e:
                self.logger.error(f"Invalid policies file: {e}")
                self._create_default_policies()
        else:
            self._create_default_policies()

    def _create_default_policies(self):
        """Create default security policies"""
        default_policies = {
            "public_read": SecurityPolicy(
                name="public_read",
                description="Public read access to non-sensitive files",
                security_level=SecurityLevel.PUBLIC,
                required_permissions=[Permission.READ],
                allowed_operations=[OperationType.READ_FILE],
                restricted_patterns=[r".*\.key$", r".*\.pem$", r".*/\.github/.*\.json$"],
                max_file_size_mb=5,
                allowed_file_extensions=[".md", ".txt", ".py", ".js", ".json", ".yaml", ".yml"],
                secret_detection_enabled=False,
                audit_logging=True,
                approval_required=False
            ),
            "developer_write": SecurityPolicy(
                name="developer_write",
                description="Developer write access to source code",
                security_level=SecurityLevel.INTERNAL,
                required_permissions=[Permission.WRITE],
                allowed_operations=[
                    OperationType.READ_FILE, OperationType.WRITE_FILE,
                    OperationType.MODIFY_CODE, OperationType.RUN_TESTS
                ],
                restricted_patterns=[
                    r".*/\.github/secrets/.*",
                    r".*\.key$", r".*\.pem$", r".*\.p12$",
                    r".*/node_modules/.*", r".*/target/.*", r".*/build/.*",
                    r".*\.(exe|dll|so|dylib)$"
                ],
                max_file_size_mb=50,
                allowed_file_extensions=[".py", ".js", ".ts", ".java", ".cpp", ".hpp", ".md", ".json", ".yaml", ".yml"],
                secret_detection_enabled=True,
                audit_logging=True,
                approval_required=False
            ),
            "admin_access": SecurityPolicy(
                name="admin_access",
                description="Administrative access to repository management",
                security_level=SecurityLevel.RESTRICTED,
                required_permissions=[Permission.ADMIN],
                allowed_operations=list(OperationType),
                restricted_patterns=[],
                max_file_size_mb=100,
                allowed_file_extensions=[],
                secret_detection_enabled=True,
                audit_logging=True,
                approval_required=True
            ),
            "security_admin": SecurityPolicy(
                name="security_admin",
                description="Security administrator access",
                security_level=SecurityLevel.RESTRICTED,
                required_permissions=[Permission.SECURITY_ADMIN],
                allowed_operations=list(OperationType),
                restricted_patterns=[],
                max_file_size_mb=100,
                allowed_file_extensions=[],
                secret_detection_enabled=True,
                audit_logging=True,
                approval_required=False
            )
        }

        self.policies = default_policies
        self._save_policies()

    def _save_policies(self):
        """Save security policies"""
        policies_data = {}
        for policy_name, policy in self.policies.items():
            policies_data[policy_name] = {
                "description": policy.description,
                "security_level": policy.security_level.value,
                "required_permissions": [p.value for p in policy.required_permissions],
                "allowed_operations": [op.value for op in policy.allowed_operations],
                "restricted_patterns": policy.restricted_patterns,
                "max_file_size_mb": policy.max_file_size_mb,
                "allowed_file_extensions": policy.allowed_file_extensions,
                "secret_detection_enabled": policy.secret_detection_enabled,
                "audit_logging": policy.audit_logging,
                "approval_required": policy.approval_required
            }

        with open(self.policies_file, 'w') as f:
            json.dump(policies_data, f, indent=2)

    def _load_secrets_patterns(self):
        """Load secrets detection patterns"""
        if self.secrets_file.exists():
            try:
                with open(self.secrets_file, 'r') as f:
                    patterns_data = json.load(f)

                self.secrets_patterns = []
                for pattern in patterns_data.get('patterns', []):
                    self.secrets_patterns.append(re.compile(pattern, re.IGNORECASE))
            except (json.JSONDecodeError, re.error) as e:
                self.logger.error(f"Invalid secrets patterns file: {e}")
                self._create_default_secrets_patterns()
        else:
            self._create_default_secrets_patterns()

    def _create_default_secrets_patterns(self):
        """Create default secrets detection patterns"""
        default_patterns = [
            # API Keys
            r"api[_-]?key['\"\\s]*[:=]['\"\\s]*[a-zA-Z0-9_\-]{16,}",
            r"secret[_-]?key['\"\\s]*[:=]['\"\\s]*[a-zA-Z0-9_\-]{16,}",

            # AWS
            r"AKIA[0-9A-Z]{16}",
            r"aws[_-]?secret[_-]?access[_-]?key['\"\\s]*[:=]['\"\\s]*[a-zA-Z0-9/+=]{40}",

            # GitHub
            r"ghp_[a-zA-Z0-9]{36}",
            r"gho_[a-zA-Z0-9]{36}",
            r"ghu_[a-zA-Z0-9]{36}",
            r"ghs_[a-zA-Z0-9]{36}",
            r"ghr_[a-zA-Z0-9]{36}",

            # Database URLs
            r"(mysql|postgresql|mongodb)://[^\s'\"]+:[^\s'\"]+@[^\s'\"]+",

            # JWT tokens
            r"eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*",

            # Private keys
            r"-----BEGIN (RSA |OPENSSH |DSA |EC |PGP )?PRIVATE KEY-----",

            # Certificates
            r"-----BEGIN CERTIFICATE-----",

            # Passwords in URLs
            r"[a-zA-Z][a-zA-Z0-9+.-]*://[^\s'\"]*:[^\s'\"]+@[^\s'\"]+",

            # Generic base64 secrets
            r"[A-Za-z0-9+/]{32,}={0,2}",
        ]

        self.secrets_patterns = [re.compile(pattern, re.IGNORECASE) for pattern in default_patterns]
        self._save_secrets_patterns()

    def _save_secrets_patterns(self):
        """Save secrets patterns"""
        patterns_data = {
            "patterns": [pattern.pattern for pattern in self.secrets_patterns],
            "updated_at": datetime.now().isoformat()
        }

        with open(self.secrets_file, 'w') as f:
            json.dump(patterns_data, f, indent=2)

    def _load_audit_logs(self):
        """Load audit logs"""
        if self.audit_log_file.exists():
            try:
                with open(self.audit_log_file, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line:
                            log_data = json.loads(line)
                            self.audit_logs.append(AuditLog(
                                timestamp=datetime.fromisoformat(log_data['timestamp']),
                                user=log_data['user'],
                                operation=OperationType(log_data['operation']),
                                target=log_data['target'],
                                result=log_data['result'],
                                details=log_data['details'],
                                security_level=SecurityLevel(log_data['security_level'])
                            ))
            except (json.JSONDecodeError, KeyError, ValueError) as e:
                self.logger.error(f"Invalid audit log file: {e}")

    def _load_violations(self):
        """Load security violations"""
        if self.violations_file.exists():
            try:
                with open(self.violations_file, 'r') as f:
                    violations_data = json.load(f)

                self.violations = []
                for violation_data in violations_data:
                    self.violations.append(SecurityViolation(
                        timestamp=datetime.fromisoformat(violation_data['timestamp']),
                        user=violation_data['user'],
                        operation=OperationType(violation_data['operation']),
                        violation_type=violation_data['violation_type'],
                        description=violation_data['description'],
                        severity=violation_data['severity'],
                        file_path=violation_data.get('file_path'),
                        blocked=violation_data.get('blocked', True)
                    ))
            except (json.JSONDecodeError, KeyError, ValueError) as e:
                self.logger.error(f"Invalid violations file: {e}")

    def check_permission(self, user: str, required_permission: Permission) -> bool:
        """Check if user has required permission"""
        # In a real implementation, this would check against a user database
        # For now, we'll use GitHub permissions
        try:
            # Get user permissions from GitHub
            result = subprocess.run(
                ["gh", "api", "repos/{}/{}/collaborators/{}" .format(
                    os.environ.get('GITHUB_REPOSITORY', '').split('/')[0],
                    os.environ.get('GITHUB_REPOSITORY', '').split('/')[1],
                    user
                )],
                capture_output=True, text=True
            )

            if result.returncode == 0:
                permissions = json.loads(result.stdout).get('permissions', {})

                permission_map = {
                    Permission.READ: permissions.get('pull', False),
                    Permission.WRITE: permissions.get('push', False),
                    Permission.ADMIN: permissions.get('admin', False),
                    Permission.SECURITY_ADMIN: permissions.get('admin', False) and user in self._get_security_admins()
                }

                return permission_map.get(required_permission, False)
        except Exception as e:
            self.logger.error(f"Failed to check permissions for {user}: {e}")

        return False

    def _get_security_admins(self) -> Set[str]:
        """Get list of security administrators"""
        # In a real implementation, this would come from a configuration file or database
        return {"owner", "security-team"}  # Default security admins

    def check_operation_allowed(self, context: SecurityContext, policy_name: str) -> Tuple[bool, List[str]]:
        """Check if operation is allowed under security policy"""
        if policy_name not in self.policies:
            return False, [f"Unknown security policy: {policy_name}"]

        policy = self.policies[policy_name]
        violations = []

        # Check user permissions
        for required_permission in policy.required_permissions:
            if not self.check_permission(context.user, required_permission):
                violations.append(f"User {context.user} lacks required permission: {required_permission.value}")

        # Check operation type
        if context.operation not in policy.allowed_operations:
            violations.append(f"Operation {context.operation.value} not allowed under policy {policy_name}")

        # Check target paths
        for target_path in context.target_paths:
            # Check restricted patterns
            for pattern in policy.restricted_patterns:
                if re.match(pattern, target_path):
                    violations.append(f"Path {target_path} matches restricted pattern: {pattern}")

            # Check file extension
            if policy.allowed_file_extensions:
                file_ext = Path(target_path).suffix.lower()
                if file_ext not in policy.allowed_file_extensions:
                    violations.append(f"File extension {file_ext} not allowed: {target_path}")

            # Check file size
            if os.path.exists(target_path):
                file_size_mb = os.path.getsize(target_path) / (1024 * 1024)
                if file_size_mb > policy.max_file_size_mb:
                    violations.append(f"File too large: {target_path} ({file_size_mb:.1f}MB > {policy.max_file_size_mb}MB)")

            # Check for secrets
            if policy.secret_detection_enabled:
                secrets = self._scan_file_for_secrets(target_path)
                if secrets:
                    violations.extend([f"Secret detected in {target_path}: {secret}" for secret in secrets])

        # Check approval requirement
        if policy.approval_required:
            if not self._check_approval(context):
                violations.append(f"Operation requires approval: {context.operation.value}")

        is_allowed = len(violations) == 0
        return is_allowed, violations

    def _scan_file_for_secrets(self, file_path: str) -> List[str]:
        """Scan file for potential secrets"""
        secrets = []

        if not os.path.exists(file_path):
            return secrets

        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()

            for pattern in self.secrets_patterns:
                matches = pattern.findall(content)
                if matches:
                    for match in matches:
                        # Mask the actual secret in the log
                        masked_secret = self._mask_secret(match)
                        secrets.append(f"{pattern.pattern}: {masked_secret}")

        except (UnicodeDecodeError, IOError) as e:
            self.logger.error(f"Failed to scan file {file_path} for secrets: {e}")

        return secrets

    def _mask_secret(self, secret: str) -> str:
        """Mask a secret for logging"""
        if len(secret) <= 8:
            return "*" * len(secret)
        return secret[:4] + "*" * (len(secret) - 8) + secret[-4:]

    def _check_approval(self, context: SecurityContext) -> bool:
        """Check if operation has been approved"""
        # In a real implementation, this would check against an approval system
        # For now, we'll check for approvals in PR comments or issues
        try:
            # Look for approval in recent commits or PR discussions
            result = subprocess.run(
                ["gh", "search", "issues", "--repo", context.repository,
                 "--author", context.user, "--in", "body", f"approve {context.operation.value}"],
                capture_output=True, text=True
            )

            return result.returncode == 0 and len(result.stdout.strip()) > 0
        except Exception as e:
            self.logger.error(f"Failed to check approval for {context.operation.value}: {e}")
            return False

    def log_audit(self, context: SecurityContext, result: str, details: Dict[str, Any], security_level: SecurityLevel):
        """Log audit entry"""
        audit_log = AuditLog(
            timestamp=datetime.now(),
            user=context.user,
            operation=context.operation,
 target=str(context.target_paths) if context.target_paths else "",
            result=result,
            details=details,
            security_level=security_level
        )

        self.audit_logs.append(audit_log)

        # Write to file
        log_entry = {
            "timestamp": audit_log.timestamp.isoformat(),
            "user": audit_log.user,
            "operation": audit_log.operation.value,
            "target": audit_log.target,
            "result": audit_log.result,
            "details": audit_log.details,
            "security_level": audit_log.security_level.value
        }

        with open(self.audit_log_file, 'a') as f:
            f.write(json.dumps(log_entry) + '\n')

        # Keep only last 1000 logs in memory
        if len(self.audit_logs) > 1000:
            self.audit_logs = self.audit_logs[-1000:]

    def log_violation(self, context: SecurityContext, violation_type: str, description: str, severity: str, file_path: Optional[str] = None, blocked: bool = True):
        """Log security violation"""
        violation = SecurityViolation(
            timestamp=datetime.now(),
            user=context.user,
            operation=context.operation,
            violation_type=violation_type,
            description=description,
            severity=severity,
            file_path=file_path,
            blocked=blocked
        )

        self.violations.append(violation)

        # Write to file
        violations_data = []
        if self.violations_file.exists():
            try:
                with open(self.violations_file, 'r') as f:
                    violations_data = json.load(f)
            except json.JSONDecodeError:
                pass

        violations_data.append({
            "timestamp": violation.timestamp.isoformat(),
            "user": violation.user,
            "operation": violation.operation.value,
            "violation_type": violation.violation_type,
            "description": violation.description,
            "severity": violation.severity,
            "file_path": violation.file_path,
            "blocked": violation.blocked
        })

        with open(self.violations_file, 'w') as f:
            json.dump(violations_data, f, indent=2)

        # Log to system
        self.logger.warning(f"Security violation: {description} (User: {context.user}, Operation: {context.operation.value})")

    def get_security_summary(self, days: int = 30) -> Dict[str, Any]:
        """Get security summary for the last N days"""
        cutoff_date = datetime.now() - timedelta(days=days)

        recent_audits = [log for log in self.audit_logs if log.timestamp >= cutoff_date]
        recent_violations = [v for v in self.violations if v.timestamp >= cutoff_date]

        # Calculate statistics
        total_operations = len(recent_audits)
        blocked_operations = len([v for v in recent_violations if v.blocked])
        high_severity_violations = len([v for v in recent_violations if v.severity in ['high', 'critical']])

        # Top users by operations
        user_operations = {}
        for log in recent_audits:
            user_operations[log.user] = user_operations.get(log.user, 0) + 1

        # Top violation types
        violation_types = {}
        for v in recent_violations:
            violation_types[v.violation_type] = violation_types.get(v.violation_type, 0) + 1

        return {
            "period_days": days,
            "total_operations": total_operations,
            "blocked_operations": blocked_operations,
            "block_rate": (blocked_operations / max(total_operations, 1)) * 100,
            "high_severity_violations": high_severity_violations,
            "total_violations": len(recent_violations),
            "top_users_by_operations": sorted(user_operations.items(), key=lambda x: x[1], reverse=True)[:10],
            "top_violation_types": sorted(violation_types.items(), key=lambda x: x[1], reverse=True)[:10],
            "security_policies": list(self.policies.keys()),
            "secrets_patterns_count": len(self.secrets_patterns)
        }


async def main():
    """Main entry point for CLI usage"""
    import argparse

    parser = argparse.ArgumentParser(description="Security Manager")
    parser.add_argument("--config-dir", type=Path, help="Security configuration directory")
    parser.add_argument("action", choices=[
        "check-permission", "check-operation", "scan-secrets",
        "security-summary", "list-policies", "audit-log"
    ], help="Action to perform")
    parser.add_argument("--user", help="User name")
    parser.add_argument("--permission", choices=[p.value for p in Permission], help="Permission to check")
    parser.add_argument("--operation", choices=[op.value for op in OperationType], help="Operation type")
    parser.add_argument("--policy", help="Security policy to use")
    parser.add_argument("--target", help="Target path(s), comma-separated")
    parser.add_argument("--file", help="File to scan for secrets")
    parser.add_argument("--days", type=int, default=30, help="Days for security summary")

    args = parser.parse_args()

    manager = SecurityManager(args.config_dir)

    try:
        if args.action == "check-permission":
            if not args.user or not args.permission:
                print("Error: --user and --permission required", file=sys.stderr)
                sys.exit(1)

            has_permission = manager.check_permission(args.user, Permission(args.permission))
            print(f"User {args.user} has permission {args.permission}: {has_permission}")

        elif args.action == "check-operation":
            if not args.user or not args.operation or not args.policy:
                print("Error: --user, --operation, and --policy required", file=sys.stderr)
                sys.exit(1)

            target_paths = args.target.split(',') if args.target else []
            context = SecurityContext(
                user=args.user,
                repository=os.environ.get('GITHUB_REPOSITORY', ''),
                branch=os.environ.get('GITHUB_REF_NAME', 'main'),
                commit_hash=os.environ.get('GITHUB_SHA', ''),
                operation=OperationType(args.operation),
                target_paths=target_paths,
                timestamp=datetime.now()
            )

            is_allowed, violations = manager.check_operation_allowed(context, args.policy)
            print(f"Operation allowed: {is_allowed}")
            if violations:
                print("Violations:")
                for violation in violations:
                    print(f"  - {violation}")

        elif args.action == "scan-secrets":
            if not args.file:
                print("Error: --file required", file=sys.stderr)
                sys.exit(1)

            secrets = manager._scan_file_for_secrets(args.file)
            if secrets:
                print(f"Secrets detected in {args.file}:")
                for secret in secrets:
                    print(f"  - {secret}")
            else:
                print(f"No secrets detected in {args.file}")

        elif args.action == "security-summary":
            summary = manager.get_security_summary(args.days)
            print(json.dumps(summary, indent=2))

        elif args.action == "list-policies":
            policies_info = {}
            for name, policy in manager.policies.items():
                policies_info[name] = {
                    "description": policy.description,
                    "security_level": policy.security_level.value,
                    "required_permissions": [p.value for p in policy.required_permissions],
                    "allowed_operations": [op.value for op in policy.allowed_operations],
                    "secret_detection_enabled": policy.secret_detection_enabled,
                    "approval_required": policy.approval_required
                }
            print(json.dumps(policies_info, indent=2))

        elif args.action == "audit-log":
            recent_logs = manager.audit_logs[-20:]  # Last 20 logs
            logs_data = []
            for log in recent_logs:
                logs_data.append({
                    "timestamp": log.timestamp.isoformat(),
                    "user": log.user,
                    "operation": log.operation.value,
                    "target": log.target,
                    "result": log.result,
                    "security_level": log.security_level.value
                })
            print(json.dumps(logs_data, indent=2))

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())