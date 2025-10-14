#!/bin/bash
# Code Formatting Configuration Setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UTILS_DIR="$SCRIPT_DIR/../utils"
RUNNER_USER="github-runner"

# Source utility functions
if [ -f "$UTILS_DIR/check-deps.sh" ]; then
    source "$UTILS_DIR/check-deps.sh"
else
    echo -e "\033[0;31m[ERROR]\033[0m Utility functions not found: $UTILS_DIR/check-deps.sh"
    exit 1
fi

setup_cpp_formatters() {
    echo -e "${GREEN}Setting up C++ code formatting configurations...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Create .clang-format configuration
    cat > ~/.clang-format << 'CLANG_FORMAT'
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
CLANG_FORMAT

    # Create .clang-tidy configuration
    cat > ~/.clang-tidy << 'CLANG_TIDY'
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
CLANG_TIDY

    # Create CMake presets template
    mkdir -p ~/.config/cmake
    cat > ~/.config/cmake/CMakePresets.json << 'CMAKE_PRESETS'
{
  "version": 6,
  "configurePresets": [
    {
      "name": "base",
      "hidden": true,
      "toolchain": {
        "file": "${sourceDir}/cmake/toolchains/default.cmake"
      },
      "cacheVariables": {
        "CMAKE_C_COMPILER_LAUNCHER": "sccache",
        "CMAKE_CXX_COMPILER_LAUNCHER": "sccache",
        "CMAKE_EXPORT_COMPILE_COMMANDS": "ON"
      }
    },
    {
      "name": "debug",
      "inherits": "base",
      "displayName": "Debug",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Debug",
        "CMAKE_DEBUG_POSTFIX": "-d"
      }
    },
    {
      "name": "release",
      "inherits": "base",
      "displayName": "Release",
      "cacheVariables": {
        "CMAKE_BUILD_TYPE": "Release",
        "CMAKE_INTERPROCEDURAL_OPTIMIZATION": "ON"
      }
    }
  ],
  "buildPresets": [
    {
      "name": "debug",
      "configurePreset": "debug",
      "jobs": 4
    },
    {
      "name": "release",
      "configurePreset": "release",
      "jobs": 4
    }
  ],
  "testPresets": [
    {
      "name": "debug",
      "configurePreset": "debug",
      "execution": {
        "noTestsAction": "error",
        "timeout": 300
      }
    },
    {
      "name": "release",
      "configurePreset": "release",
      "execution": {
        "noTestsAction": "error",
        "timeout": 300
      }
    }
  ]
}
CMAKE_PRESETS

    # Add C++ aliases to bashrc
    cat >> ~/.bashrc << 'BASHRC_EOF'

# C++ development aliases
alias cmake-debug='cmake --preset debug'
alias cmake-release='cmake --preset release'
alias build-debug='cmake --build --preset debug'
alias build-release='cmake --build --preset release'
alias test-debug='ctest --preset debug'
alias test-release='ctest --preset release'
alias format-clang='find . -name "*.cpp" -o -name "*.hpp" | xargs clang-format -i'
alias lint-clang='find . -name "*.cpp" -o -name "*.hpp" | xargs clang-tidy'
alias sccache-stats='sccache --show-stats'
alias sccache-zero='sccache --zero-stats'
BASHRC_EOF

    echo "C++ formatting configurations created"
EOF

    echo -e "${GREEN}✅ C++ formatting configurations created${NC}"
}

setup_python_formatters() {
    echo -e "${GREEN}Setting up Python code formatting configurations...${NC}"

    # Create global ruff config
    sudo -u "$RUNNER_USER" bash <<'EOF'
    mkdir -p ~/.config/ruff
    cat > ~/.config/ruff/ruff.toml << 'RUFF_CONFIG'
# Global Ruff configuration
target-version = "py310"
line-length = 88
indent-width = 4

[lint]
# Enable common rules
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
    "S",   # flake8-bandit
]

ignore = [
    "E501",  # line too long (handled by formatter)
    "S101",  # use of assert detected
]

# Allow autofix
fixable = ["ALL"]
unfixable = []

[format]
quote-style = "double"
indent-style = "space"
skip-magic-trailing-comma = false
line-ending = "auto"
RUFF_CONFIG

    # Create global pre-commit config template
    mkdir -p ~/.config/pre-commit
    cat > ~/.config/pre-commit/pre-commit-config.yaml << 'PRECOMMIT_CONFIG'
# Global pre-commit configuration template
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

  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.6.0
    hooks:
      - id: ruff
        args: [--fix, --exit-non-zero-on-fix]
      - id: ruff-format

  - repo: https://github.com/pre-commit/mirrors-mypy
    rev: v1.11.0
    hooks:
      - id: mypy
        additional_dependencies: [types-all]
        args: [--strict, --ignore-missing-imports]
PRECOMMIT_CONFIG

    # Add useful aliases to bashrc
    cat >> ~/.bashrc << 'BASHRC_EOF'

# Python development aliases
alias lint='ruff check . && ruff format --check .'
alias fmt='ruff check . --fix && ruff format .'
alias test='pytest'
alias cov='pytest --cov=src --cov-report=html --cov-report=term'
alias typecheck='mypy .'
alias precommit-run='pre-commit run --all-files'
BASHRC_EOF
EOF

    echo -e "${GREEN}✅ Python formatting configurations created${NC}"
}

main() {
    # Check if code formatting configurations are already set up
    if check_code_formatting; then
        print_success "Code formatting configurations are already set up - skipping"
        exit 0
    fi

    setup_cpp_formatters
    setup_python_formatters
}

main "$@"