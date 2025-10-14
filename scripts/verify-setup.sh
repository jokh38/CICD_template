#!/bin/bash
# Verify CICD template system setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

ERRORS=0
WARNINGS=0

log_check() {
    echo -e "${BLUE}[CHECK]${NC} $1"
}

log_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((WARNINGS++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((ERRORS++))
}

check_file() {
    local file=$1
    local desc=$2

    if [ -f "$ROOT_DIR/$file" ]; then
        log_ok "$desc exists"
    else
        log_error "$desc missing: $file"
    fi
}

check_dir() {
    local dir=$1
    local desc=$2

    if [ -d "$ROOT_DIR/$dir" ]; then
        log_ok "$desc exists"
    else
        log_error "$desc missing: $dir"
    fi
}

check_executable() {
    local file=$1
    local desc=$2

    if [ -f "$ROOT_DIR/$file" ] && [ -x "$ROOT_DIR/$file" ]; then
        log_ok "$desc is executable"
    else
        log_warning "$desc not executable: $file"
    fi
}

echo "=========================================="
echo "CICD Template System Verification"
echo "=========================================="
echo ""

# Phase 1: Cookiecutter Templates
log_check "Phase 1: Cookiecutter Templates"
check_file "cookiecutters/python-project/cookiecutter.json" "Python template config"
check_file "cookiecutters/python-project/hooks/post_gen_project.py" "Python post-gen hook"
check_dir "cookiecutters/python-project/{{cookiecutter.project_slug}}" "Python template structure"
check_file "cookiecutters/cpp-project/cookiecutter.json" "C++ template config"
check_file "cookiecutters/cpp-project/hooks/post_gen_project.py" "C++ post-gen hook"
check_dir "cookiecutters/cpp-project/{{cookiecutter.project_slug}}" "C++ template structure"
check_executable "cookiecutters/python-project/hooks/post_gen_project.py" "Python hook"
check_executable "cookiecutters/cpp-project/hooks/post_gen_project.py" "C++ hook"
echo ""

# Phase 2: Reusable Workflows
log_check "Phase 2: Reusable Workflows"
check_file ".github/workflows/python-ci-reusable.yaml" "Python reusable workflow"
check_file ".github/workflows/cpp-ci-reusable.yaml" "C++ reusable workflow"
echo ""

# Phase 3: Configuration Templates
log_check "Phase 3: Configuration Templates"
check_file "configs/python/.pre-commit-config.yaml" "Python pre-commit config"
check_file "configs/python/ruff.toml" "Ruff configuration"
check_file "configs/python/pyproject.toml.template" "Python project template"
check_file "configs/cpp/.pre-commit-config.yaml" "C++ pre-commit config"
check_file "configs/cpp/.clang-format" "clang-format config"
check_file "configs/cpp/.clang-tidy" "clang-tidy config"
check_file "configs/cpp/CMakeLists.txt.template" "CMake template"
echo ""

# Phase 4: Composite Actions
log_check "Phase 4: Composite Actions"
check_file ".github/actions/setup-python-cache/action.yaml" "Python cache action"
check_file ".github/actions/setup-cpp-cache/action.yaml" "C++ cache action"
check_file ".github/actions/monitor-ci/action.yaml" "CI monitor action"
echo ""

# Phase 5: Starter Workflows and Scripts
log_check "Phase 5: Starter Workflows and Scripts"
check_file ".github/workflow-templates/python-ci.yml" "Python starter workflow"
check_file ".github/workflow-templates/python-ci.properties.json" "Python workflow metadata"
check_file ".github/workflow-templates/cpp-ci.yml" "C++ starter workflow"
check_file ".github/workflow-templates/cpp-ci.properties.json" "C++ workflow metadata"
check_file "scripts/create-project.sh" "Project creation script"
check_file "scripts/sync-templates.sh" "Template sync script"
check_file "scripts/lib/common-utils.sh" "Common utilities"
check_executable "scripts/create-project.sh" "Create project script"
check_executable "scripts/sync-templates.sh" "Sync templates script"
check_executable "scripts/lib/common-utils.sh" "Common utils script"
echo ""

# Documentation
log_check "Documentation"
check_file "README.md" "Main README"
check_file "0.DEV_PLAN.md" "Development plan"
check_file "IMPLEMENTATION_SUMMARY.md" "Implementation summary"
check_file ".gitignore" "Git ignore file"
echo ""

# Check dependencies
log_check "Checking dependencies"
if command -v cookiecutter &> /dev/null; then
    log_ok "Cookiecutter is installed"
else
    log_warning "Cookiecutter not installed (pip install cookiecutter)"
fi

if command -v git &> /dev/null; then
    log_ok "Git is installed"
else
    log_error "Git not installed"
fi

if command -v python3 &> /dev/null; then
    log_ok "Python 3 is installed"
else
    log_error "Python 3 not installed"
fi
echo ""

# Summary
echo "=========================================="
echo "Verification Summary"
echo "=========================================="
echo ""

if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✅ All checks passed!${NC}"
    echo ""
    echo "The CICD template system is fully set up and ready to use."
    echo ""
    echo "Next steps:"
    echo "  1. Install cookiecutter: pip install cookiecutter"
    echo "  2. Create a project: bash scripts/create-project.sh python my-project"
    echo "  3. Test the templates locally"
    echo ""
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Setup complete with $WARNINGS warning(s)${NC}"
    echo ""
    echo "The system is functional but some optional features may not work."
    exit 0
else
    echo -e "${RED}❌ Setup incomplete: $ERRORS error(s), $WARNINGS warning(s)${NC}"
    echo ""
    echo "Please fix the errors above before using the template system."
    exit 1
fi
