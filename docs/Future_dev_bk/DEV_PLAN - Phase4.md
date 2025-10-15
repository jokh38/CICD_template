## Phase 4: Advanced Prompt Engineering (Week 2, Days 5-7)

### Objective
Create sophisticated prompt templates and custom slash commands for common tasks.

### 4.1 Slash Command Templates

**Task**: Develop reusable slash commands for common operations

**Location**: `.github/claude/commands/`

**File**: `fix-ci.md`
```markdown
# /fix-ci - Fix CI/CD Pipeline Failures

You are tasked with analyzing and fixing CI/CD pipeline failures.

## Context
- Review the error log provided
- Understand the type of failure (test, lint, build, type)
- Identify root cause

## Steps
1. **Analyze Error Log**: Parse the CI output to identify specific failures
2. **Classify Error Type**:
   - Test failures: Logic errors, missing test cases
   - Lint errors: Code style violations
   - Type errors: Type annotation issues
   - Build errors: Compilation or dependency issues
3. **Implement Fix**: Make minimal changes to resolve the issue
4. **Validate**: Run relevant checks locally
5. **Document**: Explain what was fixed and why

## Rules
- Fix only what is broken, no scope creep
- Maintain backward compatibility
- Follow existing code patterns
- Do not add new features
- Keep changes minimal and focused

## Output Format
Provide:
- Summary of the issue
- List of files modified
- Explanation of the fix
- Validation results
```

**File**: `refactor-code.md`
```markdown
# /refactor - Code Refactoring

Refactor code to improve quality while maintaining functionality.

## Context
- Understand the current implementation
- Identify code smells and improvement opportunities
- Ensure all tests still pass

## Refactoring Targets
1. **Code Duplication**: Extract common patterns
2. **Long Functions**: Break into smaller, focused functions
3. **Complex Logic**: Simplify conditionals and loops
4. **Magic Numbers**: Use named constants
5. **Poor Naming**: Improve variable/function names
6. **Missing Types**: Add type hints (Python) or type safety (C++)

## Process
1. **Identify**: Find code that needs refactoring
2. **Plan**: Outline refactoring steps
3. **Test First**: Ensure current tests pass
4. **Refactor**: Make incremental changes
5. **Test Again**: Verify tests still pass
6. **Document**: Update comments and docs

## Constraints
- All existing tests must pass
- No behavioral changes
- Follow project style guide
- Commit each logical refactoring separately

## Output Format
For each refactoring:
- What was refactored
- Why it was needed
- Before/after comparison
- Test results
```

**File**: `review-pr.md`
```markdown
# /review-pr - Pull Request Review

Conduct a comprehensive code review of a Pull Request.

## Review Checklist

### 1. Code Quality
- [ ] Follows project coding standards
- [ ] Consistent style and formatting
- [ ] No code duplication
- [ ] Appropriate abstraction levels
- [ ] Clear and meaningful names

### 2. Functionality
- [ ] Implementation matches requirements
- [ ] Edge cases handled
- [ ] Error handling is appropriate
- [ ] No obvious bugs

### 3. Tests
- [ ] Adequate test coverage
- [ ] Tests are meaningful
- [ ] Edge cases tested
- [ ] Test names are descriptive

### 4. Security
- [ ] No security vulnerabilities
- [ ] Input validation present
- [ ] No hardcoded secrets
- [ ] Proper authentication/authorization

### 5. Performance
- [ ] No obvious performance issues
- [ ] Efficient algorithms
- [ ] Resource usage is reasonable

### 6. Documentation
- [ ] Code is well-commented
- [ ] Public APIs documented
- [ ] README updated if needed
- [ ] CHANGELOG updated

## Review Types
- **APPROVE**: Code is ready to merge
- **REQUEST_CHANGES**: Issues must be addressed
- **COMMENT**: Suggestions for improvement

## Output Format
```markdown
## Assessment: [APPROVE | REQUEST_CHANGES | COMMENT]

### Summary
[High-level assessment]

### Findings

#### Code Quality
- [Finding 1]
- [Finding 2]

#### Security
- [Finding 1]

#### Performance
- [Finding 1]

### Suggestions
1. [Suggestion 1]
2. [Suggestion 2]

### Action Items
- [ ] [Required change 1]
- [ ] [Required change 2]
```
```

**Implementation Steps**:
1. Create slash command templates for common tasks
2. Define clear structure and output formats
3. Add project-specific customizations
4. Test commands with Claude Code CLI
5. Document command usage

**Deliverables**:
- [ ] `/fix-ci` command template
- [ ] `/refactor` command template
- [ ] `/review-pr` command template
- [ ] Command documentation

### 4.2 Language-Specific Prompt Templates

**Task**: Create context-rich prompts for Python and C++ fixes

**File**: `.github/claude/prompts/templates/python_fix.md`

```markdown
# Python Project Fix Template

## Project Context
- **Language**: Python $PYTHON_VERSION
- **Linter**: Ruff
- **Type Checker**: mypy
- **Test Framework**: pytest
- **Build Tool**: pip + pyproject.toml

## Common Python Issues

### Linting Errors (Ruff)
- Unused imports: Remove or use
- Line length: Break long lines
- Complexity: Simplify functions
- F-string usage: Convert old-style formatting

### Type Errors (mypy)
- Missing type hints: Add annotations
- Type mismatches: Fix type usage
- Optional handling: Use proper Optional[T]
- Generic types: Specify type parameters

### Test Failures (pytest)
- Assertion errors: Fix logic or update test
- Import errors: Check module paths
- Fixture issues: Review pytest fixtures

## Fix Approach

1. **Read Error Message**: Understand the specific error
2. **Locate Code**: Find the problematic line/function
3. **Understand Context**: Review surrounding code
4. **Apply Fix**: Minimal change to resolve issue
5. **Validate**:
   ```bash
   ruff check .
   mypy src/
   pytest
   ```
