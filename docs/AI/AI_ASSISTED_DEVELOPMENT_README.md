# AI-Assisted Development Framework (Compact)

## Overview
Prevents incomplete refactoring, broken imports, cascading fix commits, and documentation lag.

## Four Core Documents

### 1. AI_CONTEXT.md
- **Use when:** Starting any task
- **Contains:** Project structure, dependency graph, config mapping, synchronized files
- **Update when:** Structure changes, new modules, config changes

### 2. MODULE_INTERFACES.md
- **Use when:** Modifying module APIs
- **Contains:** Public functions/classes, dependencies, "Used By" lists, breaking change policy
- **Update when:** API changes, new modules, deprecations

### 3. ARCHITECTURE_INVARIANTS.md
- **Use when:** Before ANY code change
- **Contains:** Non-negotiable rules (no circular deps, no wildcards, validation at boundaries, etc.)
- **Update when:** New anti-patterns discovered

### 4. AI_DEVELOPMENT_GUIDE.md
- **Use when:** Performing any modification
- **Contains:** Step-by-step checklists for rename, add dependency, remove feature, fix bug, etc.
- **Update when:** New common pitfalls found

## Workflow for AI Assistants
```
1. Read AI_CONTEXT.md → Understand structure
2. Check MODULE_INTERFACES.md → Find dependencies
3. Review ARCHITECTURE_INVARIANTS.md → Know forbidden patterns
4. Follow AI_DEVELOPMENT_GUIDE.md → Execute checklist
5. Commit atomically → Code + tests + docs + config together
```

## Success Metrics
- Atomic commits (target: >90%)
- Zero broken builds
- Current documentation
- Single complete commits (no "fix" chains)

## Key Principle
**Every commit must be complete and working.** The extra 10 minutes validating prevents hours of debugging cascading failures.

## For Hook Integration
Use these docs to configure pre-edit (predict impact, warn violations) and post-edit (validate rules, update docs) hooks as defined in hook_subagent.txt.
