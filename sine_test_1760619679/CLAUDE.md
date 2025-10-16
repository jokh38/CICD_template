# AI Assistant Workflow Guide

This document provides guidance for AI assistants (like Claude) working on this C++ project.

## Project Overview

**Project**: sine_test_1760619679
**Description**: A C++ project
**Language**: C++17
**Build System**: Cmake
**Testing Framework**: GTEST

## Development Setup

### Build Configuration

This project uses Cmake as the build system:

```bash
# Configure build

cmake -B build -G Ninja

# Build the project
cmake --build build

# Run tests
ctest --test-dir build

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
sine_test_1760619679/
├── src/                      # Source files
│   ├── main.cpp             # Main executable
│   └── library.cpp          # Library implementation
├── include/sine_test_1760619679/  # Header files
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

- **C++ Standard**: C++17
- **Style**: Follow modern C++ best practices
- **Formatting**: Use clang-format (configured in .clang-format)
- **Warnings**: Compile with `-Wall -Wextra -Wpedantic -Werror`

### Code Organization

- **Headers**: Use include guards (`#pragma once` preferred)
- **Namespaces**: Use `sine_test_1760619679` namespace
- **Functions**: Include proper documentation and type safety
- **Error Handling**: Use exceptions or error codes consistently

## Testing

### Framework: GTEST

- Test files are located in `tests/` directory
- Use descriptive test names
- Aim for high test coverage
- Test both success and failure scenarios

### Running Tests

```bash

# Run all tests
ctest --test-dir build

# Run tests with verbose output
ctest --test-dir build --verbose

# Run specific test
./build/test_example

```

## Build System Details

### CMake


- **Minimum Version**: 3.20
- **Generator**: Ninja
- **Configuration**: Debug and Release builds supported
- **Dependencies**: Managed with FetchContent (e.g., gtest)


## Working with this Project

When making changes:

1. **Build First**: Always build before committing
2. **Run Tests**: Ensure all tests pass
3. **Check Code**: Run pre-commit hooks
4. **Document Changes**: Update relevant documentation

### Common Commands

```bash
# Clean build

rm -rf build && cmake -B build -G Ninja


# Debug build

cmake -B build -DCMAKE_BUILD_TYPE=Debug -G Ninja


# Release build

cmake -B build -DCMAKE_BUILD_TYPE=Release -G Ninja

```

## CI/CD Integration

The project includes GitHub Actions workflows for:
- **Continuous Integration**: Build and test on multiple platforms
- **Code Quality**: Linting and static analysis
- **Release**: Automated releases (when applicable)


## AI Assistant Integration

This project supports AI assistant workflows:
- Trigger AI workflows with `@claude` mentions in issues/PRs
- AI can help with code reviews, bug fixes, and feature development
- See `.github/workflows/ai-workflow.yaml` for details
