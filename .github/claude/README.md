# Claude Code AI Automation

This directory contains the configuration and templates for Claude Code AI automation in this repository.

## 📁 Directory Structure

```
.github/claude/
├── CLAUDE.md              # Main context file for Claude AI
├── README.md              # This file
├── commands/              # Custom slash commands
│   ├── fix-issue.md       # Automatic issue resolution
│   └── refactor-code.md   # Code refactoring assistance
└── prompts/               # Prompt templates
    ├── templates/         # Language-specific templates
    │   ├── python_fix.md  # Python issue resolution
    │   └── cpp_fix.md     # C++ issue resolution
    ├── issue_resolution.md # General issue handling
    ├── bug_fix.md        # Bug fixing methodology
    └── code_review.md    # Code review guidelines
```

## 🚀 Features

### Automated Workflows
- **Issue Resolution**: Automatically implement GitHub issues
- **CI Failure Fix**: Debug and fix failing CI/CD pipelines
- **Code Review**: Comprehensive PR analysis and feedback
- **Code Refactoring**: Improve code quality and maintainability

### Custom Commands
- `/fix-issue`: Resolve GitHub issues automatically
- `/refactor-code`: Refactor code following best practices

### Language Support
- **Python**: PEP 8, type hints, pytest, modern practices
- **C++**: Modern C++, RAII, smart pointers, CMake
- **JavaScript/Node.js**: ESLint, modern JavaScript, npm workflows
- **General**: Cross-platform compatibility, security best practices

## 🛠️ Setup Instructions

### 1. Claude Code CLI
Install the Claude Code CLI:
```bash
npm install -g @anthropic-ai/claude-code
```

### 2. GitHub Secrets
Add the following secrets to your repository:
```
ANTHROPIC_API_KEY=your_anthropic_api_key_here
```

### 3. Enable Workflows
The following workflows are available:
- `claude-code-pr-automation.yaml`: Main automation workflow
- `claude-code-fix-ci.yaml`: CI failure auto-fix
- `claude-code-review.yaml`: Automated PR reviews

### 4. Configure Triggers
- **Issue Automation**: Label issues with `ai-automate`
- **PR Reviews**: Automatically triggered on PR creation/updates
- **CI Fixes**: Automatically triggered on workflow failures

## 📋 Usage Examples

### Automatic Issue Resolution
1. Create a GitHub issue with clear requirements
2. Add the `ai-automate` label
3. Claude AI will:
   - Analyze the issue requirements
   - Implement the solution
   - Create comprehensive tests
   - Generate a pull request

### CI Failure Auto-Fix
1. When a CI/CD workflow fails
2. The automation will:
   - Analyze failure logs
   - Identify root causes
   - Implement targeted fixes
   - Re-run the validation pipeline

### Automated Code Reviews
1. Create or update a pull request
2. Claude AI will:
   - Review code quality and best practices
   - Check for security vulnerabilities
   - Suggest improvements
   - Provide detailed feedback

## 🔧 Configuration

### Customizing CLAUDE.md
Edit `.github/claude/CLAUDE.md` to:
- Update project-specific context
- Modify automation guidelines
- Add custom requirements
- Configure language-specific rules

### Adding Custom Commands
1. Create new markdown files in `.github/claude/commands/`
2. Follow the existing format
3. Include usage examples and guidelines

### Creating Prompt Templates
1. Add templates to `.github/claude/prompts/templates/`
2. Follow the structured format
3. Include specific guidelines and checklists

## 🎯 Best Practices

### For Developers
1. **Review AI Changes**: Always review AI-generated code before merging
2. **Monitor Workflows**: Keep an eye on automation workflows
3. **Provide Feedback**: Help improve the automation quality
4. **Security**: Never commit sensitive information

### For AI Automation
1. **Context Awareness**: Always read project context before making changes
2. **Testing**: Ensure all changes include comprehensive tests
3. **Documentation**: Update documentation with code changes
4. **Backward Compatibility**: Maintain compatibility unless explicitly breaking

## 📊 Monitoring and Metrics

### Automation Success Metrics
- Issue resolution time
- CI failure fix rate
- Code review coverage
- Developer productivity improvement

### Quality Metrics
- Code quality scores
- Test coverage rates
- Security vulnerability detection
- Performance impact assessment

## 🚨 Troubleshooting

### Common Issues
1. **Claude Code CLI Not Found**: Ensure CLI is installed and in PATH
2. **API Key Errors**: Verify ANTHROPIC_API_KEY secret is correctly set
3. **Timeout Issues**: Adjust timeout values in workflow files
4. **Permission Errors**: Check GitHub Actions permissions

### Debug Mode
Enable debug logging by setting:
```yaml
env:
  CLAUDE_CODE_DEBUG: true
```

### Manual Override
If automation fails, manual intervention is always available:
1. Review workflow logs
2. Manually implement the changes
3. Document the issue for improvement

## 🔄 Continuous Improvement

### Feedback Loop
- Monitor automation success rates
- Collect developer feedback
- Update prompts and templates
- Refine automation strategies

### Updates and Maintenance
- Regularly update prompt templates
- Incorporate new best practices
- Add language-specific improvements
- Maintain security guidelines

---

## 📚 Additional Resources

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AI Integration Best Practices](https://docs.github.com/en/actions/security-guides/automatic-token-authentication)

*This AI automation system is continuously evolving. Please provide feedback to help improve its capabilities.*