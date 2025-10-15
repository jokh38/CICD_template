
## Phase 1: Foundation Setup (Week 1, Days 1-3)

### Objective
Establish core infrastructure for Claude Code CLI integration and prepare directory structure.

### 1.1 Directory Structure Enhancement

**Task**: Extend existing `.github/` structure to support AI workflows

```
.github/
├── workflows/                          # Existing workflows
│   ├── python-ci-reusable.yaml        # [EXISTING]
│   ├── cpp-ci-reusable.yaml           # [EXISTING]
│   ├── cpp-linux-runner.yaml          # [EXISTING]
│   ├── claude-code-pr-automation.yaml # [NEW] Main AI automation
│   ├── claude-code-fix-ci.yaml        # [NEW] CI failure auto-fix
│   └── claude-code-review.yaml        # [NEW] Automated PR review
│
├── actions/                            # Existing composite actions
│   ├── setup-python-cache/            # [EXISTING]
│   ├── setup-cpp-cache/               # [EXISTING]
│   ├── monitor-ci/                    # [EXISTING]
│   └── claude-code-runner/            # [NEW] Core Claude Code integration
│       ├── action.yaml
│       └── scripts/
│           ├── run_claude_code.py     # Main runner script
│           ├── parse_results.py       # JSON stream parser
│           └── context_manager.py     # CLAUDE.md context handler
│
└── claude/                             # [NEW] Claude-specific configs
    ├── CLAUDE.md.template             # Project context template
    ├── commands/                       # Custom slash commands
    │   ├── fix-issue.md
    │   ├── refactor-code.md
    │   └── review-pr.md
    └── prompts/
        ├── subagent_systemprompt.txt
        └── templates/
            ├── python_fix.md
            ├── cpp_fix.md
            ├── issue_resolution.md
            └── pr_review.md
```

**Implementation Steps**:
1. Create new directory structure under `.github/`
2. Update `cookiecutters/` templates to include `.github/claude/` in generated projects
3. Create template CLAUDE.md files for both Python and C++ projects

**Deliverables**:
- [ ] Directory structure created
- [ ] Template files in place
- [ ] Updated cookiecutter configuration

### 1.2 Core Python Runner Script

**Task**: Develop `run_claude_code.py` - the foundation of AI integration

**File**: `.github/actions/claude-code-runner/scripts/run_claude_code.py`

**Key Features**:
```python
class ClaudeCodeRunner:
    """
    Core runner for Claude Code CLI with advanced features:
    - Headless mode execution with JSON streaming
    - Context management via CLAUDE.md
    - Error handling and retry logic
    - Token usage monitoring
    """

    def __init__(self, project_root: Path, context_file: Path):
        self.project_root = project_root
        self.context_file = context_file
        self.max_retries = 3
        self.max_tokens = 200000

    async def run_claude_command(
        self,
        prompt: str,
        task_type: str,
        options: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Execute Claude Code with stdin prompt delivery"""

    def _build_prompt_with_context(self, prompt: str) -> str:
        """Merge prompt with CLAUDE.md context"""

    def _parse_json_stream(self, output: str) -> List[Dict]:
        """Parse stream-json output from Claude Code"""

    def _handle_validation_failure(
        self,
        error_log: str,
        retry_count: int
    ) -> str:
        """Generate correction prompt from validation errors"""
```

**Implementation Steps**:
1. Create base `ClaudeCodeRunner` class with async subprocess handling
2. Implement stdin-based prompt delivery for long prompts
3. Add JSON stream parsing with error recovery
4. Implement context file management
5. Add retry logic with exponential backoff
6. Create comprehensive logging

**Deliverables**:
- [ ] `run_claude_code.py` with full feature set
- [ ] Unit tests for core functions
- [ ] Documentation with usage examples

### 1.3 Context Management System

**Task**: Create CLAUDE.md template and context manager

**File**: `.github/claude/CLAUDE.md.template`

**Template Structure**:
```markdown
# AI Assistant Workflow Guide - {{PROJECT_NAME}}

## Project Context
**Language**: {{LANGUAGE}}
**Build System**: {{BUILD_SYSTEM}}
**CI/CD**: GitHub Actions with {{RUNNER_TYPE}}

## Code Quality Standards
- **Python**: ruff (linting/formatting), mypy (type checking), pytest (testing)
- **C++**: clang-format, clang-tidy, sccache, CMake/Ninja

## Workflow Instructions
When working on this project:

1. **Always use headless mode** for automation
2. **Validate before committing**: Run pre-commit hooks locally
3. **Follow TDD**: Write tests first, implement, refactor
4. **Use project structure**: Respect module boundaries

## Pre-commit Hook Awareness
This project uses pre-commit hooks that will:
- Run linters and formatters
- Execute type checking
- Validate commit messages

Ensure your code passes these checks before creating commits.

## CI/CD Pipeline
- **Python**: ruff check, pytest with coverage, mypy
- **C++**: CMake build, ctest, clang-tidy, coverage reports

## Common Tasks
- Fix CI failures: `/fix-ci`
- Refactor code: `/refactor`
- Review PR: `/review-pr`
```

**Implementation Steps**:
1. Create template with variable substitution
2. Develop `context_manager.py` for runtime updates
3. Implement context injection into prompts
4. Add context versioning for tracking changes

**Deliverables**:
- [ ] CLAUDE.md.template for Python projects
- [ ] CLAUDE.md.template for C++ projects
- [ ] `context_manager.py` with update logic
- [ ] Integration tests

### 1.4 Composite Action Definition

**Task**: Create reusable GitHub Action for Claude Code execution

**File**: `.github/actions/claude-code-runner/action.yaml`

```yaml
name: 'Claude Code Runner'
description: 'Execute Claude Code CLI with context and validation'
author: 'CICD Templates Team'

inputs:
  task-type:
    description: 'Type of task (fix-ci, refactor, review-pr, fix-issue)'
    required: true
  prompt:
    description: 'Task prompt (can be multiline)'
    required: false
  error-log:
    description: 'Error log from previous step (for fix-ci)'
    required: false
  retry-count:
    description: 'Current retry attempt number'
    required: false
    default: '0'
  anthropic-api-key:
    description: 'Anthropic API key for Claude Code'
    required: true
  add-directories:
    description: 'Additional directories to add to context (JSON array)'
    required: false
    default: '[]'
  max-tokens:
    description: 'Maximum tokens for Claude Code session'
    required: false
    default: '200000'

outputs:
  result:
    description: 'Claude Code execution result (JSON)'
  success:
    description: 'Whether execution succeeded (true/false)'
  modified-files:
    description: 'List of files modified (JSON array)'
  commit-message:
    description: 'Suggested commit message'

runs:
  using: 'composite'
  steps:
    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install Claude Code CLI
      shell: bash
      run: |
        pip install claude-code

    - name: Run Claude Code
      shell: bash
      env:
        ANTHROPIC_API_KEY: ${{ inputs.anthropic-api-key }}
      run: |
        python3 ${{ github.action_path }}/scripts/run_claude_code.py \
          --task-type "${{ inputs.task-type }}" \
          --prompt "${{ inputs.prompt }}" \
          --error-log "${{ inputs.error-log }}" \
          --retry-count "${{ inputs.retry-count }}" \
          --add-dirs '${{ inputs.add-directories }}' \
          --max-tokens "${{ inputs.max-tokens }}"
```

**Implementation Steps**:
1. Define all inputs with clear descriptions
2. Create composite action structure
3. Implement output handling
4. Add error handling and logging

**Deliverables**:
- [ ] `action.yaml` with full input/output definition
- [ ] Integration with `run_claude_code.py`
- [ ] Example usage documentation
