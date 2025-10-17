# AI Assistant Workflow Guide

## Project Overview

**Project**: {{cookiecutter.project_name}}
**Description**: {{cookiecutter.project_description}}
**Language**: {% if cookiecutter.python_version is defined %}Python {{cookiecutter.python_version}}{% else %}C++ {{cookiecutter.cpp_standard}}{% endif %}
**AI Integration**: Claude Code + Serena MCP

## Development Standards

- **Code Quality**: Follow Ruff (Python) or clang-format/clang-tidy (C++) rules
- **Testing**: All new features must include **Unit Tests**
- **Atomic Commit**: Code, tests, and documentation changes must always be handled in a single commit
- **AI Enhancement**: Use Serena MCP for enhanced code analysis and context understanding

---

## 🚀 AI AUTOMATED PR CREATION WORKFLOW (Core Automation Guidelines)

### Goal
Receive development requests through external commands (e.g., Issue Comments), generate and validate code, and **automatically create the final Pull Request**.

### Enhanced AI Automated PR Creation Steps (Serena-Powered)

AI strictly follows these 8-step processes when receiving requests:

| Step | Responsibility | Serena Enhancement |
| :--- | :--- | :--- |
| **1. Command Analysis** | `Issue/PR Comment` | Accurately extract requested **task type** and **detailed requirements** using Serena's context understanding |
| **2. Code & Test Generation** | `src/`, `tests/` | Implement code matching requirements and **simultaneously** write comprehensive unit tests |
| **3. Serena Validation** | `Serena MCP` | **Autonomous validation and optimization**: <br> - Run full test suite and fix failures<br> - Optimize code quality and performance<br> - Validate architectural invariants<br> - Update documentation automatically |
| **3.5** | **Serena Optimization** | **Performance and security optimization** <br> - Apply best practices automatically<br> - Optimize algorithms and data structures<br> - Enhance security measures<br> - Improve code maintainability |
| **4. Local Quality Validation** | `pre-commit` Hooks | **Final quality gates**: <br> - **Formatting**: `ruff format --check` or `clang-format --dry-run`<br> - **Linting/Analysis**: `ruff check` or `clang-tidy`<br> - **Testing**: `pytest tests/` or `ctest --test-dir build` |
| **4.5** | **Serena Documentation** | **Automatic documentation updates** <br> - Update API documentation<br> - Create changelog entries<br> - Update examples and tutorials<br> - Generate architecture diagrams |
| **5. Atomic Commit** | `git commit` | Bundle all changes including code, tests, and documentation into a **single atomic commit** with detailed Serena-generated commit message |
| **5.5** | **Serena Verification** | **Pre-push validation** <br> - Final integrity check<br> - Rollback capability if issues detected<br> - Performance regression testing<br> - Security vulnerability scan |
| **6. PR Creation & Completion** | `git push` & `gh pr create` | Push commit to new feature branch, **automatically create Pull Request** to main branch with comprehensive description, then complete task |

### Enhanced AI Command Protocol (Serena-Powered)

To trigger AI workflow, include the following commands in Issue or PR Comment:

| Command | Serena Enhancement | Function |
| :--- | :--- | :--- |
| `/claude add-feature` | **Auto-generate & validate** | Add new feature code with comprehensive tests and documentation |
| `/claude fix-issue` | **Auto-diagnose & repair** | Identify root cause and implement complete fixes with regression tests |
| `/claude refactor-code` | **Safe automated refactoring** | Improve code structure while maintaining functionality |
| `/claude intelligent-testing` | **Self-improving test suite** | Generate, execute, and optimize tests automatically |
| `/claude architecture-evolution` | **Autonomous architecture management** | Analyze and implement architectural improvements safely |
| `/claude dependency-audit` | **Auto-fix dependency issues** | Update, secure, and optimize dependencies automatically |
| `/claude workspace-analysis` | **Workspace optimization** | Analyze and improve multi-project workspace structure |
| `/claude knowledge-transfer` | **Living documentation system** | Generate and maintain comprehensive documentation |
| `/claude serena-autofix` | **Comprehensive auto-fix** | Identify and fix all types of code issues automatically |
| `/claude serena-optimize` | **Performance optimization** | Optimize code, build, and runtime performance |
| `/claude serena-insights` | **Deep analysis** | Provide comprehensive insights using all Serena capabilities |

#### Serena Autonomous Capabilities

**Self-Validating Changes:**
- All Serena commands include automatic validation
- Changes are only committed if all tests pass
- Quality gates are enforced automatically
- Rollback capability if issues are detected

**Continuous Improvement:**
- Serena learns from each interaction
- Improves accuracy over time
- Adapts to project-specific patterns
- Maintains consistency with existing codebase

---

### ⚠️ AI Development Responsibilities (CRITICAL INVARIANTS)

**ARCHITECTURE INVARIANTS (Non-negotiable Rules):**

**Module Structure:**
- **INV-MS-001:** Single entry point (main.py/main.cpp/main.js)
- **INV-MS-002:** No circular dependencies (check: `pydeps src --show-cycles`)
- **INV-MS-003:** Clear layers - upper calls lower, never reverse

**Dependencies:**
- **INV-DR-001:** Absolute imports only: `from src.module import X`
- **INV-DR-002:** No wildcards: ❌ `from module import *`
- **INV-DR-004:** Wrap external libraries in adapter modules

**Data Flow:**
- **INV-DF-001:** Unidirectional flow (Input → Validate → Process → Store → Response)
- **INV-DF-002:** Immutable data between layers
- **INV-DF-003:** No global mutable state

**Configuration:**
- **INV-CF-001:** Single source per config value
- **INV-CF-002:** No hardcoded secrets
- **INV-CF-003:** Environment-driven config (no `if ENV == "prod"` in code)

**Error Handling:**
- **INV-EH-001:** Validate at boundaries (API endpoints, file parsing)
- **INV-EH-002:** Preserve error context: `raise NewError() from e`
- **INV-EH-003:** No silent failures (log or handle, never `except: pass`)

**Testing:**
- **INV-TS-001:** All public APIs must have tests (80%+ coverage)
- **INV-TS-002:** No real external calls in unit tests (use mocks)
- **INV-TS-003:** Test file naming: `test_<module_name>.py`

**Security:**
- **INV-SC-001:** Validate all external input
- **INV-SC-003:** No PII/passwords in logs

**Performance:**
- **INV-PF-001:** No N+1 query patterns
- **INV-PF-002:** Always cleanup resources (use context managers)

**Serena Integration:**
- **INV-SR-001:** Serena must validate all changes before commit
- **INV-SR-002:** Serena must run full test suite after any code modification
- **INV-SR-003:** Serena must maintain memory system consistency with code changes
- **INV-SR-004:** Serena must document all automated changes in commit messages
- **INV-SR-005:** Serena must preserve architectural invariants during automated changes
- **INV-SR-006:** Serena must rollback changes if validation fails
- **INV-SR-007:** Serena must optimize for performance and security in all automated improvements

**MODULE INTERFACE RULES:**
- Changes to public interfaces require updating ALL "Used By" locations in same commit
- Add deprecation warnings before breaking changes
- Update tests and docs together with interface changes

**VIOLATION RESPONSE:**
If invariant violation needed: STOP → Document why → Consult team → Get approval → Add comment with ticket reference

* **NEVER** hardcode `secrets` or API keys when generating code
* **ALWAYS** follow the above architecture invariants (no circular dependencies, etc.)
* **PR creation success** is the final success metric for AI automation tasks

---

## 📁 Project Structure Reference
```
{{cookiecutter.project_name}}/
├── .github/
│   ├── workflows/                 # GitHub Actions for automation
│   │   ├── claude-code-pr-automation.yaml    # AI PR creation workflow
│   │   ├── claude-code-fix-ci.yaml           # CI failure auto-fix
│   │   └── claude-code-review.yaml           # Automated PR reviews
│   └── claude/                    # Claude AI configuration
│       ├── CLAUDE.md              # This context file
│       ├── commands/              # AI command templates
│       └── prompts/               # Language-specific templates
├── src/                           # Source code directory
├── tests/                         # Unit test directory
├── docs/                          # Documentation
└── scripts/                       # Utility scripts
```

## 🤖 Serena MCP Integration

### Overview
This project is enhanced with **Serena MCP** (Model Context Protocol) server integration for advanced AI capabilities.

### Installation Commands
```bash
# Install Serena MCP server for Claude Code
claude mcp add-json "serena" '{"command":"uvx","args":["--from","git+https://github.com/oraios/serena","serena-mcp-server"]}'

# Verify installation
claude mcp list

# Check available MCP resources
claude mcp list-resources
```

### Serena MCP Features
- **Enhanced Context Analysis**: Deep understanding of code structure and relationships
- **Workflow Automation**: Advanced automation for repetitive development tasks
- **Documentation Generation**: Intelligent documentation creation and updates
- **Code Pattern Recognition**: Identifies common patterns and suggests improvements
- **Semantic Search**: Advanced code search and understanding capabilities

### Usage Examples
```bash
# Use Serena MCP for code analysis
# AI assistants with Serena MCP can provide enhanced insights
# about code structure, dependencies, and optimization opportunities

# Commands that leverage Serena MCP:
/claude analyze-codebase     # Deep code analysis
/claude optimize-patterns    # Pattern optimization suggestions
/claude generate-docs        # Automated documentation generation
```

### Integration with AI Workflows
Serena MCP enhances all AI automation commands in this project:
- **Feature Development**: Enhanced code analysis and recommendations
- **Bug Fixes**: Improved context understanding for faster resolution
- **Code Reviews**: Deeper insights into code quality and patterns
- **Documentation**: Automated generation of comprehensive documentation

---

## 🛡️ Security Guidelines
- **NEVER** hardcode secrets or API keys in code
- **ALWAYS** use GitHub Secrets to manage sensitive data
- **ALWAYS** validate external inputs and follow principle of least privilege
- **Serena MCP Security**: Ensure MCP server access follows security best practices

---

## 🔄 CICD_template Integration Plan

### Template Integration Strategy
This `CLAUDE.md` file serves as a master template for all projects created using the CICD_template cookiecutter. When a new project is generated, this file will be automatically copied and customized with project-specific variables.

### Implementation Steps

#### 1. Cookiecutter Hook Integration
```python
# In cookiecutter/hooks/post_gen_project.py
def setup_claude_context():
    """Copy and customize CLAUDE.md for new projects"""
    template_file = Path('.github/claude/CLAUDE.md')
    if template_file.exists():
        # Replace cookiecutter variables with actual project values
        content = template_file.read_text()
        content = content.replace('{{cookiecutter.project_name}}', '{{ cookiecutter.project_name }}')
        content = content.replace('{{cookiecutter.project_description}}', '{{ cookiecutter.project_description }}')
        # ... more variable replacements
        template_file.write_text(content)
```

#### 2. Project-Specific Customization
When creating new projects, the following variables will be automatically replaced:
- `{{cookiecutter.project_name}}` → Actual project name
- `{{cookiecutter.project_description}}` → Project description
- `{{cookiecutter.python_version}}` → Python version (if applicable)
- `{{cookiecutter.cpp_standard}}` → C++ standard (if applicable)

#### 3. Workflow Integration
- GitHub Actions workflows will reference this CLAUDE.md for AI context
- All AI automation commands will follow the protocols defined here
- New projects inherit the complete AI automation workflow immediately

#### 4. Validation and Testing
```bash
# After project creation, validate the setup
claude --model haiku --help
ls -la .github/claude/
cat .github/claude/CLAUDE.md | grep "{{cookiecutter"  # Should return empty
```

### Benefits of This Approach

1. **Consistency**: All projects follow the same AI automation standards
2. **Immediate Setup**: New projects are AI-ready from creation
3. **Maintainability**: Single source of truth for AI workflow guidelines
4. **Scalability**: Easy to update AI workflows across all projects
5. **Quality Assurance**: Built-in validation and quality gates

### Usage Example

```bash
# Create new project with AI automation
cookiecutter https://github.com/your-org/CICD_template

# Project is immediately ready for AI automation
cd your-new-project
echo "/claude add-feature Add user authentication" > feature_request.txt
# AI will use the customized CLAUDE.md for context and guidelines
```

---

*This document is maintained by the Claude Code AI automation system and automatically customized for each new project.*