# PHASE_1_2_FOUNDATION.md - Foundation and Infrastructure

## Phase 1: Core Infrastructure Development (Week 1, Days 1-3)

### Objective
Build the foundational components for Claude Code CLI integration.

### 1.1 Project Structure

Create the directory structure for AI automation components:

```
.github/
├── actions/
│   └── claude-code-runner/
│       ├── action.yaml
│       └── scripts/
│           ├── run_claude_code.py
│           ├── context_manager.py
│           ├── parse_results.py
│           ├── retry_handler.py
│           └── validation.py
├── claude/
│   ├── prompts/
│   │   ├── templates/
│   │   │   ├── python_fix.md
│   │   │   ├── cpp_fix.md
│   │   │   └── general_task.md
│   │   └── subagent_systemprompt.txt
│   ├── commands/
│   │   ├── review-pr.md
│   │   ├── fix-ci.md
│   │   └── implement-feature.md
│   └── mcp-config.json
└── workflows/
    ├── ai-workflow.yaml
    ├── ai-fix-ci.yaml
    └── ai-pr-review.yaml
```

### 1.2 Core Python Components

#### 1.2.1 Claude Code Runner

**File**: `.github/actions/claude-code-runner/scripts/run_claude_code.py`

```python
"""
Main orchestrator for Claude Code CLI integration.

Handles communication with Claude Code CLI, manages context,
and processes responses for GitHub Actions workflows.
"""

import json
import subprocess
import sys
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
import os
import tempfile


@dataclass
class ClaudeRequest:
    """Request to Claude Code CLI"""
    prompt: str
    context_files: List[str]
    task_type: str
    output_format: str = "stream-json"
    headless: bool = True


@dataclass
class ClaudeResponse:
    """Response from Claude Code CLI"""
    success: bool
    output: str
    error: Optional[str]
    files_modified: List[str]
    tokens_used: int = 0


class ClaudeCodeRunner:
    """Main interface to Claude Code CLI"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.claude_path = self._find_claude_cli()

    def _find_claude_cli(self) -> str:
        """Find Claude Code CLI executable"""
        # Try common paths
        candidates = [
            "claude",
            "/usr/local/bin/claude",
            str(Path.home() / ".local/bin" / "claude")
        ]

        for candidate in candidates:
            try:
                result = subprocess.run(
                    [candidate, "--version"],
                    capture_output=True,
                    text=True,
                    timeout=5
                )
                if result.returncode == 0:
                    return candidate
            except (subprocess.TimeoutExpired, FileNotFoundError):
                continue

        raise RuntimeError("Claude Code CLI not found. Install with: npm install -g @anthropic-ai/claude-code")

    def execute(self, request: ClaudeRequest) -> ClaudeResponse:
        """
        Execute Claude Code CLI with the given request.

        Args:
            request: ClaudeRequest with prompt and context

        Returns:
            ClaudeResponse with results
        """
        # Build command
        cmd = [self.claude_path]

        if request.headless:
            cmd.extend(["-p"])

        # Add output format
        cmd.extend(["--output-format", request.output_format])

        # Prepare prompt file (for long prompts)
        with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
            f.write(request.prompt)
            prompt_file = f.name

        try:
            # Add prompt from stdin
            cmd.extend(["--prompt-stdin"])

            # Execute
            process = subprocess.run(
                cmd,
                input=request.prompt,
                capture_output=True,
                text=True,
                cwd=self.project_root,
                timeout=300  # 5 minute timeout
            )

            # Parse response
            return self._parse_response(process.stdout, process.stderr, process.returncode)

        finally:
            os.unlink(prompt_file)

    def _parse_response(self, stdout: str, stderr: str, returncode: int) -> ClaudeResponse:
        """Parse Claude Code CLI response"""
        if returncode != 0:
            return ClaudeResponse(
                success=False,
                output="",
                error=stderr or stdout,
                files_modified=[]
            )

        # Try to parse as JSON stream
        try:
            lines = stdout.strip().split('\n')
            results = []
            files_modified = set()

            for line in lines:
                if line.strip():
                    data = json.loads(line)
                    results.append(data)

                    # Extract file modifications
                    if 'tool_uses' in data:
                        for tool_use in data['tool_uses']:
                            if tool_use.get('name') == 'Edit':
                                files_modified.add(tool_use['input']['file_path'])

            return ClaudeResponse(
                success=True,
                output=stdout,
                error=None,
                files_modified=list(files_modified),
                tokens_used=sum(r.get('usage', {}).get('input_tokens', 0) + r.get('usage', {}).get('output_tokens', 0) for r in results)
            )

        except json.JSONDecodeError:
            # Fallback to plain text
            return ClaudeResponse(
                success=True,
                output=stdout,
                error=None,
                files_modified=[],
                tokens_used=0
            )


# CLI interface for testing
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python run_claude_code.py <prompt>")
        sys.exit(1)

    runner = ClaudeCodeRunner(Path.cwd())
    request = ClaudeRequest(
        prompt=sys.argv[1],
        context_files=[],
        task_type="test"
    )

    response = runner.execute(request)

    if response.success:
        print("Success!")
        print(response.output)
    else:
        print("Error:", response.error)
        sys.exit(1)
```

#### 1.2.2 Context Manager

**File**: `.github/actions/claude-code-runner/scripts/context_manager.py`

```python
"""
Context management for Claude Code interactions.

Handles loading project context, managing CLAUDE.md files,
and preparing prompts with appropriate context.
"""

import json
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass


@dataclass
class ProjectContext:
    """Project context information"""
    language: str
    framework: Optional[str]
    dependencies: List[str]
    test_framework: Optional[str]
    build_system: Optional[str]
    custom_guidelines: List[str]


class ContextManager:
    """Manages project context for Claude Code"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.claude_md_path = project_root / "CLAUDE.md"
        self.context_cache = {}

    def load_context(self) -> ProjectContext:
        """Load project context from various sources"""
        cache_key = str(self.project_root)

        if cache_key in self.context_cache:
            return self.context_cache[cache_key]

        context = self._analyze_project()
        self.context_cache[cache_key] = context
        return context

    def _analyze_project(self) -> ProjectContext:
        """Analyze project structure and configuration"""
        # Detect language
        language = self._detect_language()

        # Load configuration
        config = self._load_config_files()

        return ProjectContext(
            language=language,
            framework=config.get('framework'),
            dependencies=config.get('dependencies', []),
            test_framework=config.get('test_framework'),
            build_system=config.get('build_system'),
            custom_guidelines=self._load_custom_guidelines()
        )

    def _detect_language(self) -> str:
        """Detect primary programming language"""
        indicators = {
            'python': ['*.py', 'requirements.txt', 'pyproject.toml', 'setup.py'],
            'cpp': ['*.cpp', '*.hpp', 'CMakeLists.txt', 'Makefile'],
            'javascript': ['*.js', 'package.json', 'yarn.lock'],
            'typescript': ['*.ts', 'tsconfig.json', 'package.json'],
            'go': ['*.go', 'go.mod', 'go.sum'],
            'rust': ['*.rs', 'Cargo.toml']
        }

        for language, patterns in indicators.items():
            for pattern in patterns:
                if list(self.project_root.rglob(pattern)):
                    return language

        return 'unknown'

    def _load_config_files(self) -> Dict[str, Any]:
        """Load configuration from various files"""
        config = {}

        # Python
        if (self.project_root / "pyproject.toml").exists():
            config.update(self._parse_pyproject())

        # C++
        if (self.project_root / "CMakeLists.txt").exists():
            config['build_system'] = 'cmake'

        # Node.js
        if (self.project_root / "package.json").exists():
            config.update(self._parse_package_json())

        return config

    def _parse_pyproject(self) -> Dict[str, Any]:
        """Parse pyproject.toml for Python projects"""
        try:
            import tomllib
        except ImportError:
            import tomli as tomllib

        pyproject_path = self.project_root / "pyproject.toml"
        with open(pyproject_path, 'rb') as f:
            data = tomllib.load(f)

        config = {}

        # Extract dependencies
        deps = []
        if 'project' in data:
            deps.extend(data['project'].get('dependencies', []))
        if 'tool' in data and 'poetry' in data['tool']:
            deps.extend(data['tool']['poetry'].get('dependencies', {}).keys())

        config['dependencies'] = deps

        # Detect test framework
        if 'tool' in data:
            if 'pytest' in str(data['tool']):
                config['test_framework'] = 'pytest'
            elif 'unittest' in str(data['tool']):
                config['test_framework'] = 'unittest'

        return config

    def _parse_package_json(self) -> Dict[str, Any]:
        """Parse package.json for Node.js projects"""
        package_path = self.project_root / "package.json"

        with open(package_path) as f:
            data = json.load(f)

        config = {}
        config['dependencies'] = list(data.get('dependencies', {}).keys())
        config['framework'] = data.get('name', '')  # Often contains framework hint

        return config

    def _load_custom_guidelines(self) -> List[str]:
        """Load custom guidelines from CLAUDE.md"""
        if not self.claude_md_path.exists():
            return []

        with open(self.claude_md_path) as f:
            content = f.read()

        guidelines = []
        current_section = None

        for line in content.split('\n'):
            if line.startswith('## '):
                current_section = line[3:].strip()
            elif line.startswith('- ') and current_section == 'Custom Guidelines':
                guidelines.append(line[2:].strip())

        return guidelines

    def prepare_prompt(self, template_path: Path, variables: Dict[str, str]) -> str:
        """Prepare prompt from template with variables"""
        with open(template_path) as f:
            template = f.read()

        # Replace variables
        for key, value in variables.items():
            template = template.replace(f"${{{key}}}", value)

        return template

    def get_context_for_prompt(self) -> str:
        """Get formatted context for inclusion in prompts"""
        context = self.load_context()

        context_str = f"""## Project Context
- **Language**: {context.language}
- **Framework**: {context.framework or 'None'}
- **Test Framework**: {context.test_framework or 'None'}
- **Build System**: {context.build_system or 'None'}
- **Dependencies**: {', '.join(context.dependencies[:10])}{'...' if len(context.dependencies) > 10 else ''}"""

        if context.custom_guidelines:
            context_str += f"\n- **Custom Guidelines**: {', '.join(context.custom_guidelines[:3])}"

        return context_str
```

### 1.3 GitHub Action

**File**: `.github/actions/claude-code-runner/action.yaml`

```yaml
name: 'Claude Code Runner'
description: 'Run Claude Code CLI for automated workflows'
author: 'AI Assistant'

inputs:
  task-type:
    description: 'Type of task (fix-ci, implement-feature, review-pr)'
    required: true
  prompt:
    description: 'Prompt for Claude Code'
    required: false
  context-files:
    description: 'Comma-separated list of context files'
    required: false
    default: ''
  working-directory:
    description: 'Working directory for Claude Code'
    required: false
    default: '.'
  api-key:
    description: 'Anthropic API key'
    required: true

outputs:
  success:
    description: 'Whether Claude Code execution succeeded'
  files-modified:
    description: 'List of files modified by Claude Code'
  output:
    description: 'Output from Claude Code'
  tokens-used:
    description: 'Number of tokens used'

runs:
  using: 'composite'
  steps:
    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: '3.11'

    - name: Install dependencies
      shell: bash
      run: |
        pip install tomli

    - name: Set ANTHROPIC_API_KEY
      shell: bash
      env:
        INPUT_API_KEY: ${{ inputs.api-key }}
      run: |
        echo "ANTHROPIC_API_KEY=$INPUT_API_KEY" >> $GITHUB_ENV

    - name: Run Claude Code
      shell: bash
      env:
        INPUT_TASK_TYPE: ${{ inputs.task-type }}
        INPUT_PROMPT: ${{ inputs.prompt }}
        INPUT_CONTEXT_FILES: ${{ inputs.context-files }}
        INPUT_WORKING_DIRECTORY: ${{ inputs.working-directory }}
      run: |
        python3 ${{ github.action_path }}/scripts/run_claude_code.py \
          --task-type "$INPUT_TASK_TYPE" \
          --prompt "$INPUT_PROMPT" \
          --context-files "$INPUT_CONTEXT_FILES" \
          --working-directory "$INPUT_WORKING_DIRECTORY"

    - name: Save outputs
      shell: bash
      run: |
        if [ -f "${{ github.workspace }}/claude_result.json" ]; then
          echo "success=$(jq -r '.success' claude_result.json)" >> $GITHUB_OUTPUT
          echo "files-modified=$(jq -r '.files_modified | join(",")' claude_result.json)" >> $GITHUB_OUTPUT
          echo "tokens-used=$(jq -r '.tokens_used' claude_result.json)" >> $GITHUB_OUTPUT
        fi
```

## Phase 2: Cookiecutter Template Updates (Week 1, Days 4-5)

### Objective
Enhance existing Cookiecutter templates to include AI automation components.

### 2.1 Python Template Updates

**File**: `{{cookiecutter.project_name}}/CLAUDE.md`

```markdown
# AI Assistant Workflow Guide - {{cookiecutter.project_name}}

## Project Context
- **Language**: Python {{cookiecutter.python_version}}
- **Framework**: {{cookiecutter.framework}}
- **Package Manager**: {{cookiecutter.package_manager}}

## Code Standards
- Use type hints everywhere
- Follow PEP 8 for formatting
- Write docstrings for all functions
- Maintain test coverage above {{cookiecutter.min_test_coverage}}%

## Development Workflow
1. Create feature branch from main
2. Write tests first (TDD)
3. Implement functionality
4. Run `python -m pytest` to verify
5. Submit PR with `ai-review` label for automated review

## Custom Guidelines
{% if cookiecutter.custom_guidelines %}
{{cookiecutter.custom_guidelines}}
{% endif %}
```

### 2.2 Post-Generation Hook Updates

**File**: `hooks/post_gen_project.py`

```python
#!/usr/bin/env python3
"""Post-generation script for Cookiecutter template."""

import json
import subprocess
import sys
from pathlib import Path


def main():
    """Main post-generation setup."""
    project_dir = Path.cwd()

    # Initialize git repository
    subprocess.run(['git', 'init'], check=True)
    subprocess.run(['git', 'add', '.'], check=True)
    subprocess.run(['git', 'commit', '-m', 'Initial commit from template'], check=True)

    # Install dependencies
    if '{{cookiecutter.package_manager}}' == 'pip':
        subprocess.run([sys.executable, '-m', 'pip', 'install', '-e', '.[dev]'], check=True)
    elif '{{cookiecutter.package_manager}}' == 'poetry':
        subprocess.run(['poetry', 'install'], check=True)

    # Set up pre-commit hooks
    subprocess.run(['pre-commit', 'install'], check=True)

    # Run initial tests
    subprocess.run([sys.executable, '-m', 'pytest'], check=True)

    print("\n✅ Project setup complete!")
    print("🚀 Ready for development with AI automation!")


if __name__ == '__main__':
    main()
```

### Implementation Checklist

**Phase 1 Deliverables**:
- [ ] Create directory structure
- [ ] Implement `run_claude_code.py` with Claude Code CLI integration
- [ ] Develop `context_manager.py` for project context management
- [ ] Create `action.yaml` composite GitHub Action
- [ ] Write unit tests for all components
- [ ] Test Claude Code CLI integration

**Phase 2 Deliverables**:
- [ ] Update Python Cookiecutter template
- [ ] Update C++ Cookiecutter template
- [ ] Enhance post-generation hooks
- [ ] Add CLAUDE.md templates
- [ ] Test template generation with AI components
- [ ] Validate all templates generate correctly

---

**Document Version**: 1.0
**Last Updated**: 2025-10-15
**Status**: Ready for Implementation
**Author**: Claude Code AI Assistant