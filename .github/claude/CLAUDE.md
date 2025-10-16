# AI Assistant Workflow Guide

## Project Overview

**Project**: {{cookiecutter.project_name}}
**Description**: {{cookiecutter.project_description}}
**Language**: Python {{cookiecutter.python_version}} (or C++ {{cookiecutter.cpp_standard}})

## Development Standards

- **Code Quality**: Follow Ruff (Python) or clang-format/clang-tidy (C++) rules
- **Testing**: All new features must include **Unit Tests**
- **Atomic Commit**: Code, tests, and documentation changes must always be handled in a single commit

---

## 🚀 AI AUTOMATED PR CREATION WORKFLOW (Core Automation Guidelines)

### Goal
Receive development requests through external commands (e.g., Issue Comments), generate and validate code, and **automatically create the final Pull Request**.

### AI Automated PR Creation Steps (Step-by-Step Flow)

AI strictly follows these 5-step processes when receiving requests:

| Step | Responsibility | Detail |
| :--- | :--- | :--- |
| **1. Command Analysis** | `Issue/PR Comment` | Accurately extract requested **task type** (`add-feature`, `fix-issue`) and **detailed requirements** |
| **2. Code & Test Generation** | `src/`, `tests/` | Implement code matching requirements and **simultaneously** write unit tests (`pytest` or `gtest` based) |
| **3. Local Quality Validation** | `pre-commit` Hooks | **Immediately after code generation**, ensure passing the following quality gates in **local environment**: <br> - **Formatting**: `ruff format --check` or `clang-format --dry-run`<br> - **Linting/Analysis**: `ruff check` or `clang-tidy`<br> - **Testing**: `pytest tests/` or `ctest --test-dir build` |
| **4. Atomic Commit** | `git commit` | Bundle all changes including code and test files into a **single atomic commit** |
| **5. PR Creation & Completion** | `git push` & `gh pr create` | Push commit to new feature branch, **automatically create Pull Request** to main branch, then complete task |

### AI Command Protocol (Command Protocol)

To trigger AI workflow, include the following commands in Issue or PR Comment:

| Command | Function |
| :--- | :--- |
| `/claude add-feature` | Add new feature code and Unit Tests |
| `/claude fix-issue` | Fix bugs and add Regression Tests |
| `/claude refactor-code` | Improve existing code according to quality standards |

---

### ⚠️ AI Development Responsibilities (CRITICAL INVARIANTS)

* **NEVER** hardcode `secrets` or API keys when generating code
* **ALWAYS** follow architecture rules specified in `ARCHITECTURE_INVARIANTS.md` (e.g., no circular dependencies)
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

## 🛡️ Security Guidelines
- **NEVER** hardcode secrets or API keys in code
- **ALWAYS** use GitHub Secrets to manage sensitive data
- **ALWAYS** validate external inputs and follow principle of least privilege

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