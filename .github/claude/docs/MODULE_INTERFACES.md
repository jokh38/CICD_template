# MODULE_INTERFACES (Compact)

## Purpose
Document public APIs to prevent breaking changes during refactoring.

## Rule
Changes to public interfaces require updating ALL "Used By" locations in same commit.

## Template Format

```markdown
## module_name
**Location:** src/path/to/module.py
**Status:** Active | Deprecated | Experimental

### Public Interface
- `function_name(param: Type) -> ReturnType`
  - Purpose: Brief description
  - Raises: ExceptionType if condition

- `ClassName`
  - Methods: __init__(), public_method()
  - Attributes: public_attr

### Dependencies
**Used By:**
- src/module_a.py:25 - Uses function_name()
- tests/test_module.py - All tests

### Configuration
**Env Variables:** ENV_VAR (default: "value")
**Config Keys:** config.section.key

### Breaking Change Policy
1. Add deprecation warnings
2. Create new interface alongside old
3. Update all "Used By" locations
4. Document in CHANGELOG
5. Remove after N releases
```

## Key Commands
```bash
# Find all usages
grep -r "from.*module_name import" src/
grep -r "module_name.function" src/

# Check for private imports (violations)
grep -r "from src._" src/
```

## Stability Levels
- **Stable:** Won't break without major version bump
- **Evolving:** May change with deprecation notice
- **Experimental:** May change anytime (not for production)
- **Internal:** Private (prefix with `_`)

## Before Modifying Interface
- [ ] Check "Used By" list
- [ ] Update ALL dependents in same commit
- [ ] Add deprecation if not backward compatible
- [ ] Update tests and docs together
