# Python-Specific Guidelines

## Code Style & PEP 8
- **Naming Conventions**: snake_case for variables/functions, PascalCase for classes
- **Import Organization**: Standard library imports first, then third-party, then local
- **Line Length**: Maximum 79-88 characters per line
- **Whitespace**: Proper spacing around operators, function definitions
- **Docstrings**: PEP 257 compliant docstrings for all modules, classes, and functions

## Type Hints & Static Analysis
- **Type Annotations**: Proper use of typing module for function signatures
- **MyPy Compatibility**: Code passes static type checking
- **Generic Types**: Appropriate use of generics and type variables
- **Optional Types**: Proper handling of Optional and Union types

## Error Handling
- **Exception Handling**: Specific exception types, proper except clauses
- **Resource Management**: Context managers for file operations and resources
- **Logging**: Appropriate use of logging module
- **Validation**: Input validation with clear error messages

## Performance & Best Practices
- **List Comprehensions**: Use instead of loops where appropriate
- **String Operations**: Efficient string formatting and manipulation
- **Memory Management**: Avoid memory leaks and unnecessary object creation
- **Concurrency**: Proper use of threading, asyncio, or multiprocessing

## Testing
- **Pytest Structure**: Proper test organization and fixtures
- **Mock Usage**: Appropriate mocking of external dependencies
- **Coverage**: Adequate test coverage for new functionality
- **Integration Tests**: Testing component interactions

## Dependencies & Packaging
- **Requirements**: Proper specification in requirements.txt or pyproject.toml
- **Virtual Environments**: Clear instructions for environment setup
- **Version Management**: Semantic versioning for releases
- **Dependencies**: Minimal and well-maintained dependencies

## Tooling
- **Formatting**: `ruff format`
- **Linting**: `ruff check`
- **Type Checking**: `mypy`
- **Testing**: `pytest`
- **Security**: `bandit`

## Common Python Patterns

### Bad vs Good Examples
```python
# Bad
def calculateTotal(items):
    total=0
    for item in items:
        total+=item.price
    return total

# Good
def calculate_total(items: list[Item]) -> float:
    """Calculate total price of items."""
    total = 0.0
    for item in items:
        total += item.price
    return total
```

```python
# Bad
try:
    result = dangerous_operation()
except:
    return None

# Good
try:
    result = dangerous_operation()
except SpecificError as e:
    logger.error(f"Operation failed: {e}")
    return None
```

```python
# Bad
f = open('file.txt')
content = f.read()
f.close()

# Good
with open('file.txt', 'r', encoding='utf-8') as f:
    content = f.read()
```