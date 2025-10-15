# Claude AI Assistant Context

## 🚀 Project Overview
This is an AI-powered CI/CD template repository that demonstrates advanced automation workflows using Claude Code CLI. The project showcases automated development processes including CI failure fixes, code reviews, and issue resolution.

## 🏗️ Project Structure
```
.
├── .github/
│   ├── workflows/                 # GitHub Actions workflows
│   │   ├── claude-code-pr-automation.yaml    # Main automation workflow
│   │   ├── claude-code-fix-ci.yaml           # CI failure auto-fix
│   │   └── claude-code-review.yaml           # Automated PR reviews
│   ├── actions/                   # Reusable GitHub Actions
│   │   ├── claude-code-runner/    # Claude Code CLI integration
│   │   └── setup-environment/     # Environment setup
│   └── claude/                    # Claude AI configuration
│       ├── CLAUDE.md              # This context file
│       ├── commands/              # Custom slash commands
│       └── prompts/               # Prompt templates
├── docs/                          # Documentation
├── templates/                     # Project templates (Python, C++, etc.)
└── scripts/                       # Utility scripts
```

## 🎯 Automation Capabilities

### 1. Issue-Driven Development
- **Trigger**: Label issues with `ai-automate`
- **Capability**: Analyze requirements, implement features, create PRs
- **Example**: Add `ai-automate` label to a feature request

### 2. CI Failure Auto-Fix
- **Trigger**: Failed CI/CD workflows
- **Capability**: Analyze failures, implement fixes, re-run validation
- **Example**: Test failures automatically trigger debugging and fixes

### 3. Automated Code Reviews
- **Trigger**: Pull request creation/updates
- **Capability**: Comprehensive code analysis, security checks, best practices
- **Example**: PRs automatically get detailed AI reviews

## 🔧 Development Guidelines

### Code Quality Standards
- **Python**: Use `ruff` for linting, `pytest` for testing, `mypy` for type checking
- **C++**: Use `clang-format`, `cmake` for builds, `ctest` for testing
- **Node.js**: Use `eslint`, `prettier`, `npm test`
- **General**: Follow language-specific best practices and conventions

### Testing Requirements
- All new functionality must include comprehensive tests
- Test coverage should be maintained or improved
- Integration tests for workflow automation
- Mock external dependencies appropriately

### Documentation Standards
- Update README.md for user-facing changes
- Document new automation capabilities
- Include examples in documentation
- Maintain API documentation for any new endpoints

## 🛡️ Security and Best Practices

### Security Guidelines
- Never commit secrets or API keys
- Use GitHub Secrets for sensitive data
- Validate all external inputs
- Follow principle of least privilege

### Git Workflow
- Create atomic, complete commits
- Use conventional commit message format
- Ensure all commits pass quality gates
- Include documentation in the same commit as code changes

### Claude Code Integration
- Use headless mode (`-p` flag) for automation
- Leverage `--output-format stream-json` for structured output
- Include project context via CLAUDE.md
- Handle timeouts and errors gracefully

## 🎨 Custom Slash Commands

### `/fix-issue`
Analyzes and resolves GitHub issues automatically.
```markdown
Usage: /fix-issue <issue_number>
Description: Implement the requested changes from a GitHub issue
```

### `/refactor-code`
Refactors existing code following best practices.
```markdown
Usage: /refactor-code <file_path> <description>
Description: Refactor code to improve quality, performance, or maintainability
```

## 📋 Prompt Templates

### Issue Resolution Template
Location: `.github/claude/prompts/templates/issue_resolution.md`
- Analyzes issue requirements
- Implements solution with tests
- Creates comprehensive PR

### Bug Fix Template
Location: `.github/claude/prompts/templates/bug_fix.md`
- Debugs failing tests or CI
- Identifies root cause
- Implements targeted fixes

### Code Review Template
Location: `.github/claude/prompts/templates/code_review.md`
- Comprehensive code analysis
- Security vulnerability scanning
- Best practices evaluation

## 🔄 Workflow Integration

### Environment Setup
The `.github/actions/setup-environment` action automatically:
- Installs Claude Code CLI
- Sets up language-specific tools
- Configures Git environment
- Creates necessary directories

### Error Handling
- Timeouts: Configurable per workflow (default 5-10 minutes)
- Retries: Automatic retry logic for transient failures
- Fallbacks: Manual intervention notifications when automation fails
- Logging: Comprehensive logging for debugging

### Quality Gates
- Pre-commit hooks for code formatting
- Automated testing in CI/CD
- Code coverage requirements
- Security scanning integration

## 📊 Metrics and Monitoring

### Automation Metrics
- CI failure resolution time
- Code review turnaround time
- Issue resolution rate
- PR merge time reduction

### Success Indicators
- Reduced manual intervention
- Improved code quality
- Faster development cycles
- Consistent documentation

## 🚨 Important Notes

### For Claude AI Assistant
1. **Always** read and understand the existing codebase before making changes
2. **Never** break backward compatibility without explicit justification
3. **Always** include tests for new functionality
4. **Never** commit secrets or sensitive information
5. **Always** follow the project's established patterns and conventions
6. **Never** make assumptions about external dependencies without verification

### For Human Developers
1. Review AI-generated changes before merging
2. Monitor automation workflows for unusual behavior
3. Maintain security best practices
4. Provide feedback to improve automation quality
5. Override automation when human judgment is required

## 🎯 Current Context
- **Repository Type**: CI/CD Template with AI Automation
- **Primary Languages**: Python, C++, Node.js (multi-language support)
- **Automation Level**: Advanced (issue-driven, CI auto-fix, code reviews)
- **Target Users**: Development teams seeking workflow automation
- **Quality Focus**: High (comprehensive testing, documentation, security)

---

## 🤖 Last Updated
This context file is automatically maintained by the AI automation workflows. Last update: 2024

*Generated by Claude Code AI Automation System*