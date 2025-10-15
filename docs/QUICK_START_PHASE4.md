# Quick Start Guide: Phase 4 Advanced Features

## 🚀 Getting Started with Phase 4

This guide helps you quickly set up and use the advanced Phase 4 features of the AI automation system.

## 📋 Prerequisites

### Required Setup
- ✅ Claude Code CLI installed
- ✅ Node.js 18+ (for MCP servers)
- ✅ Python 3.11+ (for enhanced scripts)
- ✅ GitHub CLI (gh) installed and authenticated
- ✅ Repository with Phase 1-3 features implemented

### Environment Variables
```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"
export GITHUB_TOKEN="your-github-token"
```

---

## 🔧 Step 1: Install MCP Servers

Install the required MCP servers for extended functionality:

```bash
# Install MCP servers
npm install -g @modelcontextprotocol/server-git
npm install -g @modelcontextprotocol/server-github
npm install -g @modelcontextprotocol/server-filesystem

# Verify installation
npx @modelcontextprotocol/server-git --help
```

---

## 🏗️ Step 2: Configure Workspace

Create workspace configuration for multi-project support:

```bash
# Create workspace directory
mkdir -p .github/workspace

# Generate initial workspace config
cat > .github/workspace/workspace_config.json << 'EOF'
{
  "name": "my-workspace",
  "description": "Multi-project workspace with AI automation",
  "default_branch": "main",
  "shared_tools": ["pytest", "eslint", "prettier"],
  "global_configs": {
    "python_version": "3.11",
    "node_version": "18"
  }
}
EOF
```

---

## 🛡️ Step 3: Setup Security

Initialize security policies and patterns:

```bash
# Create security directory
mkdir -p .github/security

# Generate default security configuration
python .github/actions/claude-code-runner/scripts/security_manager.py list-policies > .github/security/policies.json

# Create default secrets patterns
cat > .github/security/secrets_patterns.json << 'EOF'
{
  "patterns": [
    "api[_-]?key['\"\\s]*[:=]['\"\\s]*[a-zA-Z0-9_\\-]{16,}",
    "secret[_-]?key['\"\\s]*[:=]['\"\\s]*[a-zA-Z0-9_\\-]{16,}",
    "AKIA[0-9A-Z]{16}",
    "ghp_[a-zA-Z0-9]{36}",
    "eyJ[a-zA-Z0-9_-]*\\.eyJ[a-zA-Z0-9_-]*\\.[a-zA-Z0-9_-]*"
  ],
  "updated_at": "2024-10-15T00:00:00Z"
}
EOF
```

---

## 🎯 Step 4: Test Basic Features

### Test MCP Integration
```bash
# Test MCP server status
python .github/actions/claude-code-runner/scripts/mcp_server_manager.py status

# Test enhanced Claude runner
python .github/actions/claude-code-runner/scripts/enhanced_claude_runner.py --list-projects
```

### Test Multi-Project Discovery
```bash
# Discover projects in workspace
python .github/actions/claude-code-runner/scripts/multi_project_manager.py report

# Analyze dependencies
python .github/actions/claude-code-runner/scripts/multi_project_manager.py dependencies
```

### Test Security Features
```bash
# Test permission checking
python .github/actions/claude-code-runner/scripts/security_manager.py \
  check-permission --user $GITHUB_ACTOR --permission read

# Test secret scanning
python .github/actions/claude-code-runner/scripts/security_manager.py \
  scan-secrets --file "README.md"
```

---

## 🚀 Step 5: Use Advanced Slash Commands

### Workspace Analysis
```bash
# Trigger workspace analysis via GitHub issue comment
echo "I need a comprehensive workspace analysis" | gh issue create \
  --title "Workspace Analysis Request" \
  --label "ai-assist" \
  --body "/workspace-analysis"
```

### Cross-Project Operations
```bash
# Request cross-project synchronization
echo "Please sync dependencies across all projects" | gh issue create \
  --title "Cross-Project Sync" \
  --label "ai-assist" \
  --body "/cross-project-sync --config-types=dependencies,ci-cd"
```

### Security Audit
```bash
# Request security audit
echo "Please perform a security audit of the repository" | gh issue create \
  --title "Security Audit Request" \
  --label "ai-assist,security" \
  --body "/dependency-audit --severity=high"
```

---

## 🔄 Step 6: Enable Workflows

Enable the new Phase 4 workflows:

### MCP-Enhanced Automation
The workflow triggers automatically when:
- Issues are labeled with `ai-assist`
- Comments contain `/claude` commands
- CI/CD workflows fail
- Pull requests are created/updated

### Multi-Project Automation
```bash
# Trigger manually via GitHub CLI
gh workflow run multi-project-automation \
  --field operation=workspace-analysis \
  --field create_issues=true

# Or via issue comment
echo "Please analyze the workspace" | gh issue comment 1 \
  --body "/workspace analyze"
```

### Security Enforcement
```bash
# Run security scan manually
gh workflow run security-enforcement \
  --field operation=scan-secrets \
  --field security_level=internal

# Daily security scans run automatically at 3 AM UTC
```

---

## 📊 Step 7: Monitor Results

### Check Security Dashboard
Security results are posted in:
- GitHub Actions step summaries
- Security issues (if violations found)
- Audit logs in `.github/security/audit.log`

### View Workspace Reports
Multi-project analysis results are available in:
- Workflow run artifacts
- GitHub Actions summaries
- `.github/workspace/` configuration files

### MCP Server Status
Monitor MCP server health:
```bash
python .github/actions/claude-code-runner/scripts/mcp_server_manager.py status
```

---

## 🎯 Common Usage Patterns

### 1. New Project Onboarding
```bash
# 1. Add new project to workspace
cd /path/to/new-project

# 2. Trigger workspace analysis
echo "Adding new project to workspace" | gh issue create \
  --title "New Project: project-name" \
  --label "ai-assist" \
  --body "/workspace-analysis"

# 3. Sync configurations
gh issue comment [issue-number] \
  --body "/cross-project-sync --projects=project-name"
```

### 2. Security Incident Response
```bash
# 1. Run immediate security scan
gh workflow run security-enforcement \
  --field operation=scan-secrets \
  --field security_level=restricted

# 2. Generate security report
gh workflow run security-enforcement \
  --field operation=security-report \
  --field security_level=restricted

# 3. Review violations
cat .github/security/violations.json
```

### 3. Dependency Management
```bash
# 1. Audit dependencies across all projects
echo "Audit all dependencies for updates and vulnerabilities" | gh issue create \
  --title "Dependency Audit" \
  --label "ai-assist,maintenance" \
  --body "/dependency-audit --fix --severity=medium"

# 2. Sync updates
gh issue comment [issue-number] \
  --body "/cross-project-sync --config-types=dependencies"
```

### 4. Architecture Reviews
```bash
# Request architecture evolution analysis
echo "Please review our architecture and suggest improvements" | gh issue create \
  --title "Architecture Review" \
  --label "ai-assist,architecture" \
  --body "/architecture-evolution full-system --create-roadmap"
```

### 5. Test Generation
```bash
# Generate intelligent tests
echo "Generate comprehensive tests for critical components" | gh issue create \
  --title "Test Generation" \
  --label "ai-assist,testing" \
  --body "/intelligent-testing --coverage-target=90 --priority=high"
```

---

## 🔧 Troubleshooting Quick Fixes

### MCP Server Issues
```bash
# Restart MCP servers
python .github/actions/claude-code-runner/scripts/mcp_server_manager.py stop
python .github/actions/claude-code-runner/scripts/mcp_server_manager.py start

# Check configuration
cat .github/claude/mcp_config.json
```

### Permission Issues
```bash
# Check your permissions
python .github/actions/claude-code-runner/scripts/security_manager.py \
  check-permission --user $GITHUB_ACTOR --permission write

# List available policies
python .github/actions/claude-code-runner/scripts/security_manager.py list-policies
```

### Project Discovery Issues
```bash
# Force project rediscovery
rm -f .github/workspace/projects.json
python .github/actions/claude-code-runner/scripts/multi_project_manager.py report
```

### Security Scan Issues
```bash
# Update security patterns
python .github/actions/claude-code-runner/scripts/security_manager.py \
  security-summary --days 1
```

---

## 📈 Performance Tips

### Optimize MCP Usage
1. **Server Configuration**: Set appropriate timeouts (30-60 seconds)
2. **Tool Selection**: Use specific tools rather than broad operations
3. **Caching**: Enable result caching for repeated operations

### Multi-Project Optimization
1. **Incremental Analysis**: Only analyze changed projects
2. **Parallel Processing**: Use concurrent operations where possible
3. **Dependency Caching**: Cache dependency analysis results

### Security Efficiency
1. **Pattern Optimization**: Use specific, efficient regex patterns
2. **Incremental Scanning**: Only scan changed files
3. **Policy Caching**: Cache permission checks

---

## 🎯 Next Steps

1. **Customize Policies**: Adjust security policies for your organization
2. **Add MCP Servers**: Install additional MCP servers for specific needs
3. **Create Custom Commands**: Develop domain-specific slash commands
4. **Set Up Monitoring**: Configure alerts for security violations
5. **Team Training**: Train team members on new features

---

## 📚 Additional Resources

- [Full Phase 4 Implementation Guide](./PHASE4_IMPLEMENTATION_GUIDE.md)
- [Security Best Practices](./SECURITY_GUIDELINES.md)
- [Multi-Project Management](./MULTI_PROJECT_GUIDE.md)
- [MCP Integration](./MCP_INTEGRATION.md)

---

## 🆘 Getting Help

If you encounter issues:

1. **Check Workflow Logs**: Review GitHub Actions run logs
2. **Review Configuration**: Verify all configuration files
3. **Check Permissions**: Ensure proper GitHub permissions
4. **Review Security Logs**: Check `.github/security/audit.log`
5. **Create Issue**: Create a GitHub issue with the `ai-assist` label

---

*Ready to supercharge your development workflow with Phase 4 advanced features!* 🚀