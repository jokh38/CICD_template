# AI Documentation Structure

This directory contains all AI-specific documentation and guidelines that are directly referenced by Claude AI during automated development tasks.

## Document Structure

### Core AI Guidelines
- **CLAUDE.md** (../CLAUDE.md): Main AI context file with integrated critical invariants
- **base_prompt.md** (../prompts/base_prompt.md): Centralized core workflow instructions

### Language-Specific Guidelines
- **_python_guidelines.md** (../prompts/_python_guidelines.md): Python-specific best practices
- **_cpp_guidelines.md** (../prompts/_cpp_guidelines.md): C++-specific best practices
- **_javascript_guidelines.md** (../prompts/_javascript_guidelines.md): JavaScript/TypeScript best practices

### Architecture Rules
- **ARCHITECTURE_INVARIANTS.md**: Non-negotiable architecture rules and invariants
- **MODULE_INTERFACES.md**: Public interface documentation and change policies

### Process Documentation
- **AI_DEVELOPMENT_GUIDE.md**: Comprehensive AI development workflow
- **AI_ASSISTED_DEVELOPMENT_README.md**: Overview of AI-assisted development

### Prompt Templates
- **prompts/** directory: Contains all task-specific and language-specific prompt templates
  - **bug_fix.md**: Bug fixing and CI failure resolution
  - **code_review.md**: Code review process and criteria
  - **python_fix.md**, **cpp_fix.md**, **javascript_fix.md**: Language-specific fixing prompts
  - **_language_template.md**: Template for creating new language-specific prompts

## Usage Guidelines

### For AI Systems
- All AI automation should reference the **base_prompt.md** for core workflow instructions
- Language-specific prompts should include the relevant **_language_guidelines.md**
- Architecture invariants from **ARCHITECTURE_INVARIANTS.md** are integrated into CLAUDE.md

### For Developers
- When modifying AI workflows, update **base_prompt.md** first
- When adding new language support, create **_newlanguage_guidelines.md** and a corresponding prompt template
- Architecture rule changes should be made in both **ARCHITECTURE_INVARIANTS.md** and **CLAUDE.md**

### File Organization Principle
- **AI-readable files**: All files in `.github/claude/` are designed to be directly consumed by AI
- **Human-readable files**: Documentation in `docs/` is for human understanding
- **Integration**: Critical rules from docs/AI/ are integrated into CLAUDE.md for AI access

## Maintenance

### Adding New Languages
1. Create `_newlanguage_guidelines.md` in `prompts/` directory
2. Create `newlanguage_fix.md` prompt template referencing the guidelines
3. Update base_prompt.md if language-specific workflow steps are needed

### Updating Core Workflows
1. Modify `base_prompt.md` for workflow changes
2. Update individual prompt templates if needed
3. Test changes with AI automation tasks

### Architecture Changes
1. Update `ARCHITECTURE_INVARIANTS.md`
2. Mirror critical changes in `CLAUDE.md`
3. Update any affected prompt templates

This consolidated structure ensures AI has immediate access to all necessary guidelines while maintaining clear separation of concerns between AI-usable and human-readable documentation.