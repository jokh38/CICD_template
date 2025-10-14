# AI Assistant Workflow Guide

This document provides guidance for AI assistants (like Claude) working on this C++ project.

## Project Overview

**Project**: {{cookiecutter.project_name}}
**Description**: {{cookiecutter.project_description}}
**Language**: C++{{cookiecutter.cpp_standard}}
**Build System**: {{cookiecutter.build_system | capitalize}}
**Testing Framework**: {{cookiecutter.testing_framework | upper}}

## Development Setup

### Build Configuration

This project uses {{cookiecutter.build_system | capitalize}} as the build system:

```bash
# Configure build
{% if cookiecutter.build_system == "cmake" %}
cmake -B build {% if cookiecutter.use_ninja == "yes" %}-G Ninja{% endif %}

# Build the project
cmake --build build

# Run tests
ctest --test-dir build
{% else %}
meson setup build

# Build the project
meson compile -C build

# Run tests
meson test -C build
{% endif %}
```

### Code Quality Tools

The project includes pre-commit hooks for code quality:

```bash
# Install pre-commit hooks (done automatically)
pre-commit install

# Run hooks manually
pre-commit run --all-files
```

## Project Structure

```
{{cookiecutter.project_slug}}/
├── src/                      # Source files
│   ├── main.cpp             # Main executable
│   └── library.cpp          # Library implementation
├── include/{{cookiecutter.project_slug}}/  # Header files
│   └── library.hpp          # Library header
├── tests/                    # Test files
│   └── test_example.cpp     # Example tests
├── build/                    # Build output directory
├── .github/workflows/        # CI/CD workflows
├── CMakeLists.txt or meson.build  # Build configuration
└── README.md                # Project documentation
```

## Coding Standards

### C++ Standards

- **C++ Standard**: C++{{cookiecutter.cpp_standard}}
- **Style**: Follow modern C++ best practices
- **Formatting**: Use clang-format (configured in .clang-format)
- **Warnings**: Compile with `-Wall -Wextra -Wpedantic -Werror`

### Code Organization

- **Headers**: Use include guards (`#pragma once` preferred)
- **Namespaces**: Use `{{cookiecutter.project_slug}}` namespace
- **Functions**: Include proper documentation and type safety
- **Error Handling**: Use exceptions or error codes consistently

## Testing

### Framework: {{cookiecutter.testing_framework | upper}}

- Test files are located in `tests/` directory
- Use descriptive test names
- Aim for high test coverage
- Test both success and failure scenarios

### Running Tests

```bash
{% if cookiecutter.build_system == "cmake" %}
# Run all tests
ctest --test-dir build

# Run tests with verbose output
ctest --test-dir build --verbose

# Run specific test
./build/test_example
{% else %}
# Run all tests
meson test -C build

# Run tests with verbose output
meson test -C build --verbose

# Run specific test
./build/tests/test_example
{% endif %}
```

## Build System Details

### {% if cookiecutter.build_system == "cmake" %}CMake{% else %}Meson{% endif %}

{% if cookiecutter.build_system == "cmake" %}
- **Minimum Version**: 3.20
- **Generator**: {% if cookiecutter.use_ninja == "yes" %}Ninja{% else %}Default{% endif %}
- **Configuration**: Debug and Release builds supported
- **Dependencies**: Managed with FetchContent (e.g., gtest)
{% else %}
- **Configuration**: Simple and readable meson.build files
- **Dependencies**: Managed with wrap files
- **Cross-compilation**: Built-in support
{% endif %}

## Working with this Project

When making changes:

1. **Build First**: Always build before committing
2. **Run Tests**: Ensure all tests pass
3. **Check Code**: Run pre-commit hooks
4. **Document Changes**: Update relevant documentation

### Common Commands

```bash
# Clean build
{% if cookiecutter.build_system == "cmake" %}
rm -rf build && cmake -B build{% if cookiecutter.use_ninja == "yes" %} -G Ninja{% endif %}
{% else %}
rm -rf build && meson setup build
{% endif %}

# Debug build
{% if cookiecutter.build_system == "cmake" %}
cmake -B build -DCMAKE_BUILD_TYPE=Debug{% if cookiecutter.use_ninja == "yes" %} -G Ninja{% endif %}
{% else %}
meson setup build --buildtype=debug
{% endif %}

# Release build
{% if cookiecutter.build_system == "cmake" %}
cmake -B build -DCMAKE_BUILD_TYPE=Release{% if cookiecutter.use_ninja == "yes" %} -G Ninja{% endif %}
{% else %}
meson setup build --buildtype=release
{% endif %}
```

## CI/CD Integration

The project includes GitHub Actions workflows for:
- **Continuous Integration**: Build and test on multiple platforms
- **Code Quality**: Linting and static analysis
- **Release**: Automated releases (when applicable)

{% if cookiecutter.use_ai_workflow == "yes" %}
## AI Assistant Integration

This project supports AI assistant workflows:
- Trigger AI workflows with `@claude` mentions in issues/PRs
- AI can help with code reviews, bug fixes, and feature development
- See `.github/workflows/ai-workflow.yaml` for details
{% endif %}