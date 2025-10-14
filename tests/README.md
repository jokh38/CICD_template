# CICD Template System - Test Directory

This directory contains test projects and validation utilities for the CICD Template System.

## Structure

```
tests/
├── README.md                   # This file
├── test-projects/              # Generated test projects
│   ├── python-minimal/         # Basic Python project
│   ├── python-full/            # Full-featured Python project
│   ├── cpp-cmake/              # C++ CMake project
│   └── cpp-cmake-ninja/        # C++ CMake + Ninja project
├── expected-outputs/           # Expected file structures
└── validation/                 # Validation scripts
```

## Usage

### Running All Tests

Use the main test script from the repository root:

```bash
# Run all integration tests
bash scripts/test-templates.sh

# Run tests without cleanup
bash scripts/test-templates.sh --no-cleanup
```

### Running Performance Benchmarks

```bash
# Benchmark a Python project
bash scripts/benchmark-ci.sh /path/to/python-project

# Benchmark with custom settings
bash scripts/benchmark-ci.sh -r 5 -f json -s /path/to/cpp-project
```

### Manual Testing

```bash
# Create test Python project
cookiecutter ../cookiecutters/python-project \
    --no-input \
    project_name="Test Python Project"

# Create test C++ project
cookiecutter ../cookiecutters/cpp-project \
    --no-input \
    project_name="Test CPP Project"
```

## Test Coverage

The integration tests cover:

1. **Template Generation**
   - Cookiecutter template execution
   - Variable substitution
   - File structure creation

2. **Python Projects**
   - Virtual environment setup
   - Dependency installation
   - Pre-commit hooks
   - Ruff linting and formatting
   - pytest execution

3. **C++ Projects**
   - CMake configuration
   - Build system generation
   - Compilation and linking
   - Test execution with ctest

4. **Configuration Files**
   - YAML syntax validation
   - TOML syntax validation
   - Configuration completeness

5. **Scripts**
   - Bash/PowerShell syntax
   - Help functionality
   - Error handling

6. **Performance**
   - Project creation speed
   - Linting performance
   - Build performance

## Validation Criteria

### Success Criteria

- All templates generate valid projects
- Generated projects compile/run successfully
- All scripts execute without syntax errors
- Configuration files are syntactically correct
- Performance meets baseline expectations

### Failure Modes

- Template generation fails
- Generated projects have build errors
- Scripts have syntax or runtime errors
- Configuration files are malformed
- Performance is significantly below expectations

## Expected Outputs

### Python Project Structure

```
test-python-project/
├── .git/
├── .github/
│   └── workflows/
│       └── ci.yaml
├── .pre-commit-config.yaml
├── .venv/
├── pyproject.toml
├── src/
│   └── test_python_project/
│       └── __init__.py
├── tests/
│   └── test_example.py
└── README.md
```

### C++ Project Structure

```
test-cpp-project/
├── .git/
├── .github/
│   └── workflows/
│       └── ci.yaml
├── .clang-format
├── .clang-tidy
├── .pre-commit-config.yaml
├── CMakeLists.txt
├── build/
├── src/
│   └── main.cpp
├── tests/
│   ├── CMakeLists.txt
│   └── test_example.cpp
└── README.md
```

## Troubleshooting

### Common Issues

1. **Cookiecutter not found**
   ```bash
   pip install cookiecutter
   ```

2. **Virtual environment creation fails**
   - Ensure Python 3.10+ is installed
   - Check available disk space

3. **CMake configuration fails**
   - Install CMake and Ninja build tools
   - Verify compiler installation

4. **Tests fail to run**
   - Check dependencies in pyproject.toml
   - Verify test file syntax

### Debug Mode

Run tests with verbose output:

```bash
bash scripts/test-templates.sh --no-cleanup
```

This will keep all generated files for manual inspection.

## Performance Baselines

Expected performance metrics:

| Operation | Target | Acceptable |
|-----------|--------|------------|
| Python project creation | < 10s | < 30s |
| C++ project creation | < 15s | < 30s |
| Ruff lint (small project) | < 1s | < 5s |
| CMake configure | < 10s | < 30s |
| C++ build (small project) | < 30s | < 120s |

## Contributing

When adding new tests:

1. Follow the existing naming conventions
2. Include appropriate error handling
3. Add documentation for new test cases
4. Update this README with new test coverage
5. Verify tests pass before submitting

---

**Directory created:** 2025-10-14
**Purpose:** Integration testing for CICD Template System