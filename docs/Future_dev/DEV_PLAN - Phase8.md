
## Phase 8: Testing and Documentation (Week 4, Days 4-7)

### Objective
Comprehensive testing and documentation for the AI automation system.

### 8.1 Integration Tests

**Task**: Create end-to-end tests for AI workflows

**File**: `tests/integration/test_ai_workflows.py`

```python
"""
Integration tests for AI workflows.
"""

import pytest
import subprocess
import json
from pathlib import Path


class TestAIWorkflows:
    """Integration tests for AI-powered workflows"""

    @pytest.fixture
    def test_project(self, tmp_path):
        """Create a test project from cookiecutter template"""
        # Create Python test project
        subprocess.run([
            "cookiecutter",
            "cookiecutters/python-project",
            "--no-input",
            f"project_name=Test Project",
            f"use_ai_workflow=yes",
            f"output_dir={tmp_path}"
        ], check=True)

        project_dir = tmp_path / "test_project"
        return project_dir

    def test_claude_md_generated(self, test_project):
        """Test that CLAUDE.md is generated correctly"""
        claude_md = test_project / ".github" / "claude" / "CLAUDE.md"
        assert claude_md.exists()

        content = claude_md.read_text()
        assert "Test Project" in content
        assert "Python" in content

    def test_ai_workflows_present(self, test_project):
        """Test that AI workflow files are created"""
        workflows_dir = test_project / ".github" / "workflows"

        assert (workflows_dir / "ai-workflow.yaml").exists()
        assert (workflows_dir / "ai-fix-ci.yaml").exists()

    @pytest.mark.skipif(
        not os.getenv("ANTHROPIC_API_KEY"),
        reason="ANTHROPIC_API_KEY not set"
    )
    def test_claude_code_runner(self, test_project):
        """Test Claude Code runner with simple prompt"""
        result = subprocess.run([
            "python3",
            ".github/actions/claude-code-runner/scripts/run_claude_code.py",
            "--task-type", "review-pr",
            "--prompt", "Review this code: print('hello')",
            "--max-tokens", "10000"
        ], capture_output=True, text=True, cwd=test_project)

        assert result.returncode == 0

        # Parse output
        output = json.loads(result.stdout)
        assert "success" in output

    def test_error_parsing(self):
        """Test error log parsing"""
        from parse_results import ErrorLogParser

        parser = ErrorLogParser()

        sample_log = """
        tests/test_main.py::test_calculate FAILED
        tests/test_main.py:42: AssertionError: assert 42 == 43
        """

        errors = parser.parse(sample_log)
        assert len(errors) > 0
        assert errors[0].error_type.value == "test-failure"
        assert errors[0].line_number == 42

    def test_validation_pipeline(self, test_project):
        """Test validation pipeline"""
        from validation import ValidationPipeline, ValidationStage

        pipeline = ValidationPipeline(test_project, "python")

        # Run only format check for speed
        result = await pipeline.run_all([ValidationStage.FORMAT_CHECK])

        summary = pipeline.get_summary()
        assert summary["total_stages"] == 1
```

**Implementation Steps**:
1. Create test fixtures for projects
2. Write tests for each workflow component
3. Add integration tests for full workflows
4. Mock AI API calls for CI testing
5. Add performance benchmarks

**Deliverables**:
- [ ] Integration test suite
- [ ] Test fixtures and mocks
- [ ] CI integration for tests
- [ ] Performance benchmarks

### 8.2 Comprehensive Documentation

**Task**: Create detailed documentation for all components

**File**: `docs/AI_WORKFLOWS_GUIDE.md`

```markdown
# AI Workflows Guide

Complete guide to using AI-powered workflows in your CI/CD pipeline.

## Table of Contents

1. [Overview](#overview)
2. [Getting Started](#getting-started)
3. [Workflows](#workflows)
4. [Configuration](#configuration)
5. [Security](#security)
6. [Troubleshooting](#troubleshooting)

## Overview

The AI Workflow system provides automated code assistance using Claude Code CLI:

- **Automated PR Creation**: Convert issues to pull requests automatically
- **CI Failure Auto-Fix**: Detect and fix CI failures without manual intervention
- **Automated Code Review**: Get AI-powered code reviews on pull requests

### Architecture

```
┌─────────────────┐
│  GitHub Event   │ (Issue, PR, CI Failure)
└────────┬────────┘
         │
         v
┌─────────────────┐
│ AI Workflow     │
│ (GitHub Action) │
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Claude Code     │
│ Runner          │ (Python script)
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Validation      │
│ Pipeline        │ (Lint, Test, Build)
└────────┬────────┘
         │
         v
┌─────────────────┐
│ Commit & PR     │
└─────────────────┘
```

## Getting Started

### Prerequisites

1. Anthropic API key
2. GitHub repository with Actions enabled
3. Project created from our Cookiecutter templates

### Setup

#### 1. Add API Key to Secrets

```bash
# Organization level (recommended)
GitHub > Settings > Secrets > New organization secret
Name: ANTHROPIC_API_KEY
Value: sk-ant-...

# Or repository level
Repository > Settings > Secrets > New repository secret
Name: ANTHROPIC_API_KEY
Value: sk-ant-...
```

#### 2. Enable AI Workflows in Project

When creating a project:

```bash
bash scripts/create-project.sh python /path/to/project

# Answer "yes" to:
# - use_ai_workflow
# - enable_ai_fix_ci
# - enable_ai_pr_review
```

#### 3. Verify Setup

Check that these files exist:
- `.github/claude/CLAUDE.md`
- `.github/workflows/ai-workflow.yaml`
- `.github/workflows/ai-fix-ci.yaml`
