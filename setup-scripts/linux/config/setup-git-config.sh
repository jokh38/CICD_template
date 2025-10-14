#!/bin/bash
# Git Configuration and Initialization Setup

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

RUNNER_USER="github-runner"
GIT_USER_NAME="Kwanghyun Jo"
GIT_USER_EMAIL="jokh38@gmail.com"

check_root() {
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}Please run as root${NC}"
        exit 1
    fi
}

configure_git_user() {
    echo -e "${GREEN}Configuring git user for $RUNNER_USER...${NC}"

    sudo -u "$RUNNER_USER" bash <<EOF
    # Configure git user
    git config --global user.name "$GIT_USER_NAME"
    git config --global user.email "$GIT_USER_EMAIL"

    # Verify configuration
    echo "Git user configuration:"
    git config --global user.name
    git config --global user.email

    # Configure useful git defaults
    git config --global init.defaultBranch "main"
    git config --global pull.rebase "false"
    git config --global core.autocrlf "input"
    git config --global core.preloadindex "true"
    git config --global core.fscache "true"
    git config --global gc.auto "256"

    # Configure editor (use nano if available, otherwise vi)
    if command -v nano &> /dev/null; then
        git config --global core.editor "nano"
    else
        git config --global core.editor "vi"
    fi

    echo "Git configuration completed for $RUNNER_USER"
EOF

    echo -e "${GREEN}✅ Git user configuration completed${NC}"
}

setup_git_aliases() {
    echo -e "${GREEN}Setting up git aliases for $RUNNER_USER...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Set up useful git aliases
    git config --global alias.st "status"
    git config --global alias.co "checkout"
    git config --global alias.br "branch"
    git config --global alias.cm "commit -m"
    git config --global alias.ca "commit --amend"
    git config --global alias.cam "commit --amend -m"
    git config --global alias.cp "cherry-pick"
    git config --global alias.fp "fetch --prune"
    git config --global alias.gr "graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"
    git config --global alias.last "log -1 HEAD"
    git config --global alias.unstage "reset HEAD --"
    git config --global alias.lg "log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --"
    git config --global alias.tree "log --graph --pretty=oneline --abbrev-commit --all --decorate"
    git config --global alias.logs "log --show-signature --stat --graph"
    git config --global alias.diffstat "diff --stat"
    git config --global alias.diffstaged "diff --staged --stat"

    echo "Git aliases configured"
EOF

    echo -e "${GREEN}✅ Git aliases configured${NC}"
}

setup_git_credentials_helper() {
    echo -e "${GREEN}Setting up git credentials helper...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Configure credentials helper (for potential future use)
    git config --global credential.helper "cache --timeout=3600"

    # Configure safe directory (important for security)
    git config --global --add safe.directory "$(pwd)"
    git config --global --add safe.directory "/home/$RUNNER_USER"

    echo "Git credentials helper configured"
EOF

    echo -e "${GREEN}✅ Git credentials helper configured${NC}"
}

create_gitignore_global() {
    echo -e "${GREEN}Creating global .gitignore for $RUNNER_USER...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Create global .gitignore
    cat > ~/.gitignore_global << 'GITIGNORE_GLOBAL'
# Common development ignores
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# IDE and editor files
.vscode/
.idea/
*.swp
*.swo
*~
.project
.classpath
.c9/
*.launch
.settings/
*.sublime-project
*.sublime-workspace

# Build directories
build/
cmake-build-*/
dist/
target/
bin/
out/

# Dependency directories
node_modules/
.pnp
.pnp.js

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
venv/
.venv/
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
.mypy_cache/
.pytest_cache/
.coverage
htmlcov/

# Temporary files
*.tmp
*.temp
*.log
*.pid
*.seed
*.pid.lock

# Cache directories
.cache/
.sass-cache/
.parcel-cache/

# Backup files
*.bak
*.backup
*.orig
*.rej

# OS generated files
.DS_Store?
ehthumbs.db
Icon?
Thumbs.db
GITIGNORE_GLOBAL

    # Configure git to use global gitignore
    git config --global core.excludesfile ~/.gitignore_global

    echo "Global .gitignore created and configured"
EOF

    echo -e "${GREEN}✅ Global .gitignore created${NC}"
}

create_git_template() {
    echo -e "${GREEN}Creating git commit message template...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Create commit message template
    mkdir -p ~/.config/git
    cat > ~/.config/git/commit.template << 'COMMIT_TEMPLATE'
# <type>(<scope>): <subject>
#
# <body>
#
# <footer>
#
# Types: feat, fix, docs, style, refactor, test, chore
# Subject: Imperative mood, short description (50 chars or less)
# Body: Detailed explanation of what and why, not how
# Footer: References to issues, breaking changes, etc.
#
# Examples:
# feat(ci): add automated testing for new pipeline
# fix(parser): handle null input gracefully
# docs(readme): update installation instructions
COMMIT_TEMPLATE

    # Configure git to use commit template
    git config --global commit.template ~/.config/git/commit.template

    echo "Git commit template created"
EOF

    echo -e "${GREEN}✅ Git commit template created${NC}"
}

setup_git_hooks_directory() {
    echo -e "${GREEN}Setting up git hooks directory...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    # Create global git hooks directory
    mkdir -p ~/.git-hooks

    # Configure git to use global hooks directory
    git config --global core.hooksPath ~/.git/hooks

    # Create sample pre-commit hook
    cat > ~/.git-hooks/pre-commit.sample << 'HOOK_SAMPLE'
#!/bin/bash
# Sample pre-commit hook

echo "Running pre-commit checks..."

# Check for large files
echo "Checking for large files..."
if git diff --cached --name-only | xargs ls -la | awk '$5 > 10485760 {print $9}' | grep .; then
    echo "Error: Found files larger than 10MB. Consider using git-lfs."
    exit 1
fi

# Check for common issues
echo "Checking for common issues..."
if git diff --cached --name-only | grep -E '\.(py|js|ts|cpp|hpp|c|h)$'; then
    echo "Source files detected. Consider running linting/formatting."
fi

echo "Pre-commit checks completed."
HOOK_SAMPLE

    chmod +x ~/.git-hooks/pre-commit.sample

    echo "Git hooks directory configured"
EOF

    echo -e "${GREEN}✅ Git hooks directory configured${NC}"
}

verify_git_configuration() {
    echo -e "${GREEN}Verifying git configuration...${NC}"

    sudo -u "$RUNNER_USER" bash <<'EOF'
    echo "=== Git Configuration Summary ==="
    echo "User: $(git config --global user.name)"
    echo "Email: $(git config --global user.email)"
    echo "Default Branch: $(git config --global init.defaultBranch)"
    echo "Editor: $(git config --global core.editor)"
    echo "Core Excludesfile: $(git config --global core.excludesfile)"
    echo "Commit Template: $(git config --global commit.template)"

    echo ""
    echo "=== Git Aliases ==="
    git config --global --get-regexp '^alias\.' | sort

    echo ""
    echo "=== Configuration Files ==="
    echo "Global .gitignore: $(git config --global core.excludesfile)"
    echo "Commit template: $(git config --global commit.template)"

    echo ""
    echo "✅ Git configuration verified successfully"
EOF

    echo -e "${GREEN}✅ Git configuration verification completed${NC}"
}

main() {
    echo -e "${GREEN}Starting git configuration setup...${NC}"

    check_root
    configure_git_user
    setup_git_aliases
    setup_git_credentials_helper
    create_gitignore_global
    create_git_template
    setup_git_hooks_directory
    verify_git_configuration

    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}✅ Git configuration setup complete!${NC}"
    echo -e "${GREEN}================================${NC}"
    echo ""
    echo "Configured for user: $RUNNER_USER"
    echo "Git user: $GIT_USER_NAME <$GIT_USER_EMAIL>"
    echo ""
    echo "The git configuration includes:"
    echo "  - User name and email"
    echo "  - Useful aliases (st, co, br, cm, lg, etc.)"
    echo "  - Global .gitignore"
    echo "  - Commit message template"
    echo "  - Credentials helper"
    echo "  - Git hooks directory"
    echo ""
    echo "Git is now ready for use by $RUNNER_USER!"
}

main "$@"