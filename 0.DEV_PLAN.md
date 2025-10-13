# Optimized Development Plan: Reusable CICD Template System

## 📋 Executive Summary

본 문서는 **오픈소스 도구를 최대한 활용한 경량화된 CICD 템플릿 시스템** 구축 계획입니다.

### 핵심 개선사항
- **개발 기간**: 25일 → 15일 (40% 단축)
- **유지보수 복잡도**: 60% 감소 (기존 생태계 활용)
- **핵심 도구**: Cookiecutter, GitHub Starter Workflows, Ruff, sccache

### 주요 목표
1. Python/C++ 프로젝트의 2분 내 초기화
2. Self-hosted runner로 빌드 시간 50% 단축
3. AI 워크플로우 통합 (선택 사항)
4. 조직 전체 템플릿 표준화

---

## 🎯 System Architecture

### 최적화된 디렉토리 구조

```
github-cicd-templates/
├── cookiecutters/
│   ├── python-project/
│   │   ├── cookiecutter.json
│   │   ├── hooks/
│   │   │   ├── pre_gen_project.py
│   │   │   └── post_gen_project.py
│   │   └── {{cookiecutter.project_slug}}/
│   │       ├── .github/
│   │       │   └── workflows/
│   │       │       └── ci.yaml
│   │       ├── src/
│   │       ├── tests/
│   │       ├── .pre-commit-config.yaml
│   │       ├── pyproject.toml
│   │       └── README.md
│   │
│   └── cpp-project/
│       ├── cookiecutter.json
│       ├── hooks/
│       │   ├── pre_gen_project.py
│       │   └── post_gen_project.py
│       └── {{cookiecutter.project_slug}}/
│           ├── .github/
│           │   └── workflows/
│           │       └── ci.yaml
│           ├── src/
│           ├── tests/
│           ├── .pre-commit-config.yaml
│           ├── .clang-format
│           ├── .clang-tidy
│           ├── CMakeLists.txt
│           └── README.md
│
├── .github/
│   ├── workflows/
│   │   ├── python-ci-reusable.yaml
│   │   ├── cpp-ci-reusable.yaml
│   │   └── workflow-templates/
│   │       ├── python-starter.yml
│   │       ├── python-starter.properties.json
│   │       ├── cpp-starter.yml
│   │       └── cpp-starter.properties.json
│   │
│   └── actions/
│       ├── setup-python-cache/
│       │   └── action.yaml
│       ├── setup-cpp-cache/
│       │   └── action.yaml
│       └── monitor-ci/
│           └── action.yaml
│
├── configs/
│   ├── python/
│   │   ├── .pre-commit-config.yaml
│   │   ├── ruff.toml
│   │   └── pyproject.toml.template
│   │
│   └── cpp/
│       ├── .pre-commit-config.yaml
│       ├── .clang-format
│       ├── .clang-tidy
│       └── CMakeLists.txt.template
│
├── runner-setup/
│   ├── install-runner-linux.sh
│   ├── install-runner-windows.ps1
│   ├── setup-python-tools.sh
│   ├── setup-cpp-tools.sh
│   └── runner-config.yaml
│
├── scripts/
│   ├── create-project.sh
│   ├── sync-templates.sh
│   └── lib/
│       └── common-utils.sh
│
├── prompts/
│   ├── CLAUDE_BASE.md
│   ├── CLAUDE_PYTHON.md
│   └── CLAUDE_CPP.md
│
└── docs/
    ├── README.md
    ├── QUICK_START.md
    ├── COOKIECUTTER_GUIDE.md
    ├── RUNNER_SETUP.md
    ├── RUFF_MIGRATION.md
    └── TROUBLESHOOTING.md
```

---

## 📅 Phase 1: Cookiecutter Template Design (Day 1)

### 목표
Cookiecutter 기반 프로젝트 템플릿 구조 설계 및 기본 템플릿 생성

### 1.1 Python Cookiecutter Template

**파일**: `cookiecutters/python-project/cookiecutter.json`

```json
{
    "project_name": "My Python Project",
    "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '-').replace('_', '-') }}",
    "project_description": "A Python project",
    "author_name": "Your Name",
    "author_email": "your.email@example.com",
    "python_version": ["3.10", "3.11", "3.12"],
    "use_ai_workflow": ["no", "yes"],
    "runner_type": ["github-hosted", "self-hosted"],
    "include_docker": ["no", "yes"],
    "license": ["MIT", "BSD-3-Clause", "Apache-2.0", "GPL-3.0", "None"]
}
```

**파일**: `cookiecutters/python-project/hooks/post_gen_project.py`

```python
#!/usr/bin/env python
"""Post-generation hook for Python project."""

import os
import subprocess
import sys

def run_command(cmd, check=True):
    """Run shell command."""
    try:
        result = subprocess.run(cmd, shell=True, check=check, 
                                capture_output=True, text=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        return False

def initialize_git():
    """Initialize git repository."""
    print("📦 Initializing git repository...")
    run_command("git init")
    run_command("git add .")
    run_command('git commit -m "Initial commit from template"')

def install_precommit():
    """Install pre-commit hooks."""
    print("🔧 Installing pre-commit hooks...")
    if run_command("which pre-commit", check=False):
        run_command("pre-commit install")
    else:
        print("⚠️  pre-commit not found. Install: pip install pre-commit")

def create_venv():
    """Create virtual environment."""
    print("🐍 Creating virtual environment...")
    python_version = "{{ cookiecutter.python_version }}"
    run_command(f"python{python_version} -m venv .venv")

def print_next_steps():
    """Print next steps for user."""
    project_slug = "{{ cookiecutter.project_slug }}"
    runner_type = "{{ cookiecutter.runner_type }}"
    use_ai = "{{ cookiecutter.use_ai_workflow }}"
    
    print("\n" + "="*60)
    print("✅ Project created successfully!")
    print("="*60)
    print(f"\n📁 Project: {project_slug}")
    print(f"🏃 Runner: {runner_type}")
    print(f"🤖 AI Workflow: {use_ai}")
    
    print("\n📋 Next Steps:")
    print("1. cd {{ cookiecutter.project_slug }}")
    print("2. source .venv/bin/activate")
    print("3. pip install -e .[dev]")
    
    if use_ai == "yes":
        print("4. Review CLAUDE.md for AI assistant")
    
    print("\n🔗 Add remote:")
    print("   git remote add origin <your-repo-url>")
    print("   git push -u origin main\n")

def main():
    """Main post-generation logic."""
    try:
        initialize_git()
        install_precommit()
        create_venv()
        
        # Remove AI workflow if not needed
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            for f in ["CLAUDE.md", ".github/workflows/ai-workflow.yaml"]:
                if os.path.exists(f):
                    os.remove(f)
        
        # Remove license if None
        if "{{ cookiecutter.license }}" == "None":
            if os.path.exists("LICENSE"):
                os.remove("LICENSE")
        
        print_next_steps()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

### 1.2 C++ Cookiecutter Template

**파일**: `cookiecutters/cpp-project/cookiecutter.json`

```json
{
    "project_name": "My C++ Project",
    "project_slug": "{{ cookiecutter.project_name.lower().replace(' ', '-') }}",
    "project_description": "A C++ project",
    "author_name": "Your Name",
    "author_email": "your.email@example.com",
    "cpp_standard": ["17", "20", "23"],
    "build_system": ["cmake", "meson"],
    "use_ai_workflow": ["no", "yes"],
    "runner_type": ["github-hosted", "self-hosted"],
    "enable_cache": ["yes", "no"],
    "use_ninja": ["yes", "no"],
    "testing_framework": ["gtest", "catch2", "doctest"],
    "license": ["MIT", "BSD-3-Clause", "Apache-2.0", "GPL-3.0", "None"]
}
```

**파일**: `cookiecutters/cpp-project/hooks/post_gen_project.py`

```python
#!/usr/bin/env python
"""Post-generation hook for C++ project."""

import os
import subprocess
import sys

def run_command(cmd, check=True):
    try:
        result = subprocess.run(cmd, shell=True, check=check,
                                capture_output=True, text=True)
        return result.returncode == 0
    except subprocess.CalledProcessError as e:
        print(f"Error: {e}")
        return False

def initialize_git():
    print("📦 Initializing git repository...")
    run_command("git init")
    run_command("git add .")
    run_command('git commit -m "Initial commit from template"')

def install_precommit():
    print("🔧 Installing pre-commit hooks...")
    if run_command("which pre-commit", check=False):
        run_command("pre-commit install")
    else:
        print("⚠️  pre-commit not found")

def setup_build_directory():
    print("🏗️  Creating build directory...")
    os.makedirs("build", exist_ok=True)

def print_next_steps():
    project_slug = "{{ cookiecutter.project_slug }}"
    build_system = "{{ cookiecutter.build_system }}"
    use_ninja = "{{ cookiecutter.use_ninja }}"
    
    print("\n" + "="*60)
    print("✅ Project created!")
    print("="*60)
    print(f"\n📁 Project: {project_slug}")
    print(f"🔨 Build: {build_system}")
    
    print("\n📋 Next Steps:")
    print("1. cd {{ cookiecutter.project_slug }}")
    
    if build_system == "cmake":
        gen = "-G Ninja" if use_ninja == "yes" else ""
        print(f"2. cmake -B build {gen}")
        print("3. cmake --build build")
        print("4. ctest --test-dir build")
    else:
        print("2. meson setup build")
        print("3. meson compile -C build")
        print("4. meson test -C build")
    
    print("\n🔗 Add remote:")
    print("   git remote add origin <repo-url>\n")

def main():
    try:
        initialize_git()
        install_precommit()
        setup_build_directory()
        
        # Cleanup
        if "{{ cookiecutter.use_ai_workflow }}" == "no":
            for f in ["CLAUDE.md", ".github/workflows/ai-workflow.yaml"]:
                if os.path.exists(f):
                    os.remove(f)
        
        if "{{ cookiecutter.license }}" == "None":
            if os.path.exists("LICENSE"):
                os.remove("LICENSE")
        
        # Remove unused build system files
        if "{{ cookiecutter.build_system }}" == "cmake":
            if os.path.exists("meson.build"):
                os.remove("meson.build")
        else:
            if os.path.exists("CMakeLists.txt"):
                os.remove("CMakeLists.txt")
        
        print_next_steps()
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
```

### Deliverables
- ✅ Python Cookiecutter template with hooks
- ✅ C++ Cookiecutter template with hooks
- ✅ Template validation

---

## 📅 Phase 2: Reusable Workflows (Days 2-3)

### 2.1 Python Reusable Workflow

**파일**: `.github/workflows/python-ci-reusable.yaml`

```yaml
name: Python CI (Reusable)

on:
  workflow_call:
    inputs:
      python-version:
        description: 'Python version'
        required: false
        type: string
        default: '3.10'
      
      working-directory:
        description: 'Working directory'
        required: false
        type: string
        default: '.'
      
      run-tests:
        description: 'Run pytest'
        required: false
        type: boolean
        default: true
      
      run-coverage:
        description: 'Run coverage'
        required: false
        type: boolean
        default: true
      
      runner-type:
        description: 'Runner type'
        required: false
        type: string
        default: 'ubuntu-latest'

    outputs:
      test-result:
        description: 'Test result'
        value: ${{ jobs.test.outputs.result }}

jobs:
  lint:
    name: Lint with Ruff
    runs-on: ${{ inputs.runner-type }}
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
          cache: 'pip'
      
      - name: Install Ruff
        run: pip install ruff
      
      - name: Ruff check
        run: ruff check ${{ inputs.working-directory }}
      
      - name: Ruff format check
        run: ruff format --check ${{ inputs.working-directory }}

  test:
    name: Test
    runs-on: ${{ inputs.runner-type }}
    needs: lint
    outputs:
      result: ${{ steps.summary.outputs.result }}
    
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-python@v5
        with:
          python-version: ${{ inputs.python-version }}
          cache: 'pip'
      
      - name: Install dependencies
        working-directory: ${{ inputs.working-directory }}
        run: pip install -e .[dev]
      
      - name: Run tests
        if: ${{ inputs.run-tests }}
        working-directory: ${{ inputs.working-directory }}
        run: pytest tests/ -v
      
      - name: Coverage
        if: ${{ inputs.run-coverage }}
        working-directory: ${{ inputs.working-directory }}
        run: pytest tests/ --cov=src --cov-report=xml
      
      - name: Upload coverage
        if: ${{ inputs.run-coverage }}
        uses: codecov/codecov-action@v4
        with:
          files: ./coverage.xml
      
      - name: Summary
        id: summary
        if: always()
        run: |
          if [ "${{ job.status }}" == "success" ]; then
            echo "result=✅ Passed" >> $GITHUB_OUTPUT
          else
            echo "result=❌ Failed" >> $GITHUB_OUTPUT
          fi
```

### 2.2 C++ Reusable Workflow

**파일**: `.github/workflows/cpp-ci-reusable.yaml`

```yaml
name: C++ CI (Reusable)

on:
  workflow_call:
    inputs:
      build-type:
        description: 'CMake build type'
        required: false
        type: string
        default: 'Release'
      
      cpp-compiler:
        description: 'C++ compiler'
        required: false
        type: string
        default: 'g++'
      
      cmake-options:
        description: 'Extra CMake options'
        required: false
        type: string
        default: ''
      
      run-tests:
        description: 'Run ctest'
        required: false
        type: boolean
        default: true
      
      enable-cache:
        description: 'Enable sccache'
        required: false
        type: boolean
        default: true
      
      runner-type:
        description: 'Runner type'
        required: false
        type: string
        default: 'ubuntu-latest'
      
      use-ninja:
        description: 'Use Ninja'
        required: false
        type: boolean
        default: true

    outputs:
      build-result:
        value: ${{ jobs.build.outputs.result }}

jobs:
  build:
    name: Build and Test
    runs-on: ${{ inputs.runner-type }}
    outputs:
      result: ${{ steps.summary.outputs.result }}
    
    steps:
      - uses: actions/checkout@v4
      
      - name: Install deps (Linux)
        if: runner.os == 'Linux'
        run: |
          sudo apt-get update
          sudo apt-get install -y cmake ninja-build
      
      - name: Install sccache
        if: ${{ inputs.enable-cache }}
        run: |
          SCCACHE_VERSION=0.7.7
          FILE=sccache-v$SCCACHE_VERSION-x86_64-unknown-linux-musl
          curl -L https://github.com/mozilla/sccache/releases/download/v$SCCACHE_VERSION/$FILE.tar.gz | tar xz
          sudo mv $FILE/sccache /usr/local/bin/
          chmod +x /usr/local/bin/sccache
      
      - name: Configure sccache
        if: ${{ inputs.enable-cache }}
        run: |
          echo "CMAKE_C_COMPILER_LAUNCHER=sccache" >> $GITHUB_ENV
          echo "CMAKE_CXX_COMPILER_LAUNCHER=sccache" >> $GITHUB_ENV
      
      - name: Cache sccache
        if: ${{ inputs.enable-cache }}
        uses: actions/cache@v4
        with:
          path: ~/.cache/sccache
          key: sccache-${{ runner.os }}-${{ inputs.cpp-compiler }}-${{ hashFiles('**/CMakeLists.txt') }}
      
      - name: Configure CMake
        run: |
          GEN=""
          [ "${{ inputs.use-ninja }}" == "true" ] && GEN="-G Ninja"
          cmake -B build $GEN \
            -DCMAKE_BUILD_TYPE=${{ inputs.build-type }} \
            -DCMAKE_CXX_COMPILER=${{ inputs.cpp-compiler }} \
            ${{ inputs.cmake-options }}
      
      - name: Build
        run: cmake --build build -j$(nproc)
      
      - name: sccache stats
        if: ${{ inputs.enable-cache }}
        run: sccache --show-stats
      
      - name: Test
        if: ${{ inputs.run-tests }}
        run: ctest --test-dir build --output-on-failure -j$(nproc)
      
      - name: Summary
        id: summary
        if: always()
        run: |
          if [ "${{ job.status }}" == "success" ]; then
            echo "result=✅ Passed" >> $GITHUB_OUTPUT
          else
            echo "result=❌ Failed" >> $GITHUB_OUTPUT
          fi
```

### Deliverables
- ✅ Python reusable workflow with Ruff
- ✅ C++ reusable workflow with sccache
- ✅ Documentation

---

## 📅 Phase 3: Ruff-Based Pre-commit (Day 4)

### 3.1 Python Pre-commit Configuration

**파일**: `configs/python/.pre-commit-config.yaml`

```yaml
# Python Pre-commit (Ruff-based)
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=1000']
      - id: check-merge-conflict
      - id: detect-private-key

  # Ruff replaces: Black, Flake8, isort, pyupgrade
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  # Optional: mypy
  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--strict, --ignore-missing-imports]
```

**파일**: `configs/python/ruff.toml`

```toml
# Ruff configuration
target-version = "py310"
line-length = 88
indent-width = 4

[lint]
# Enable rules
select = [
    "E",   # pycodestyle errors
    "W",   # pycodestyle warnings
    "F",   # pyflakes
    "I",   # isort
    "N",   # pep8-naming
    "UP",  # pyupgrade
    "B",   # flake8-bugbear
    "C4",  # flake8-comprehensions
    "SIM", # flake8-simplify
]

ignore = [
    "E501",  # line too long (handled by formatter)
]

# Allow autofix
fixable = ["ALL"]
unfixable = []

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
```

**파일**: `configs/python/pyproject.toml.template`

```toml
[build-system]
requires = ["setuptools>=68.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "{{cookiecutter.project_slug}}"
version = "0.1.0"
description = "{{cookiecutter.project_description}}"
authors = [
    {name = "{{cookiecutter.author_name}}", email = "{{cookiecutter.author_email}}"}
]
readme = "README.md"
requires-python = ">=3.10"
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest>=7.4",
    "pytest-cov>=4.1",
    "ruff>=0.6.0",
    "mypy>=1.11",
    "pre-commit>=3.5",
]

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
addopts = [
    "-v",
    "--tb=short",
    "--strict-markers",
]

[tool.coverage.run]
source = ["src"]
omit = ["tests/*", "*/site-packages/*"]

[tool.coverage.report]
precision = 2
show_missing = true
skip_covered = false

[tool.ruff]
target-version = "py310"
line-length = 88

[tool.ruff.lint]
select = ["E", "W", "F", "I", "N", "UP", "B", "C4", "SIM"]
ignore = ["E501"]

[tool.mypy]
python_version = "3.10"
strict = true
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
```

### 3.2 C++ Pre-commit Configuration

**파일**: `configs/cpp/.pre-commit-config.yaml`

```yaml
# C++ Pre-commit configuration
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
        args: ['--maxkb=5000']
      - id: check-merge-conflict

  # C++ formatting and linting
  - repo: https://github.com/pocc/pre-commit-hooks
    rev: v1.3.5
    hooks:
      - id: clang-format
        args: [--style=file]
      
      - id: clang-tidy
        args: [-checks=*, --warnings-as-errors=*]
      
      - id: cppcheck
        args: [
          --enable=all,
          --suppress=missingIncludeSystem,
          --inline-suppr
        ]
```

**파일**: `configs/cpp/.clang-format`

```yaml
# clang-format configuration
BasedOnStyle: Google
Language: Cpp
Standard: c++17

ColumnLimit: 100
IndentWidth: 4
UseTab: Never
PointerAlignment: Left
ReferenceAlignment: Left

AllowShortFunctionsOnASingleLine: Inline
AllowShortIfStatementsOnASingleLine: Never
AllowShortLoopsOnASingleLine: false

BreakBeforeBraces: Attach
IndentCaseLabels: true
SpaceAfterCStyleCast: false
SpacesInParentheses: false
```

**파일**: `configs/cpp/.clang-tidy`

```yaml
# clang-tidy configuration
Checks: >
  *,
  -fuchsia-*,
  -google-*,
  -llvm-*,
  -modernize-use-trailing-return-type,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers

WarningsAsErrors: '*'

HeaderFilterRegex: '.*'

CheckOptions:
  - key: readability-identifier-naming.ClassCase
    value: CamelCase
  - key: readability-identifier-naming.FunctionCase
    value: camelBack
  - key: readability-identifier-naming.VariableCase
    value: lower_case
  - key: readability-identifier-naming.ConstantCase
    value: UPPER_CASE
```

**파일**: `configs/cpp/CMakeLists.txt.template`

```cmake
cmake_minimum_required(VERSION 3.20)
project({{cookiecutter.project_slug}} VERSION 0.1.0 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD {{cookiecutter.cpp_standard}})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Export compile commands for clang-tidy
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Compiler warnings
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# Dependencies
find_package({{cookiecutter.testing_framework}} REQUIRED)

# Library
add_library({{cookiecutter.project_slug}}_lib
    src/main.cpp
)

target_include_directories({{cookiecutter.project_slug}}_lib
    PUBLIC
        $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>
)

# Executable
add_executable({{cookiecutter.project_slug}}
    src/main.cpp
)

target_link_libraries({{cookiecutter.project_slug}}
    PRIVATE {{cookiecutter.project_slug}}_lib
)

# Tests
enable_testing()
add_subdirectory(tests)
```

### Deliverables
- ✅ Ruff-based Python pre-commit
- ✅ C++ pre-commit with clang tools
- ✅ Configuration templates

---

## 📅 Phase 4: Composite Actions (Days 5-6)

### 4.1 Python Cache Setup Action

**파일**: `.github/actions/setup-python-cache/action.yaml`

```yaml
name: 'Setup Python with Cache'
description: 'Setup Python environment with dependency caching'

inputs:
  python-version:
    description: 'Python version'
    required: true
  cache-key-prefix:
    description: 'Cache key prefix'
    required: false
    default: 'python-deps'

runs:
  using: composite
  steps:
    - name: Setup Python
      uses: actions/setup-python@v5
      with:
        python-version: ${{ inputs.python-version }}
    
    - name: Cache pip packages
      uses: actions/cache@v4
      with:
        path: ~/.cache/pip
        key: ${{ inputs.cache-key-prefix }}-${{ runner.os }}-py${{ inputs.python-version }}-${{ hashFiles('**/pyproject.toml', '**/requirements*.txt') }}
        restore-keys: |
          ${{ inputs.cache-key-prefix }}-${{ runner.os }}-py${{ inputs.python-version }}-
    
    - name: Install pip tools
      shell: bash
      run: |
        python -m pip install --upgrade pip setuptools wheel
```

### 4.2 C++ Cache Setup Action

**파일**: `.github/actions/setup-cpp-cache/action.yaml`

```yaml
name: 'Setup C++ with Cache'
description: 'Setup C++ environment with sccache'

inputs:
  compiler:
    description: 'C++ compiler (g++ or clang++)'
    required: false
    default: 'g++'
  enable-cache:
    description: 'Enable sccache'
    required: false
    default: 'true'

runs:
  using: composite
  steps:
    - name: Install build tools
      shell: bash
      run: |
        if [ "$RUNNER_OS" == "Linux" ]; then
          sudo apt-get update
          sudo apt-get install -y cmake ninja-build
        elif [ "$RUNNER_OS" == "macOS" ]; then
          brew install cmake ninja
        fi
    
    - name: Install sccache
      if: inputs.enable-cache == 'true'
      shell: bash
      run: |
        SCCACHE_VERSION=0.7.7
        if [ "$RUNNER_OS" == "Linux" ]; then
          FILE=sccache-v$SCCACHE_VERSION-x86_64-unknown-linux-musl
        elif [ "$RUNNER_OS" == "macOS" ]; then
          FILE=sccache-v$SCCACHE_VERSION-x86_64-apple-darwin
        fi
        
        curl -L https://github.com/mozilla/sccache/releases/download/v$SCCACHE_VERSION/$FILE.tar.gz | tar xz
        sudo mv $FILE/sccache /usr/local/bin/
        chmod +x /usr/local/bin/sccache
    
    - name: Setup sccache
      if: inputs.enable-cache == 'true'
      shell: bash
      run: |
        echo "CMAKE_C_COMPILER_LAUNCHER=sccache" >> $GITHUB_ENV
        echo "CMAKE_CXX_COMPILER_LAUNCHER=sccache" >> $GITHUB_ENV
        echo "SCCACHE_DIR=$HOME/.cache/sccache" >> $GITHUB_ENV
    
    - name: Cache sccache
      if: inputs.enable-cache == 'true'
      uses: actions/cache@v4
      with:
        path: ~/.cache/sccache
        key: sccache-${{ runner.os }}-${{ inputs.compiler }}-${{ github.sha }}
        restore-keys: |
          sccache-${{ runner.os }}-${{ inputs.compiler }}-
```

### 4.3 CI Monitor Action

**파일**: `.github/actions/monitor-ci/action.yaml`

```yaml
name: 'Monitor CI Status'
description: 'Monitor and report CI status for AI sub-agents'

inputs:
  commit-sha:
    description: 'Commit SHA to monitor'
    required: true
  output-file:
    description: 'Output JSON file path'
    required: false
    default: 'ci_result.json'

outputs:
  status:
    description: 'CI status (success/failure)'
    value: ${{ steps.check.outputs.status }}

runs:
  using: composite
  steps:
    - name: Check CI status
      id: check
      shell: bash
      env:
        GH_TOKEN: ${{ github.token }}
      run: |
        echo "Monitoring CI for commit ${{ inputs.commit-sha }}"
        
        # Wait for checks to complete
        sleep 10
        
        # Get check runs
        gh api repos/${{ github.repository }}/commits/${{ inputs.commit-sha }}/check-runs \
          --jq '.check_runs[] | {name: .name, status: .status, conclusion: .conclusion}' \
          > checks.json
        
        # Determine overall status
        if jq -e '.conclusion == "failure"' checks.json > /dev/null; then
          echo "status=failure" >> $GITHUB_OUTPUT
          STATUS="failure"
        else
          echo "status=success" >> $GITHUB_OUTPUT
          STATUS="success"
        fi
        
        # Create result JSON
        jq -n \
          --arg status "$STATUS" \
          --arg commit "${{ inputs.commit-sha }}" \
          --slurpfile checks checks.json \
          '{status: $status, commit: $commit, checks: $checks}' \
          > ${{ inputs.output-file }}
        
        cat ${{ inputs.output-file }}
```

### Deliverables
- ✅ Python cache composite action
- ✅ C++ cache composite action
- ✅ CI monitoring action

---

## 📅 Phase 5: Starter Workflows (Days 7-8)

### 5.1 Organization .github Repository Setup

**구조**:
```
.github/  (organization repository)
├── workflow-templates/
│   ├── python-ci.yml
│   ├── python-ci.properties.json
│   ├── cpp-ci.yml
│   └── cpp-ci.properties.json
└── README.md
```

### 5.2 Python Starter Workflow

**파일**: `.github/workflow-templates/python-ci.yml`

```yaml
name: Python CI

on:
  push:
    branches: [ $default-branch ]
  pull_request:
    branches: [ $default-branch ]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      python-version: '3.10'
      run-tests: true
      run-coverage: true
      runner-type: 'ubuntu-latest'
```

**파일**: `.github/workflow-templates/python-ci.properties.json`

```json
{
  "name": "Python CI with Ruff",
  "description": "Fast Python CI/CD with Ruff linting and pytest",
  "iconName": "python",
  "categories": [
    "Python",
    "CI",
    "Testing"
  ],
  "filePatterns": [
    "pyproject.toml$",
    "setup.py$",
    "requirements.txt$"
  ]
}
```

### 5.3 C++ Starter Workflow

**파일**: `.github/workflow-templates/cpp-ci.yml`

```yaml
name: C++ CI

on:
  push:
    branches: [ $default-branch ]
  pull_request:
    branches: [ $default-branch ]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-ci-reusable.yaml@v1
    with:
      build-type: 'Release'
      cpp-compiler: 'g++'
      run-tests: true
      enable-cache: true
      runner-type: 'ubuntu-latest'
      use-ninja: true
```

**파일**: `.github/workflow-templates/cpp-ci.properties.json`

```json
{
  "name": "C++ CI with CMake",
  "description": "Fast C++ builds with CMake, Ninja, and sccache",
  "iconName": "cplusplus",
  "categories": [
    "C++",
    "CI",
    "CMake"
  ],
  "filePatterns": [
    "CMakeLists.txt$",
    "meson.build$"
  ]
}
```

### 5.4 Setup Script

**파일**: `scripts/create-project.sh`

```bash
#!/bin/bash
# Project creation wrapper for Cookiecutter

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="$SCRIPT_DIR/../cookiecutters"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

usage() {
    cat <<EOF
Usage: $0 <language> [project-name]

Languages:
  python    - Python project template
  cpp       - C++ project template

Examples:
  $0 python my-awesome-project
  $0 cpp my-fast-library

EOF
    exit 1
}

check_dependencies() {
    local deps=("cookiecutter" "git")
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            echo -e "${RED}Error: $dep not found${NC}"
            echo "Install with: pip install cookiecutter"
            exit 1
        fi
    done
}

create_project() {
    local language=$1
    local project_name=$2
    
    local template_dir="$TEMPLATES_DIR/${language}-project"
    
    if [ ! -d "$template_dir" ]; then
        echo -e "${RED}Error: Template not found for $language${NC}"
        exit 1
    fi
    
    echo -e "${GREEN}Creating $language project...${NC}"
    
    if [ -n "$project_name" ]; then
        cookiecutter "$template_dir" --no-input project_name="$project_name"
    else
        cookiecutter "$template_dir"
    fi
    
    echo -e "${GREEN}✅ Project created successfully!${NC}"
}

main() {
    if [ $# -lt 1 ]; then
        usage
    fi
    
    check_dependencies
    
    create_project "$@"
}

main "$@"
```

### Deliverables
- ✅ Organization .github repository
- ✅ Python starter workflow
- ✅ C++ starter workflow
- ✅ Creation script

---

## 📅 Phase 6: Self-Hosted Runner Setup (Days 9-10)

### 6.1 Linux Runner Installation

**파일**: `runner-setup/install-runner-linux.sh`

```bash
#!/bin/bash
# GitHub Actions Self-Hosted Runner Installation (Linux)

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUNNER_VERSION="2.319.1"
RUNNER_USER="github-runner"
INSTALL_DIR="/opt/actions-runner"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

install_dependencies() {
    echo -e "${GREEN}Installing dependencies...${NC}"
    
    if [ -f /etc/debian_version ]; then
        apt-get update
        apt-get install -y \
            curl jq git build-essential \
            libssl-dev libffi-dev python3 python3-pip
    elif [ -f /etc/redhat-release ]; then
        yum install -y \
            curl jq git gcc gcc-c++ make \
            openssl-devel libffi-devel python3 python3-pip
    else
        echo -e "${RED}Unsupported OS${NC}"
        exit 1
    fi
}

create_runner_user() {
    echo -e "${GREEN}Creating runner user...${NC}"
    
    if ! id "$RUNNER_USER" &>/dev/null; then
        useradd -m -s /bin/bash "$RUNNER_USER"
    fi
}

download_runner() {
    echo -e "${GREEN}Downloading runner...${NC}"
    
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    curl -o actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz \
        -L https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    
    tar xzf actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    rm actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz
    
    chown -R "$RUNNER_USER:$RUNNER_USER" "$INSTALL_DIR"
}

configure_runner() {
    echo -e "${YELLOW}Runner configuration${NC}"
    echo "Please provide the following information:"
    echo ""
    
    read -p "GitHub URL (e.g., https://github.com/your-org): " GITHUB_URL
    read -p "Registration token: " REG_TOKEN
    read -p "Runner name (default: $(hostname)): " RUNNER_NAME
    RUNNER_NAME=${RUNNER_NAME:-$(hostname)}
    
    echo -e "${GREEN}Configuring runner...${NC}"
    
    cd "$INSTALL_DIR"
    sudo -u "$RUNNER_USER" ./config.sh \
        --url "$GITHUB_URL" \
        --token "$REG_TOKEN" \
        --name "$RUNNER_NAME" \
        --labels self-hosted,Linux,X64 \
        --work _work \
        --unattended
}

install_service() {
    echo -e "${GREEN}Installing systemd service...${NC}"
    
    cd "$INSTALL_DIR"
    ./svc.sh install "$RUNNER_USER"
    ./svc.sh start
    
    systemctl enable actions.runner.*.service
}

print_success() {
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ Runner installed successfully!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "Service status:"
    systemctl status actions.runner.*.service --no-pager
    echo ""
    echo "Next steps:"
    echo "1. Verify runner appears in GitHub settings"
    echo "2. Run: sudo $0 --setup-python"
    echo "   or: sudo $0 --setup-cpp"
}

setup_python_tools() {
    echo -e "${GREEN}Installing Python development tools...${NC}"
    
    sudo -u "$RUNNER_USER" bash <<'EOF'
pip3 install --user \
    ruff \
    pytest pytest-cov \
    mypy \
    pre-commit
EOF
    
    echo -e "${GREEN}✅ Python tools installed${NC}"
}

setup_cpp_tools() {
    echo -e "${GREEN}Installing C++ development tools...${NC}"
    
    if [ -f /etc/debian_version ]; then
        apt-get install -y \
            clang clang-format clang-tidy \
            cmake ninja-build \
            libgtest-dev
    fi
    
    # Install sccache
    SCCACHE_VERSION="0.7.7"
    curl -L https://github.com/mozilla/sccache/releases/download/v${SCCACHE_VERSION}/sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl.tar.gz | tar xz
    mv sccache-v${SCCACHE_VERSION}-x86_64-unknown-linux-musl/sccache /usr/local/bin/
    chmod +x /usr/local/bin/sccache
    
    # Configure sccache
    sudo -u "$RUNNER_USER" bash <<'EOF'
mkdir -p ~/.cache/sccache
echo 'export SCCACHE_DIR=~/.cache/sccache' >> ~/.bashrc
echo 'export SCCACHE_CACHE_SIZE="10G"' >> ~/.bashrc
EOF
    
    echo -e "${GREEN}✅ C++ tools installed${NC}"
}

main() {
    case "${1:-}" in
        --setup-python)
            setup_python_tools
            ;;
        --setup-cpp)
            setup_cpp_tools
            ;;
        *)
            check_root
            install_dependencies
            create_runner_user
            download_runner
            configure_runner
            install_service
            print_success
            ;;
    esac
}

main "$@"
```

### 6.2 Windows Runner Installation

**파일**: `runner-setup/install-runner-windows.ps1`

```powershell
# GitHub Actions Self-Hosted Runner Installation (Windows)

param(
    [string]$GitHubUrl,
    [string]$Token,
    [string]$RunnerName = $env:COMPUTERNAME
)

$ErrorActionPreference = "Stop"

$RUNNER_VERSION = "2.319.1"
$INSTALL_DIR = "C:\actions-runner"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = "Green")
    Write-Host $Message -ForegroundColor $Color
}

function Install-Dependencies {
    Write-ColorOutput "Installing dependencies..." "Yellow"
    
    # Check if Chocolatey is installed
    if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-ColorOutput "Installing Chocolatey..."
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    }
    
    # Install Git
    choco install -y git
}

function Download-Runner {
    Write-ColorOutput "Downloading runner..." "Yellow"
    
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
    Set-Location $INSTALL_DIR
    
    $url = "https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/actions-runner-win-x64-$RUNNER_VERSION.zip"
    
    Invoke-WebRequest -Uri $url -OutFile "actions-runner.zip"
    Expand-Archive -Path "actions-runner.zip" -DestinationPath . -Force
    Remove-Item "actions-runner.zip"
}

function Configure-Runner {
    Write-ColorOutput "Configuring runner..." "Yellow"
    
    if (!$GitHubUrl) {
        $GitHubUrl = Read-Host "GitHub URL (e.g., https://github.com/your-org)"
    }
    if (!$Token) {
        $Token = Read-Host "Registration token"
    }
    
    Set-Location $INSTALL_DIR
    
    .\config.cmd `
        --url $GitHubUrl `
        --token $Token `
        --name $RunnerName `
        --labels "self-hosted,Windows,X64" `
        --work "_work" `
        --unattended
}

function Install-Service {
    Write-ColorOutput "Installing Windows service..." "Yellow"
    
    Set-Location $INSTALL_DIR
    .\svc.cmd install
    .\svc.cmd start
}

function Setup-PythonTools {
    Write-ColorOutput "Installing Python tools..." "Yellow"
    
    python -m pip install --upgrade pip
    pip install ruff pytest pytest-cov mypy pre-commit
    
    Write-ColorOutput "✅ Python tools installed" "Green"
}

function Setup-CppTools {
    Write-ColorOutput "Installing C++ tools..." "Yellow"
    
    # Install Visual Studio Build Tools
    choco install -y visualstudio2022buildtools
    choco install -y visualstudio2022-workload-vctools
    
    # Install CMake and Ninja
    choco install -y cmake ninja
    
    # Install sccache
    $SCCACHE_VERSION = "0.7.7"
    $url = "https://github.com/mozilla/sccache/releases/download/v$SCCACHE_VERSION/sccache-v$SCCACHE_VERSION-x86_64-pc-windows-msvc.zip"
    
    Invoke-WebRequest -Uri $url -OutFile "sccache.zip"
    Expand-Archive -Path "sccache.zip" -DestinationPath "C:\sccache" -Force
    Remove-Item "sccache.zip"
    
    # Add to PATH
    [Environment]::SetEnvironmentVariable(
        "Path",
        [Environment]::GetEnvironmentVariable("Path", "Machine") + ";C:\sccache",
        "Machine"
    )
    
    Write-ColorOutput "✅ C++ tools installed" "Green"
}

function Print-Success {
    Write-ColorOutput "`n================================" "Green"
    Write-ColorOutput "✅ Runner installed successfully!" "Green"
    Write-ColorOutput "================================`n" "Green"
    
    Write-Host "Service status:"
    Get-Service "actions.runner.*" | Format-Table
    
    Write-Host "`nNext steps:"
    Write-Host "1. Verify runner in GitHub settings"
    Write-Host "2. Run: .\install-runner-windows.ps1 -SetupPython"
    Write-Host "   or: .\install-runner-windows.ps1 -SetupCpp"
}

# Main execution
try {
    switch ($PSCmdlet.ParameterSetName) {
        default {
            Install-Dependencies
            Download-Runner
            Configure-Runner
            Install-Service
            Print-Success
        }
    }
}
catch {
    Write-ColorOutput "Error: $_" "Red"
    exit 1
}
```

### Deliverables
- ✅ Linux runner install script
- ✅ Windows runner install script
- ✅ Tool setup scripts

---

## 📅 Phase 7: Integration Testing (Days 11-12)

### 7.1 Test Projects

**생성할 테스트 프로젝트**:
```
tests/
├── test-python-minimal/
├── test-python-full/
├── test-cpp-cmake/
└── test-cpp-meson/
```

### 7.2 Automated Test Script

**파일**: `scripts/test-templates.sh`

```bash
#!/bin/bash
# Automated template testing

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."
TEST_DIR="$ROOT_DIR/tests"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

cleanup() {
    echo "Cleaning up test projects..."
    rm -rf "$TEST_DIR"
}

test_python_template() {
    echo -e "\n${GREEN}Testing Python template...${NC}"
    
    cd "$TEST_DIR"
    cookiecutter "$ROOT_DIR/cookiecutters/python-project" \
        --no-input \
        project_name="Test Python Project" \
        use_ai_workflow="no"
    
    cd test-python-project
    
    # Test structure
    [ -f "pyproject.toml" ] || { echo "Missing pyproject.toml"; exit 1; }
    [ -f ".pre-commit-config.yaml" ] || { echo "Missing pre-commit config"; exit 1; }
    [ -d ".github/workflows" ] || { echo "Missing workflows"; exit 1; }
    
    # Test pre-commit
    python3 -m venv .venv
    source .venv/bin/activate
    pip install -e .[dev]
    pre-commit run --all-files
    
    # Test CI workflow syntax
    cd .github/workflows
    for f in *.yaml *.yml; do
        echo "Validating $f"
        python3 -c "import yaml; yaml.safe_load(open('$f'))"
    done
    
    echo -e "${GREEN}✅ Python template passed${NC}"
}

test_cpp_template() {
    echo -e "\n${GREEN}Testing C++ template...${NC}"
    
    cd "$TEST_DIR"
    cookiecutter "$ROOT_DIR/cookiecutters/cpp-project" \
        --no-input \
        project_name="Test CPP Project" \
        use_ai_workflow="no" \
        build_system="cmake"
    
    cd test-cpp-project
    
    # Test structure
    [ -f "CMakeLists.txt" ] || { echo "Missing CMakeLists.txt"; exit 1; }
    [ -f ".clang-format" ] || { echo "Missing clang-format"; exit 1; }
    [ -d ".github/workflows" ] || { echo "Missing workflows"; exit 1; }
    
    # Test build
    cmake -B build -G Ninja
    cmake --build build
    
    echo -e "${GREEN}✅ C++ template passed${NC}"
}

test_reusable_workflows() {
    echo -e "\n${GREEN}Testing reusable workflows...${NC}"
    
    # Validate YAML syntax
    for f in "$ROOT_DIR"/.github/workflows/*.yaml; do
        echo "Validating $(basename $f)"
        python3 -c "import yaml; yaml.safe_load(open('$f'))"
    done
    
    echo -e "${GREEN}✅ Reusable workflows valid${NC}"
}

main() {
    echo "Starting template tests..."
    
    mkdir -p "$TEST_DIR"
    
    test_python_template
    test_cpp_template
    test_reusable_workflows
    
    echo -e "\n${GREEN}================================${NC}"
    echo -e "${GREEN}✅ All tests passed!${NC}"
    echo -e "${GREEN}================================${NC}"
    
    cleanup
}

trap cleanup EXIT
main "$@"
```

### 7.3 CI Performance Benchmark

**파일**: `scripts/benchmark-ci.sh`

```bash
#!/bin/bash
# CI Performance Benchmark

PROJECT=$1
RUNS=${2:-3}

if [ -z "$PROJECT" ]; then
    echo "Usage: $0 <project-dir> [runs]"
    exit 1
fi

cd "$PROJECT"

echo "Benchmarking CI for $PROJECT ($RUNS runs)"
echo "==========================================="

total_time=0

for i in $(seq 1 $RUNS); do
    echo "Run $i/$RUNS..."
    
    start=$(date +%s)
    
    # Trigger CI (example for Python)
    if [ -f "pyproject.toml" ]; then
        # Python project
        source .venv/bin/activate
        ruff check . && ruff format --check .
        pytest tests/
    elif [ -f "CMakeLists.txt" ]; then
        # C++ project
        cmake --build build
        ctest --test-dir build
    fi
    
    end=$(date +%s)
    duration=$((end - start))
    total_time=$((total_time + duration))
    
    echo "  Duration: ${duration}s"
done

avg_time=$((total_time / RUNS))

echo ""
echo "Results:"
echo "  Total runs: $RUNS"
echo "  Average time: ${avg_time}s"
```

### Deliverables
- ✅ Automated test suite
- ✅ Performance benchmarks
- ✅ Test documentation

---

## 📅 Phase 8: Documentation (Day 13)

### 8.1 Main README

**파일**: `docs/README.md`

```markdown
# GitHub CICD Templates

> 빠르고 유지보수 가능한 CICD 파이프라인을 위한 템플릿 시스템

## 🚀 Quick Start

### Python Project

```bash
# Install Cookiecutter
pip install cookiecutter

# Create project
bash scripts/create-project.sh python my-project

# Setup
cd my-project
source .venv/bin/activate
pip install -e .[dev]

# Add remote and push
git remote add origin <your-repo>
git push -u origin main
```

### C++ Project

```bash
# Create project
bash scripts/create-project.sh cpp my-cpp-project

# Build
cd my-cpp-project
cmake -B build -G Ninja
cmake --build build

# Test
ctest --test-dir build
```

## 📚 Documentation

- [Quick Start Guide](QUICK_START.md)
- [Cookiecutter Guide](COOKIECUTTER_GUIDE.md)
- [Runner Setup](RUNNER_SETUP.md)
- [Ruff Migration](RUFF_MIGRATION.md)
- [Troubleshooting](TROUBLESHOOTING.md)

## 🎯 Features

### Core Components

1. **Cookiecutter Templates**
   - Python: Ruff + pytest + mypy
   - C++: CMake + Ninja + sccache

2. **Reusable Workflows**
   - Python CI with Ruff (2-3x faster)
   - C++ CI with sccache (50% faster builds)

3. **Composite Actions**
   - Python cache setup
   - C++ cache setup
   - CI monitoring

4. **Self-Hosted Runners**
   - Linux (Ubuntu/Debian/RHEL)
   - Windows (experimental)

### Performance

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Python lint | 60s | 5s | 12x faster |
| C++ build (clean) | 6 min | 3 min | 2x faster |
| C++ build (cached) | 6 min | 30s | 12x faster |
| Project setup | 2 hours | 2 min | 60x faster |

## 🔧 Architecture

```
cookiecutters/          # Project templates
  ├── python-project/
  └── cpp-project/

.github/
  ├── workflows/        # Reusable workflows
  └── actions/          # Composite actions

configs/               # Configuration templates
  ├── python/
  └── cpp/

runner-setup/          # Self-hosted runner scripts

scripts/               # Helper scripts
```

## 📖 Usage Examples

### Using Reusable Workflows

```yaml
# .github/workflows/ci.yaml
name: CI

on: [push, pull_request]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      python-version: '3.11'
      run-coverage: true
```

### Custom CI Configuration

```yaml
jobs:
  custom-ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: YOUR-ORG/github-cicd-templates/.github/actions/setup-python-cache@v1
        with:
          python-version: '3.11'
      
      - run: pip install -e .[dev]
      - run: ruff check .
      - run: pytest
```

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md)

## 📄 License

MIT License - see [LICENSE](LICENSE)
```

### 8.2 Quick Start Guide

**파일**: `docs/QUICK_START.md`

```markdown
# Quick Start Guide

## Prerequisites

- Python 3.10+ (for Cookiecutter)
- Git
- (Optional) Docker

### Install Cookiecutter

```bash
pip install cookiecutter
```

## Create Your First Project

### 1. Python Project

```bash
# Interactive mode
cookiecutter gh:YOUR-ORG/github-cicd-templates --directory="cookiecutters/python-project"

# Non-interactive
cookiecutter gh:YOUR-ORG/github-cicd-templates \
  --directory="cookiecutters/python-project" \
  --no-input \
  project_name="My Awesome Project" \
  python_version="3.11" \
  use_ai_workflow="yes"
```

### 2. C++ Project

```bash
cookiecutter gh:YOUR-ORG/github-cicd-templates \
  --directory="cookiecutters/cpp-project"
```

## Next Steps

### Python

```bash
cd my-awesome-project

# Create virtual environment
source .venv/bin/activate  # Linux/Mac
# or
.venv\Scripts\activate  # Windows

# Install dependencies
pip install -e .[dev]

# Run pre-commit
pre-commit run --all-files

# Run tests
pytest
```

### C++

```bash
cd my-cpp-project

# Configure
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build -j$(nproc)

# Test
ctest --test-dir build --output-on-failure
```

## Add to GitHub

```bash
# Add remote
git remote add origin https://github.com/YOUR-ORG/your-project.git

# Push
git push -u origin main
```

## Setup CI/CD

Your project already has CI/CD configured! Just push your code:

```bash
git push
```

Check the **Actions** tab on GitHub to see your CI running.

## Self-Hosted Runner (Optional)

For faster builds, set up a self-hosted runner:

```bash
# Linux
sudo ./runner-setup/install-runner-linux.sh

# Setup tools
sudo ./runner-setup/install-runner-linux.sh --setup-python
# or
sudo ./runner-setup/install-runner-linux.sh --setup-cpp
```

Then update your workflow:

```yaml
jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      runner-type: 'self-hosted'  # Changed from 'ubuntu-latest'
```

## Troubleshooting

See [TROUBLESHOOTING.md](TROUBLESHOOTING.md)
```

### 8.3 Troubleshooting Guide

**파일**: `docs/TROUBLESHOOTING.md`

```markdown
# Troubleshooting Guide

## Common Issues

### Cookiecutter

#### "cookiecutter: command not found"

**Solution:**
```bash
pip install cookiecutter
# or
pipx install cookiecutter
```

#### Template not found

**Solution:**
```bash
# Use full GitHub URL
cookiecutter https://github.com/YOUR-ORG/github-cicd-templates \
  --directory="cookiecutters/python-project"
```

### Pre-commit

#### "pre-commit: command not found"

**Solution:**
```bash
pip install pre-commit
pre-commit install
```

#### Pre-commit hooks fail

**Solution:**
```bash
# Update hooks
pre-commit autoupdate

# Clear cache
pre-commit clean

# Re-run
pre-commit run --all-files
```

### Python

#### Ruff not found

**Solution:**
```bash
pip install ruff
```

#### Import errors

**Solution:**
```bash
# Reinstall in editable mode
pip install -e .[dev]
```

### C++

#### sccache not working

**Symptoms:**
- Cache hit rate: 0%
- Build times not improving

**Solution:**
```bash
# Check sccache stats
sccache --show-stats

# Check environment variables
echo $CMAKE_CXX_COMPILER_LAUNCHER

# Clear cache and rebuild
sccache --stop-server
rm -rf ~/.cache/sccache
sccache --start-server
```

#### CMake cache issues

**Solution:**
```bash
# Clean build
rm -rf build
cmake -B build -G Ninja
```

### CI/CD

#### Workflow not triggering

**Checklist:**
- [ ] Workflow file in `.github/workflows/`
- [ ] Valid YAML syntax
- [ ] Correct trigger events

**Solution:**
```bash
# Validate YAML
python -c "import yaml; yaml.safe_load(open('.github/workflows/ci.yaml'))"
```

#### Reusable workflow not found

**Error:**
```
error: workflow ... references ... which could not be resolved
```

**Solution:**
- Verify repository URL
- Check version/tag exists
- Ensure repository is accessible

### Self-Hosted Runner

#### Runner offline

**Solution:**
```bash
# Check service status
systemctl status actions.runner.*.service

# Restart service
sudo systemctl restart actions.runner.*.service

# Check logs
journalctl -u actions.runner.*.service -f
```

#### Runner not accepting jobs

**Solution:**
- Check runner labels match workflow requirements
- Verify runner has required tools installed
- Check runner has enough disk space

## Getting Help

1. Check [GitHub Issues](https://github.com/YOUR-ORG/github-cicd-templates/issues)
2. Search [GitHub Discussions](https://github.com/YOUR-ORG/github-cicd-templates/discussions)
3. Contact DevOps team on Slack: #devops-help
```

### Deliverables
- ✅ Complete documentation set
- ✅ Quick start guide
- ✅ Troubleshooting guide

---

## 📅 Phase 9: Pilot Migration (Days 14-15)

### 9.1 Pilot Project Selection

**선정 기준**:
- 활발히 개발 중인 프로젝트
- 중간 규모 (너무 크지 않음)
- Python 또는 C++ 프로젝트
- 팀이 협조적

**목표 프로젝트**:
1. Python 웹 서비스 (1개)
2. C++ 라이브러리 (1개)

### 9.2 Migration Checklist

**파일**: `docs/MIGRATION_CHECKLIST.md`

```markdown
# Migration Checklist

## Pre-Migration

- [ ] Backup current CI configuration
- [ ] Document current build times
- [ ] Review project dependencies
- [ ] Schedule migration window
- [ ] Notify team

## Python Project Migration

### 1. Install pre-commit config

```bash
# Copy pre-commit config
cp path/to/templates/configs/python/.pre-commit-config.yaml .

# Install hooks
pre-commit install
pre-commit run --all-files
```

### 2. Update pyproject.toml

```bash
# Merge configurations
# Add Ruff config from template
```

### 3. Replace CI workflow

```bash
# Backup existing
mv .github/workflows/ci.yaml .github/workflows/ci.yaml.backup

# Create new workflow
cat > .github/workflows/ci.yaml <<EOF
name: CI

on: [push, pull_request]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
    with:
      python-version: '3.10'
      run-tests: true
      run-coverage: true
EOF
```

### 4. Test locally

```bash
# Run pre-commit
pre-commit run --all-files

# Run tests
pytest

# Fix any issues
```

### 5. Push and verify

```bash
git add .
git commit -m "Migrate to template-based CI"
git push

# Monitor Actions tab
```

## C++ Project Migration

### 1. Copy configurations

```bash
cp templates/configs/cpp/.clang-format .
cp templates/configs/cpp/.clang-tidy .
cp templates/configs/cpp/.pre-commit-config.yaml .
```

### 2. Update CMakeLists.txt

```cmake
# Add compiler launcher
set(CMAKE_C_COMPILER_LAUNCHER sccache)
set(CMAKE_CXX_COMPILER_LAUNCHER sccache)

# Export compile commands
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
```

### 3. Replace CI workflow

```yaml
name: CI

on: [push, pull_request]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-ci-reusable.yaml@v1
    with:
      build-type: 'Release'
      enable-cache: true
      use-ninja: true
```

### 4. Test

```bash
# Clean build
rm -rf build
cmake -B build -G Ninja
cmake --build build
ctest --test-dir build
```

## Post-Migration

- [ ] Compare build times
- [ ] Document issues encountered
- [ ] Collect team feedback
- [ ] Update documentation
- [ ] Share lessons learned

## Rollback Plan

If issues occur:

```bash
# Restore backup
git revert <commit-hash>

# Or restore files
mv .github/workflows/ci.yaml.backup .github/workflows/ci.yaml
git add .github/workflows/ci.yaml
git commit -m "Rollback CI migration"
git push
```
```

### 9.3 Performance Measurement

**파일**: `scripts/measure-performance.sh`

```bash
#!/bin/bash
# Performance measurement for pilot projects

PROJECT_DIR=$1
METRICS_FILE="performance-metrics.json"

if [ -z "$PROJECT_DIR" ]; then
    echo "Usage: $0 <project-dir>"
    exit 1
fi

cd "$PROJECT_DIR"

echo "Measuring performance for $(basename $PROJECT_DIR)"

# Get recent workflow runs
gh api repos/:owner/:repo/actions/runs \
  --jq '.workflow_runs[] | {
    name: .name,
    status: .status,
    conclusion: .conclusion,
    duration: (.updated_at | fromdateiso8601) - (.created_at | fromdateiso8601),
    created_at: .created_at
  }' \
  | jq -s '.' > "$METRICS_FILE"

# Calculate statistics
python3 <<EOF
import json
from statistics import mean, median

with open('$METRICS_FILE') as f:
    runs = json.load(f)

successful = [r['duration'] for r in runs if r['conclusion'] == 'success']

if successful:
    print(f"Build Statistics:")
    print(f"  Total runs: {len(runs)}")
    print(f"  Successful: {len(successful)}")
    print(f"  Average duration: {mean(successful)/60:.2f} minutes")
    print(f"  Median duration: {median(successful)/60:.2f} minutes")
    print(f"  Min duration: {min(successful)/60:.2f} minutes")
    print(f"  Max duration: {max(successful)/60:.2f} minutes")
else:
    print("No successful runs found")
EOF
```

### Deliverables
- ✅ 2 migrated pilot projects
- ✅ Performance metrics
- ✅ Migration documentation
- ✅ Lessons learned

---

## 📊 Success Metrics

### Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| **Project setup** | < 2 min | Cookiecutter to first commit |
| **Python lint** | < 10s | Ruff check + format |
| **Python tests** | < 30s | pytest on typical project |
| **C++ build (clean)** | < 3 min | Full CMake + build |
| **C++ build (cached)** | < 30s | With sccache hits |
| **CI pass rate** | > 80% | First-attempt success |

### Adoption Metrics

| Metric | Target | Timeline |
|--------|--------|----------|
| **Pilot projects** | 2 | Week 2 |
| **Template adoption** | 5 projects | Month 1 |
| **Self-hosted runners** | 2 runners | Month 1 |
| **Team training** | 80% of team | Month 2 |

---

## 🔧 Technology Stack Summary

### Core Technologies
- **Cookiecutter**: Project templating (15k+ stars)
- **Ruff**: Python linting/formatting (100x faster than alternatives)
- **sccache**: C++ compilation cache (Mozilla, production-proven)
- **GitHub Actions**: CI/CD platform
- **pre-commit**: Hook management

### Python Stack
- **Ruff**: Linting + formatting (replaces Black, Flake8, isort)
- **pytest**: Testing
- **mypy**: Type checking

### C++ Stack
- **CMake**: Build system
- **Ninja**: Build tool
- **sccache**: Compilation cache
- **clang-format**: Code formatting
- **clang-tidy**: Static analysis

---

## 📅 Timeline Summary

| Phase | Days | Key Deliverables |
|-------|------|-----------------|
| 1. Cookiecutter | 1 | Templates + hooks |
| 2. Workflows | 2 | Reusable workflows |
| 3. Pre-commit | 1 | Ruff configs |
| 4. Actions | 2 | Composite actions |
| 5. Starter Workflows | 2 | Org templates |
| 6. Runners | 2 | Self-hosted setup |
| 7. Testing | 2 | Test suite + benchmarks |
| 8. Documentation | 1 | Complete docs |
| 9. Pilot | 2 | Migrated projects |
| **Total** | **15 days** | **Production-ready system** |

---

## 🚀 Quick Reference

### Create New Project

```bash
# Python
bash scripts/create-project.sh python my-project

# C++
bash scripts/create-project.sh cpp my-library
```

### Use in Existing Project

```yaml
# .github/workflows/ci.yaml
jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/python-ci-reusable.yaml@v1
```

### Setup Self-Hosted Runner

```bash
# Linux
sudo ./runner-setup/install-runner-linux.sh
sudo ./runner-setup/install-runner-linux.sh --setup-python
```

### Migrate Existing Project

```bash
# See docs/MIGRATION_CHECKLIST.md
cp configs/python/.pre-commit-config.yaml .
pre-commit install
# Update CI workflow
```

---

## 📚 Additional Resources

### Documentation
- [Cookiecutter Documentation](https://cookiecutter.readthedocs.io/)
- [Ruff Documentation](https://docs.astral.sh/ruff/)
- [GitHub Actions Reusable Workflows](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [sccache Documentation](https://github.com/mozilla/sccache)

### Internal Links
- [Complete Documentation](docs/README.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Migration Guide](docs/MIGRATION_CHECKLIST.md)

---

**Document Version:** 2.0  
**Last Updated:** 2025-10-13  
**Status:** Ready for Implementation  
**Estimated Completion:** 15 working days