# AI_DEVELOPMENT_GUIDE (Compact)

## Core Principle
Every commit must be complete and working. No "fix in next commit" patterns.

## Before ANY Task
1. Read AI_CONTEXT.md, MODULE_INTERFACES.md, ARCHITECTURE_INVARIANTS.md
2. Find ALL affected files: `grep -r "keyword" src/`
3. Check dependencies, config, docs

## Task Checklists

### Renaming Module/Function
- [ ] Find ALL imports: `grep -r "old_name" .`
- [ ] Update: code, tests, config, docs together
- [ ] Verify: No old name remains
- [ ] Commit atomically with complete changeset

### Adding Dependency
- [ ] Add to requirements.txt with version
- [ ] Wrap in adapter layer (INV-DR-004)
- [ ] Update docs with installation instructions
- [ ] Test clean install: `pip3 install -r requirements.txt`

### Removing Feature
- [ ] List ALL files using feature
- [ ] Remove: code, imports, config, API endpoints, docs, tests, dependencies
- [ ] Create migration guide if breaking change
- [ ] Verify: `grep -ri "feature_name" .` returns nothing

### Fixing Bug
- [ ] Write failing test first
- [ ] Fix bug (test passes)
- [ ] Search for similar patterns elsewhere
- [ ] Consider architectural prevention rule

## General Validation (Before Commit)
```bash
python3 -m py_compile src/*.py    # Syntax check
python3 -c "from src import *"    # Import check
python3 -m pytest                  # Run tests
grep -r "old_name" .               # Reference check
```

## Atomic Commit Rule
Single commit = code + tests + docs + config all updated together.

**Remember:** Extra 10 minutes validating prevents hours of debugging.
