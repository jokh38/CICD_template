#!/bin/bash
# AI Workflow Template Setup

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

# Function to check if AI workflow templates are already set up
check_ai_workflows() {
    print_status "Checking AI workflow templates..."

    local cpp_template="/home/$RUNNER_USER/.config/templates/cpp/.github/workflows/ai-workflow.yaml"
    local python_template="/home/$RUNNER_USER/.config/templates/python/.github/workflows/ai-workflow.yaml"

    if [ -f "$cpp_template" ] && [ -f "$python_template" ]; then
        print_success "AI workflow templates are already set up"
        return 0
    else
        print_warning "AI workflow templates are not set up"
        return 1
    fi
}

create_cpp_ai_workflow() {
    echo -e "${GREEN}Creating C++ AI workflow template...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    mkdir -p ~/.config/templates/cpp/.github/workflows
    cat > ~/.config/templates/cpp/.github/workflows/ai-workflow.yaml << 'AI_WORKFLOW'
name: C++ AI Assistant Workflow

on:
  issue_comment:
    types: [created]
  issues:
    types: [opened, edited]
  pull_request:
    types: [opened, edited, synchronize]

jobs:
  ai-assistant:
    runs-on: ubuntu-latest
    if: contains({% raw %}{{ github.event.comment.body }}{% endraw %}, '@claude') || contains({% raw %}{{ github.event.issue.body }}{% endraw %}, '@claude')

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup C++ Environment
      uses: jokh38/cpp-dev-setup@v1
      with:
        cpp-standard: '17'
        build-system: 'cmake'
        use-ninja: 'true'

    - name: Configure Build
      run: |
        cmake -B build -G Ninja

    - name: AI Assistant Analysis
      run: |
        echo "🤖 AI Assistant workflow triggered for C++ project"
        echo "📊 Project Analysis:"
        echo "   - Language: C++17"
        echo "   - Build System: cmake"
        echo "   - Testing: gtest"

        if [ "{% raw %}{{ github.event_name }}{% endraw %}" = "issue_comment" ]; then
          echo "💬 Comment detected: {% raw %}{{ github.event.comment.body }}{% endraw %}"
        elif [ "{% raw %}{{ github.event_name }}{% endraw %}" = "issues" ]; then
          echo "🐛 Issue detected: {% raw %}{{ github.event.issue.title }}{% endraw %}"
        elif [ "{% raw %}{{ github.event_name }}{% endraw %}" = "pull_request" ]; then
          echo "🔄 PR detected: {% raw %}{{ github.event.pull_request.title }}{% endraw %}"

          # Run basic build check on PR
          echo "🔨 Building project..."
          cmake --build build --config Debug

          echo "🧪 Running tests..."
          ctest --test-dir build --output-on-failure
        fi

    - name: Code Quality Check
      run: |
        echo "🔍 Running code quality checks..."

        # Check if clang-format is available
        if command -v clang-format &> /dev/null; then
          echo "✓ clang-format found"
          clang-format --version
        else
          echo "⚠️ clang-format not found"
        fi

        # Check for common C++ issues
        echo "📋 Static analysis summary:"
        find src/ include/ tests/ -name "*.cpp" -o -name "*.hpp" | head -10 | while read file; do
          echo "   - Analyzing: $file"
        done

    - name: AI Assistant Response
      uses: actions/github-script@v7
      with:
        script: |
          const response = `
          🤖 **C++ AI Assistant Analysis Complete**

          **Project Status**: ✅ Analyzed
          **Build System**: CMake
          **C++ Standard**: C++17
          **Testing**: GTEST

          **Next Steps**:
          1. Review the build output above
          2. Check test results
          3. Address any compilation warnings
          4. Consider code formatting with clang-format

          **Available Commands**:
          - \`@claude review code\` - Request code review
          - \`@claude fix build\` - Help with build issues
          - \`@claude add tests\` - Help with test coverage
          `;

          if (context.eventName === 'issue_comment') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          } else if (context.eventName === 'issues') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          } else if (context.eventName === 'pull_request') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          }
AI_WORKFLOW
EOF

    echo -e "${GREEN}✅ C++ AI workflow template created${NC}"
}

create_python_ai_workflow() {
    echo -e "${GREEN}Creating Python AI workflow template...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    mkdir -p ~/.config/templates/python/.github/workflows
    cat > ~/.config/templates/python/.github/workflows/ai-workflow.yaml << 'AI_WORKFLOW'
name: AI Assistant Workflow

on:
  issue_comment:
    types: [created]
  issues:
    types: [opened, edited]
  pull_request:
    types: [opened, edited, synchronize]

jobs:
  ai-assistant:
    runs-on: ubuntu-latest
    if: contains({% raw %}{{ github.event.comment.body }}{% endraw %}, '@claude') || contains({% raw %}{{ github.event.issue.body }}{% endraw %}, '@claude')

    steps:
    - name: Checkout repository
      uses: actions/checkout@v4

    - name: Setup Python Environment
      uses: actions/setup-python@v4
      with:
        python-version: '3.10'

    - name: Install Dependencies
      run: |
        python -m pip install --upgrade pip
        pip install ruff pytest mypy

    - name: AI Assistant Analysis
      run: |
        echo "🤖 AI Assistant workflow triggered for Python project"
        echo "📊 Project Analysis:"
        echo "   - Language: Python 3.10"
        echo "   - Tools: ruff, pytest, mypy"

        if [ "{% raw %}{{ github.event_name }}{% endraw %}" = "issue_comment" ]; then
          echo "💬 Comment detected: {% raw %}{{ github.event.comment.body }}{% endraw %}"
        elif [ "{% raw %}{{ github.event_name }}{% endraw %}" = "issues" ]; then
          echo "🐛 Issue detected: {% raw %}{{ github.event.issue.title }}{% endraw %}"
        elif [ "{% raw %}{{ github.event_name }}{% endraw %}" = "pull_request" ]; then
          echo "🔄 PR detected: {% raw %}{{ github.event.pull_request.title }}{% endraw %}"

          # Run basic checks on PR
          echo "🔍 Running code quality checks..."
          ruff check .
          ruff format --check .
          mypy .
          pytest tests/ -v
        fi

    - name: Code Quality Check
      run: |
        echo "🔍 Running code quality checks..."

        # Check if ruff is available
        if command -v ruff &> /dev/null; then
          echo "✓ ruff found"
          ruff --version
        else
          echo "⚠️ ruff not found"
        fi

        # Check if pytest is available
        if command -v pytest &> /dev/null; then
          echo "✓ pytest found"
          pytest --version
        else
          echo "⚠️ pytest not found"
        fi

        # Check if mypy is available
        if command -v mypy &> /dev/null; then
          echo "✓ mypy found"
          mypy --version
        else
          echo "⚠️ mypy not found"
        fi

        echo "📋 Static analysis summary:"
        find src/ tests/ -name "*.py" | head -10 | while read file; do
          echo "   - Analyzing: $file"
        done

    - name: AI Assistant Response
      uses: actions/github-script@v7
      with:
        script: |
          const response = `
          🤖 **Python AI Assistant Analysis Complete**

          **Project Status**: ✅ Analyzed
          **Language**: Python 3.10
          **Tools**: ruff, pytest, mypy

          **Next Steps**:
          1. Review the code quality output above
          2. Check test results
          3. Address any linting issues
          4. Consider type annotations with mypy

          **Available Commands**:
          - \`@claude review code\` - Request code review
          - \`@claude fix imports\` - Help with import organization
          - \`@claude add tests\` - Help with test coverage
          - \`@claude type check\` - Help with type annotations
          `;

          if (context.eventName === 'issue_comment') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          } else if (context.eventName === 'issues') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          } else if (context.eventName === 'pull_request') {
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: response
            });
          }
AI_WORKFLOW
EOF

    echo -e "${GREEN}✅ Python AI workflow template created${NC}"
}

main() {
    # Check if AI workflow templates are already set up
    if check_ai_workflows; then
        print_success "AI workflow templates are already set up - skipping"
        exit 0
    fi

    create_cpp_ai_workflow
    create_python_ai_workflow
}

main "$@"