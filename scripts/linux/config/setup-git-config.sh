#!/bin/bash
# Setup Git Configuration

set -e

# Source common utilities
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_UTILS="$SCRIPT_DIR/../../lib/common-utils.sh"

if [ -f "$COMMON_UTILS" ]; then
    source "$COMMON_UTILS"
else
    echo "Error: Cannot find common-utils.sh at $COMMON_UTILS"
    exit 1
fi

# Configure git user
print_status "Configuring Git user..."
git config --global user.name "Kwanghyun Jo"
git config --global user.email "jokh38@gmail.com"

# Set default branch name
git config --global init.defaultBranch main

# Configure core settings
git config --global core.autocrlf input
git config --global core.pager "less -FRX"
git config --global core.editor "nano"

# Configure useful aliases
git config --global alias.st status
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.unstage 'reset HEAD --'
git config --global alias.last 'log -1 HEAD'
git config --global alias.visual '!gitk'
git config --global alias.graph 'log --oneline --graph --decorate --all'
git config --global alias.amend 'commit --amend --no-edit'
git config --global alias.fixup 'commit --fixup'
git config --global alias.squash '!git rebase -i --autosquash'

# Configure pull behavior
git config --global pull.rebase true

# Configure push behavior
git config --global push.default simple

# Configure rebase behavior
git config --global rebase.autosquash true
git config --global rebase.autostash true

# Create global gitignore
print_status "Creating global gitignore..."
cat > ~/.gitignore_global << 'EOF'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE files
.vscode/
.idea/
*.swp
*.swo
*~
.project
.pydevproject
.settings/
*.sublime-*

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/
pip-log.txt
pip-delete-this-directory.txt
.tox/
.coverage
.pytest_cache/
htmlcov/
.mypy_cache/
.dmypy.json
dmypy.json

# C++
*.o
*.obj
*.exe
*.dll
*.so
*.dylib
*.a
*.lib
*.pdb
*.ilk
*.exp
*.map
*.dSYM/
*.su
*.idb
*.pdb
*.pgc
*.pgd
*.rsp
*.sbr
*.tlb
*.tli
*.tlh
*.tmp_proj
*.vspscc
*.vssscc
.builds
*.pidb
*.svclog
*.scc

# CMake
CMakeCache.txt
CMakeFiles/
cmake_install.cmake
Makefile
*.cmake
CMake/

# Build directories
build/
Build/
dist/
build-*/

# Package files
*.jar
*.war
*.nar
*.ear
*.zip
*.tar.gz
*.rar

# Logs
logs/
*.log
npm-debug.log*
yarn-debug.log*
yarn-error.log*

# Environment variables
.env
.env.local
.env.development.local
.env.test.local
.env.production.local

# Temporary files
*.tmp
*.temp
EOF

git config --global core.excludesfile ~/.gitignore_global

# Create commit template
print_status "Creating commit template..."
mkdir -p ~/.config/git
cat > ~/.config/git/commit.template << 'EOF'
# Type(scope): subject

# Body: Explain what and why, not how.
#
# Footer:
#   - Breaking changes: BREAKING CHANGE: description
#   - Closes issues: Closes #issue-number
#   - References: References #issue-number

# Types: feat, fix, docs, style, refactor, test, chore
# Scopes: app, lib, docs, build, ci, style, refactor, test, chore
EOF

git config --global commit.template ~/.config/git/commit.template

print_success "Git configuration completed successfully"