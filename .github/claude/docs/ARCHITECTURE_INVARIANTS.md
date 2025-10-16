# ARCHITECTURE_INVARIANTS (Compact)

## Purpose
Non-negotiable rules. If violated, STOP and ask human. These are "laws of physics" for the codebase.

## Critical Invariants

### Module Structure
- **INV-MS-001:** Single entry point (main.py)
- **INV-MS-002:** No circular dependencies (check: `pydeps src --show-cycles`)
- **INV-MS-003:** Clear layers - upper calls lower, never reverse

### Dependencies
- **INV-DR-001:** Absolute imports only: `from src.module import X`
- **INV-DR-002:** No wildcards: ❌ `from module import *`
- **INV-DR-004:** Wrap external libraries in adapter modules

### Data Flow
- **INV-DF-001:** Unidirectional flow (Input → Validate → Process → Store → Response)
- **INV-DF-002:** Immutable data between layers
- **INV-DF-003:** No global mutable state

### Configuration
- **INV-CF-001:** Single source per config value
- **INV-CF-002:** No hardcoded secrets
- **INV-CF-003:** Environment-driven config (no `if ENV == "prod"` in code)

### Error Handling
- **INV-EH-001:** Validate at boundaries (API endpoints, file parsing)
- **INV-EH-002:** Preserve error context: `raise NewError() from e`
- **INV-EH-003:** No silent failures (log or handle, never `except: pass`)

### Testing
- **INV-TS-001:** All public APIs must have tests (80%+ coverage)
- **INV-TS-002:** No real external calls in unit tests (use mocks)
- **INV-TS-003:** Test file naming: `test_<module_name>.py`

### Security
- **INV-SC-001:** Validate all external input
- **INV-SC-003:** No PII/passwords in logs

### Performance
- **INV-PF-001:** No N+1 query patterns
- **INV-PF-002:** Always cleanup resources (use context managers)

## Violation Response
If invariant violation needed: STOP → Document why → Consult team → Get approval → Add comment with ticket reference
