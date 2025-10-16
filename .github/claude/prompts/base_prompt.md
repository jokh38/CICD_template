# Base AI Prompt Template

## Core AI Workflow Instructions

### 🚀 AI AUTOMATED PR CREATION WORKFLOW (Core Automation Guidelines)

**Goal**: Receive development requests through external commands, generate and validate code, and **automatically create the final Pull Request**.

**AI Automated PR Creation Steps (5-Step Process)**

| Step | Responsibility | Detail |
| :--- | :--- | :--- |
| **1. Command Analysis** | `Issue/PR Comment` | Accurately extract requested **task type** (`add-feature`, `fix-issue`) and **detailed requirements** |
| **2. Code & Test Generation** | `src/`, `tests/` | Implement code matching requirements and **simultaneously** write unit tests (`pytest`, `gtest`, `jest` based on language) |
| **3. Local Quality Validation** | `pre-commit` Hooks | **Immediately after code generation**, ensure passing quality gates: <br> - **Formatting**: Language-specific formatters <br> - **Linting/Analysis**: Language-specific linters <br> - **Testing**: Run test suite |
| **4. Atomic Commit** | `git commit` | Bundle all changes including code and test files into a **single atomic commit** |
| **5. PR Creation & Completion** | `git push` & `gh pr create` | Push commit to new feature branch, **automatically create Pull Request** to main branch, then complete task |

### ⚠️ CRITICAL INVARIANTS (Non-negotiable Rules)

**Architecture Rules:**
- **INV-MS-001:** Single entry point (main.py/main.cpp/main.js)
- **INV-MS-002:** No circular dependencies (check: `pydeps src --show-cycles`)
- **INV-MS-003:** Clear layers - upper calls lower, never reverse

**Dependency Rules:**
- **INV-DR-001:** Absolute imports only: `from src.module import X`
- **INV-DR-002:** No wildcards: ❌ `from module import *`
- **INV-DR-004:** Wrap external libraries in adapter modules

**Data Flow Rules:**
- **INV-DF-001:** Unidirectional flow (Input → Validate → Process → Store → Response)
- **INV-DF-002:** Immutable data between layers
- **INV-DF-003:** No global mutable state

**Configuration Rules:**
- **INV-CF-001:** Single source per config value
- **INV-CF-002:** No hardcoded secrets
- **INV-CF-003:** Environment-driven config (no `if ENV == "prod"` in code)

**Error Handling Rules:**
- **INV-EH-001:** Validate at boundaries (API endpoints, file parsing)
- **INV-EH-002:** Preserve error context: `raise NewError() from e`
- **INV-EH-003:** No silent failures (log or handle, never `except: pass`)

**Testing Rules:**
- **INV-TS-001:** All public APIs must have tests (80%+ coverage)
- **INV-TS-002:** No real external calls in unit tests (use mocks)
- **INV-TS-003:** Test file naming: `test_<module_name>.py`

**Security Rules:**
- **INV-SC-001:** Validate all external input
- **INV-SC-003:** No PII/passwords in logs

**Performance Rules:**
- **INV-PF-001:** No N+1 query patterns
- **INV-PF-002:** Always cleanup resources (use context managers)

### 🔒 Security Guidelines
- **NEVER** hardcode secrets or API keys in code
- **ALWAYS** use GitHub Secrets to manage sensitive data
- **ALWAYS** validate external inputs and follow principle of least privilege

### 📋 Universal Development Process

**Problem Analysis:**
1. **Identify Root Cause**: Analyze error logs and failing tests to understand the core issue
2. **Reproduce Issue**: Create minimal reproduction case if possible
3. **Assess Impact**: Determine scope of the bug and affected functionality
4. **Review Recent Changes**: Identify what might have introduced the issue

**Debugging Process:**
1. **Log Analysis**: Carefully examine error messages, stack traces, and CI logs
2. **Code Review**: Examine suspicious code paths and recent changes
3. **Environment Check**: Verify configuration, dependencies, and environment setup
4. **Isolation**: Narrow down the specific conditions that trigger the failure

**Fix Implementation:**
1. **Targeted Fix**: Implement minimal change that resolves the issue
2. **Verify Solution**: Ensure the fix actually resolves the problem
3. **Regression Test**: Add tests to prevent this issue from recurring
4. **Documentation**: Document the fix and any preventive measures

**Validation Requirements:**
- **Fix Verification**: Confirm the original issue is resolved
- **No Regressions**: Ensure existing functionality still works
- **Test Coverage**: Add tests for the specific bug scenario
- **CI Validation**: Ensure all CI checks pass after the fix

### 🎯 Quality Assurance Checklist
- [ ] Code follows project conventions and style guidelines
- [ ] Implementation is correct and complete
- [ ] Error handling is appropriate and robust
- [ ] Performance considerations are addressed
- [ ] Security implications are evaluated
- [ ] Tests are comprehensive and pass
- [ ] Documentation is updated and accurate
- [ ] Backward compatibility is maintained
- [ ] Integration with existing code is proper
- [ ] Configuration and deployment considerations are addressed

### 💡 Success Metrics
- **PR creation success** is the final success metric for AI automation tasks
- All quality gates must pass before PR creation
- Atomic commits ensure traceability
- Comprehensive test coverage prevents regressions

---

**Note**: This base prompt is included by reference in all language-specific prompts. Changes to core workflow rules should be made here to maintain consistency across all AI tasks.