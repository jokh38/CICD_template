

## Phase 2: Cookiecutter Template Updates (Week 1, Days 4-5)

### Objective
Update Cookiecutter templates to automatically include Claude Code infrastructure in generated projects.

### 2.1 Python Template Enhancement

**Task**: Extend `cookiecutters/python-project/` with AI workflow support

**File**: `cookiecutters/python-project/cookiecutter.json`

**Changes**:
```json
{
  "project_name": "My Python Project",
  "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '_').replace('-', '_') }}",
  "python_version": ["3.11", "3.10", "3.12"],
  "runner_type": ["github-hosted", "self-hosted"],
  "use_ai_workflow": ["yes", "no"],  // [EXISTING]
  "enable_ai_fix_ci": ["yes", "no"],  // [NEW]
  "enable_ai_pr_review": ["yes", "no"],  // [NEW]
  "anthropic_api_key_secret": "ANTHROPIC_API_KEY",  // [NEW]
  "license": ["MIT", "BSD-3-Clause", "Apache-2.0", "GPL-3.0", "None"]
}
```

**New Template Files**:
```
cookiecutters/python-project/{{cookiecutter.project_slug}}/
├── .github/
│   ├── claude/
│   │   ├── CLAUDE.md                  # [NEW] Auto-generated from template
│   │   ├── commands/
│   │   │   ├── fix-ci.md             # [NEW]
│   │   │   └── review-pr.md          # [NEW]
│   │   └── prompts/
│   │       └── templates/
│   │           └── python_fix.md     # [NEW]
│   └── workflows/
│       ├── ai-workflow.yaml           # [UPDATE] Enhanced version
│       ├── ai-fix-ci.yaml            # [NEW] CI auto-fix
│       └── ai-pr-review.yaml         # [NEW] Auto PR review
```

**Implementation Steps**:
1. Update `cookiecutter.json` with new AI-related options
2. Create Jinja2 templates for CLAUDE.md with Python-specific context
3. Add conditional inclusion based on `use_ai_workflow` flag
4. Update `hooks/post_gen_project.py` to configure AI workflows
5. Update template documentation

**Deliverables**:
- [ ] Updated cookiecutter configuration
- [ ] New template files for AI workflows
- [ ] Updated post-generation hook
- [ ] Template testing with different configurations

### 2.2 C++ Template Enhancement

**Task**: Extend `cookiecutters/cpp-project/` with AI workflow support

**Similar to Python template but with C++-specific customizations**

**Key Differences**:
- CLAUDE.md includes CMake, sccache, clang-tidy context
- Prompts reference C++ standards, build systems
- CI fix workflows handle CMake build failures

**Implementation Steps**:
1. Mirror Python template changes
2. Customize CLAUDE.md for C++ ecosystem
3. Create C++-specific prompt templates
4. Update post-generation hooks

**Deliverables**:
- [ ] C++ template with AI workflow support
- [ ] C++-specific CLAUDE.md template
- [ ] CMake-aware CI fix workflows

### 2.3 Post-Generation Hook Updates

**Task**: Enhance `hooks/post_gen_project.py` to set up AI infrastructure

**File**: `cookiecutters/python-project/hooks/post_gen_project.py`

**Additions**:
```python
def setup_ai_workflows():
    """Configure AI workflows if enabled"""
    if '{{ cookiecutter.use_ai_workflow }}' == 'yes':
        # Create .github/claude directory
        claude_dir = Path('.github/claude')
        claude_dir.mkdir(parents=True, exist_ok=True)

        # Generate CLAUDE.md from template
        generate_claude_md()

        # Configure workflow files
        configure_ai_workflows()

        # Add README section about AI features
        add_ai_documentation()

def generate_claude_md():
    """Generate project-specific CLAUDE.md"""
    template_vars = {
        'project_name': '{{ cookiecutter.project_name }}',
        'python_version': '{{ cookiecutter.python_version }}',
        'runner_type': '{{ cookiecutter.runner_type }}',
    }
    # Template rendering logic

def configure_ai_workflows():
    """Enable/disable AI workflows based on config"""
    if '{{ cookiecutter.enable_ai_fix_ci }}' != 'yes':
        # Remove ai-fix-ci.yaml
        workflow_file = Path('.github/workflows/ai-fix-ci.yaml')
        if workflow_file.exists():
            workflow_file.unlink()
```

**Implementation Steps**:
1. Add AI setup function to post-generation hook
2. Implement CLAUDE.md generation with template variables
3. Add conditional workflow file management
4. Update project README with AI feature documentation

**Deliverables**:
- [ ] Enhanced post-generation hooks for both templates
- [ ] Automated CLAUDE.md generation
- [ ] Conditional AI workflow inclusion
