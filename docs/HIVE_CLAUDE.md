## AI-Powered GitHub Workflow Control System Documentation

### Overview

This system enables complete control of the development workflow through **GitHub labels** and **slash commands** that trigger automated AI workflows. Users can manage the entire development lifecycle—including issue creation, code review, testing, building, PR creation, and merging—by simply adding labels to issues or using specific commands in comments.

### System Architecture

1.  **User**: Triggers workflows by adding **GitHub labels** to issues or using **slash commands** in comments
2.  **GitHub Actions**: Automatically detects labels/commands and triggers appropriate AI workflows
3.  **Claude (AI Assistant)**:
    * Executes development tasks based on triggered workflows
    * Performs code analysis, building, testing, and PR management
    * Reports results and logs back through GitHub comments
4.  **CI/CD Pipeline**: Validates code quality and runs automated tests

### Workflow Trigger Mechanisms

The system supports two primary trigger methods:

#### A. GitHub Labels (Automatic Trigger)
- **`ai-automate`**: Triggers PR automation workflow
- **`ai-assist`**: Triggers MCP-enhanced AI automation
- **`skip-ai-review`**: Excludes PR from automatic AI review

#### B. Slash Commands (Manual Trigger)
- **`/claude <command>`**: Main AI automation commands
- **`/workspace <command>`**: Multi-project management commands

### `.github/claude/CLAUDE.md`

The following is an example of a document that `claude` can use to understand and direct the entire workflow.

---

# Claude: An AI-Powered Guide to Development Workflow

This document describes how to manage the entire development lifecycle using AI automation workflows. The system enhances development productivity by automating complex tasks such as code review, building, testing, and Pull Request (PR) creation through **GitHub labels** and **slash commands**.

## 1. Workflow Overview

This project uses multiple automated workflows that combine CI/CD pipelines with AI automation:

### Available AI Workflows

| Workflow File | Purpose | Trigger Conditions |
| :--- | :--- | :--- |
| **`claude-code-pr-automation.yaml`** | Main AI automation & PR creation | `ai-automate` label or `/claude` commands |
| **`claude-code-fix-ci.yaml`** | Auto-fix CI failures | Failed CI workflows or manual dispatch |
| **`claude-code-review.yaml`** | PR code review | PR events (excluded with `skip-ai-review` label) |
| **`claude-code-mcp-enhanced.yaml`** | MCP-enhanced AI automation | `ai-assist` label or `/claude` commands |
| **`multi-project-automation.yaml`** | Multi-project analysis | `/workspace` commands or scheduled runs |

### Standard Development Workflows

* **CI (Continuous Integration)**: Automatically builds and runs tests on code push to `main` or PR creation
* **AI Automation**: Triggered by labels or commands to perform development tasks
* **Code Quality**: Automatic styling and static analysis via pre-commit hooks

## 2. How to Trigger AI Workflows

### Method A: GitHub Labels (Automatic)

Add one of these labels to an issue or PR:

- **`ai-automate`**: Triggers the main PR automation workflow
- **`ai-assist`**: Triggers MCP-enhanced automation with advanced features
- **`skip-ai-review`**: Prevents automatic AI review on a PR

### Method B: Slash Commands (Manual)

Use these commands in issue or PR comments:

**Example:**
> `/claude add-feature 사용자 인증 기능을 추가할 것`

## 3. Available Commands

### A. `/claude` Commands (Main AI Automation)

These commands trigger the main AI automation workflows and can be used in issue or PR comments:

| Command | Purpose | Example |
| :--- | :--- | :--- |
| **`/claude add-feature <내용>`** | Add new features and create tests | `/claude add-feature 사용자 프로필 조회 API를 추가할 것` |
| **`/claude fix-issue <내용>`** | Fix bugs and add regression tests | `/claude fix-issue setup-scripts/linux/core/install-system-deps.sh의 오타를 수정할 것` |
| **`/claude refactor-code <내용>`** | Refactor code according to quality standards | `/claude refactor-code src/utils.py의 로직을 간소화하고 타입 힌트를 적용할 것` |
| **`/claude security-audit <내용>`** | Perform security audit (MCP Enhanced) | `/claude security-audit --secrets 명령을 실행하여 하드코딩된 비밀 키를 스캔할 것` |
| **`/claude code-review <내용>`** | Perform code review (MCP Enhanced) | `/claude code-review 이 PR의 로직 오류와 성능 병목 지점을 집중적으로 검토할 것` |

### B. `/workspace` Commands (Multi-Project Management)

These commands are used for multi-project environment analysis and management:

| Command | Purpose | Example |
| :--- | :--- | :--- |
| **`/workspace analyze`** | Analyze workspace structure and dependencies | `/workspace analyze. 전체 프로젝트의 종속성 그래프를 도식화하여 보고할 것.` |
| **`/workspace sync`** | Sync common settings across projects | `/workspace sync. 모든 Python 프로젝트의 ruff.toml 설정 파일을 최신 템플릿으로 동기화할 것.` |
| **`/workspace audit`** | Audit dependencies and security vulnerabilities | `/workspace audit. 모든 프로젝트의 종속성을 감사하고 취약점을 보고할 것.` |

## 4. Common Usage Scenarios

### Scenario 1: New Feature Development

1. **Using Labels (Automatic)**
   - Create an issue and add the **`ai-automate`** label
   - **System Action**: Automatically triggers feature implementation workflow

2. **Using Commands (Manual)**
   - **User**: `/claude add-feature 사용자 인증 기능을 추가할 것`
   - **System Action**:
     1. Creates feature branch
     2. Implements the requested feature
     3. Generates appropriate tests
     4. Creates PR for review

### Scenario 2: Bug Fixing

1. **Using Labels (Automatic)**
   - Create bug report and add the **`ai-assist`** label
   - **System Action**: Triggers enhanced AI automation for bug analysis and fixing

2. **Using Commands (Manual)**
   - **User**: `/claude fix-issue 로그인 시 메모리 누수 문제를 해결할 것`
   - **System Action**:
     1. Analyzes code to identify memory leak
     2. Implements fix
     3. Adds regression tests
     4. Creates PR for validation

### Scenario 3: Code Review

1. **Automatic Review**
   - Create PR without **`skip-ai-review`** label
   - **System Action**: Automatically triggers code review workflow

2. **Manual Review Request**
   - **User**: `/claude code-review 이 PR의 성능 최적화 부분을 집중 검토할 것`
   - **System Action**: Performs targeted code review and provides feedback

### Scenario 4: CI Failure Auto-Fix

- **Trigger**: Any CI workflow fails
- **System Action**:
  1. `claude-code-fix-ci.yaml` workflow automatically triggers
  2. Analyzes failure logs
  3. Implements fixes
  4. Updates/creates PR
  5. Re-runs CI to validate fixes

## 5. Workflow Selection Guide

Choose the appropriate workflow based on your needs:

### For Standard Development Tasks
- **Use**: `ai-automate` label or `/claude` commands
- **Workflow**: `claude-code-pr-automation.yaml`
- **Best for**: Feature development, bug fixes, code refactoring

### For Advanced AI Capabilities
- **Use**: `ai-assist` label
- **Workflow**: `claude-code-mcp-enhanced.yaml`
- **Best for**: Security audits, complex analysis, MCP integration

### For Multi-Project Management
- **Use**: `/workspace` commands
- **Workflow**: `multi-project-automation.yaml`
- **Best for**: Cross-project analysis, dependency management

### For CI Issues
- **Use**: Automatic (no action needed)
- **Workflow**: `claude-code-fix-ci.yaml`
- **Best for**: Auto-fixing build/test failures

## 6. Best Practices

### Using Labels Effectively
- **`ai-automate`**: Use for standard development tasks that need full automation
- **`ai-assist`**: Use when you need enhanced AI capabilities or MCP integration
- **`skip-ai-review`**: Use only for PRs that don't need AI review (e.g., documentation fixes)

### Writing Effective Commands
- **Be Specific**: Include detailed requirements in your commands
- **Use Examples**: Provide code examples or expected behavior when helpful
- **Set Context**: Mention relevant files, modules, or dependencies

### Monitoring Workflow Progress
- Check GitHub Actions tab for workflow status
- Review comments added by the AI assistant
- Verify generated code and test results
- Ensure all CI checks pass before merging

## 7. Troubleshooting

### Workflow Not Triggering
- Verify label spelling matches exactly (`ai-automate`, `ai-assist`)
- Check command syntax (`/claude <command>`)
- Ensure workflow files exist in `.github/workflows/`

### AI Assistant Not Responding
- Check GitHub Actions logs for errors
- Verify required permissions are granted
- Ensure workflow secrets are configured

### CI Auto-Fix Not Working
- Check that `claude-code-fix-ci.yaml` is enabled
- Verify workflow_run events are properly configured
- Review failure logs for diagnostic information

---