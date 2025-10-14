# C++ Linux GitHub Actions Runner Guide

A comprehensive GitHub Actions workflow for C++ projects on Linux with advanced features including caching, static analysis, code coverage, and sanitizers.

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Quick Start](#quick-start)
- [Configuration Options](#configuration-options)
- [Usage Examples](#usage-examples)
- [Advanced Features](#advanced-features)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

The C++ Linux Runner (`cpp-linux-runner.yaml`) is a reusable GitHub Actions workflow that provides a complete CI/CD pipeline for C++ projects on Linux. It supports multiple compilers, build systems, and advanced development tools.

### Key Benefits

- **🚀 Fast Builds**: sccache integration for up to 12x faster cached builds
- **🔍 Quality Assurance**: Static analysis, formatting checks, and code coverage
- **🛡️ Safety**: AddressSanitizer, UndefinedBehaviorSanitizer, and Valgrind
- **⚙️ Flexible**: Support for GCC/Clang, CMake/Meson, C++17/20/23
- **📊 Insights**: Comprehensive build summaries and coverage reports

---

## Features

### Build System Support
- **CMake**: Full support with Ninja generator
- **Meson**: Alternative fast build system
- **Compilers**: GCC and Clang with version detection
- **C++ Standards**: C++17, C++20, C++23

### Build Types
- **Debug**: Development with debug symbols
- **Release**: Optimized production builds
- **RelWithDebInfo**: Optimized with debug info
- **MinSizeRel**: Size-optimized builds

### Quality Tools
- **sccache**: Distributed compilation caching
- **clang-format**: Code formatting verification
- **clang-tidy**: Static analysis (Clang)
- **cppcheck**: Static analysis (additional)
- **lcov**: Code coverage generation
- **Valgrind**: Memory leak detection

### Testing & Analysis
- **ctest**: CMake test runner
- **meson test**: Meson test runner
- **AddressSanitizer**: Memory error detection
- **UndefinedBehaviorSanitizer**: UB detection
- **Code Coverage**: With lcov and Codecov integration

---

## Quick Start

### 1. Basic Usage

Create `.github/workflows/ci.yml` in your project:

```yaml
name: CI

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  ci:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Release'
      cpp-standard: '20'
      compiler: 'gcc'
      enable-tests: true
      enable-cache: true
```

### 2. Advanced Usage with All Features

```yaml
name: Advanced CI

on: [push, pull_request]

jobs:
  # Main build with all features
  main:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Release'
      cpp-standard: '20'
      compiler: 'gcc'
      build-system: 'cmake'
      enable-cache: true
      enable-tests: true
      enable-static-analysis: true
      enable-formatting-check: true
      runner-type: 'ubuntu-latest'
      use-ninja: true

  # Coverage build
  coverage:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Debug'
      cpp-standard: '20'
      compiler: 'gcc'
      enable-tests: true
      enable-coverage: true
      enable-static-analysis: false
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}

  # Sanitizer build
  sanitizers:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Debug'
      compiler: 'clang'
      enable-tests: true
      enable-sanitizers: true
      enable-memory-check: true
```

---

## Configuration Options

### Build Configuration

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `build-type` | choice | 'Release' | CMake build type (Debug/Release/RelWithDebInfo/MinSizeRel) |
| `cpp-standard` | choice | '20' | C++ standard version (17/20/23) |
| `compiler` | choice | 'gcc' | Compiler to use (gcc/clang) |
| `build-system` | choice | 'cmake' | Build system (cmake/meson) |
| `use-ninja` | boolean | true | Use Ninja build generator |
| `parallel-jobs` | string | '$(nproc)' | Number of parallel build jobs |

### Feature Toggles

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `enable-cache` | boolean | true | Enable sccache for build caching |
| `enable-tests` | boolean | true | Run unit tests |
| `enable-coverage` | boolean | false | Generate code coverage report |
| `enable-static-analysis` | boolean | true | Run clang-tidy and cppcheck |
| `enable-sanitizers` | boolean | false | Enable ASan/UBSan in Debug |
| `enable-formatting-check` | boolean | true | Check code formatting |
| `enable-memory-check` | boolean | false | Run Valgrind memory checks |

### Environment

| Input | Type | Default | Description |
|-------|------|---------|-------------|
| `runner-type` | choice | 'ubuntu-latest' | GitHub Actions runner |
| `cmake-options` | string | '' | Additional CMake options |

### Secrets

| Secret | Required | Description |
|--------|----------|-------------|
| `CODECOV_TOKEN` | optional | Token for Codecov upload |

---

## Usage Examples

### Example 1: Simple Library Project

```yaml
name: Library CI

on: [push, pull_request]

jobs:
  build:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Release'
      cpp-standard: '17'
      compiler: 'gcc'
      enable-tests: true
      enable-static-analysis: true
      enable-formatting-check: true
```

### Example 2: Multi-Configuration Build Matrix

```yaml
name: Matrix CI

on: [push, pull_request]

jobs:
  matrix-build:
    strategy:
      matrix:
        compiler: [gcc, clang]
        build-type: [Debug, Release]
        cpp-standard: [17, 20]
        exclude:
          # Skip Debug builds with older standards
          - build-type: Debug
            cpp-standard: 17

    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: ${{ matrix.build-type }}
      cpp-standard: ${{ matrix.cpp-standard }}
      compiler: ${{ matrix.compiler }}
      enable-tests: true
      enable-cache: true
      enable-coverage: ${{ matrix.build-type == 'Debug' }}
      enable-static-analysis: ${{ matrix.build-type == 'Release' }}
```

### Example 3: Performance-Focused Workflow

```yaml
name: Performance CI

on: [push]

jobs:
  benchmark:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Release'
      cpp-standard: '20'
      compiler: 'gcc'
      enable-cache: true
      enable-tests: false
      enable-static-analysis: false
      enable-formatting-check: false
      use-ninja: true
      cmake-options: '-DCMAKE_CXX_FLAGS="-O3 -march=native"'

  # Build time measurement
  benchmark-timing:
    runs-on: ubuntu-latest
    needs: benchmark
    steps:
      - name: Get build time from previous job
        run: echo "Check build time in the previous job's summary"
```

### Example 4: Safety-Critical Workflow

```yaml
name: Safety-Critical CI

on: [push, pull_request]

jobs:
  safety:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Debug'
      cpp-standard: '20'
      compiler: 'clang'
      enable-tests: true
      enable-coverage: true
      enable-static-analysis: true
      enable-sanitizers: true
      enable-memory-check: true
      enable-formatting-check: true
    secrets:
      CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

---

## Advanced Features

### 1. Build Caching with sccache

The workflow automatically configures sccache for compilation caching:

```yaml
# Enable caching (default)
enable-cache: true

# Cache is keyed by:
# - Operating system
# - Compiler version
# - C++ standard
# - Source file hashes (CMakeLists.txt, source files)
```

**Cache Statistics:**
The workflow displays sccache statistics after each build, showing cache hit rates and performance improvements.

### 2. Static Analysis Integration

**clang-tidy** (Clang only):
```yaml
compiler: 'clang'
enable-static-analysis: true
```

**cppcheck** (all compilers):
```yaml
enable-static-analysis: true
```

Results are uploaded as artifacts and can be reviewed in the GitHub Actions UI.

### 3. Code Coverage

**Setup:**
```yaml
build-type: 'Debug'
enable-coverage: true
```

**Integration with Codecov:**
```yaml
secrets:
  CODECOV_TOKEN: ${{ secrets.CODECOV_TOKEN }}
```

The workflow generates:
- lcov coverage reports
- Coverage percentage badge
- Upload to Codecov (if token provided)

### 4. Sanitizers

**Enable in Debug builds:**
```yaml
build-type: 'Debug'
enable-sanitizers: true
```

This enables:
- **AddressSanitizer**: Detects memory errors (buffer overflows, use-after-free)
- **UndefinedBehaviorSanitizer**: Detects undefined behavior

### 5. Memory Leak Detection

**Valgrind integration:**
```yaml
build-type: 'Debug'
enable-memory-check: true
```

Runs Valgrind on test executables to detect memory leaks and invalid memory access.

### 6. Custom CMake Options

Pass additional CMake options:

```yaml
cmake-options: '-DENABLE_FEATURE_X=ON -DBUILD_TESTS=OFF'
```

Common options:
- `-DCMAKE_CXX_FLAGS="-O3 -march=native"` (performance optimization)
- `-DBoost_DEBUG=ON` (debugging Boost)
- `-DCMAKE_VERBOSE_MAKEFILE=ON` (verbose build output)

---

## Best Practices

### 1. Project Structure

Organize your project for best CI/CD integration:

```
my-project/
├── .github/
│   └── workflows/
│       └── ci.yml                    # Your workflow
├── src/                              # Source files
├── include/                          # Header files
├── tests/                            # Test files
├── CMakeLists.txt                    # Main CMake file
├── .clang-format                     # Formatting config
├── .clang-tidy                       # Static analysis config
└── README.md
```

### 2. CMake Configuration

**Best practices for CMakeLists.txt:**

```cmake
cmake_minimum_required(VERSION 3.20)
project(MyProject VERSION 1.0.0 LANGUAGES CXX)

# C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Export compile commands for clang-tidy
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

# Compiler warnings
if(MSVC)
    add_compile_options(/W4 /WX)
else()
    add_compile_options(-Wall -Wextra -Wpedantic -Werror)
endif()

# Testing
enable_testing()
find_package(GTest REQUIRED)

# Your targets...
```

### 3. Test Organization

**Organize tests with CTest:**

```cmake
# In CMakeLists.txt
add_executable(my_tests test_main.cpp test_feature1.cpp)
target_link_libraries(my_tests PRIVATE GTest::gtest GTest::gtest_main)

add_test(NAME UnitTests COMMAND my_tests)
```

### 4. Configuration Files

**.clang-format:**
```yaml
BasedOnStyle: Google
IndentWidth: 2
ColumnLimit: 100
```

**.clang-tidy:**
```yaml
Checks: >
  *,
  -readability-magic-numbers,
  -cppcoreguidelines-avoid-magic-numbers,
  -modernize-use-trailing-return-type
```

### 5. Workflow Optimization

**Tips for faster CI:**

1. **Use sccache**: Enable build caching
2. **Parallel builds**: Use multiple cores
3. **Ninja generator**: Faster than Make
4. **Selective features**: Don't run everything on every push
5. **Matrix optimization**: Skip redundant combinations

```yaml
# Optimized workflow example
jobs:
  pr-build:
    if: github.event_name == 'pull_request'
    strategy:
      matrix:
        compiler: [gcc, clang]
        include:
          - compiler: gcc
            enable-coverage: true
          - compiler: clang
            enable-static-analysis: true

    uses: ./.github/workflows/cpp-linux-runner.yaml@v1
    with:
      compiler: ${{ matrix.compiler }}
      enable-coverage: ${{ matrix.enable-coverage }}
      enable-static-analysis: ${{ matrix.enable-static-analysis }}
```

---

## Troubleshooting

### Common Issues

#### 1. Cache Not Working
**Problem**: sccache shows 0% hit rate

**Solution**: Check cache key generation:
- Ensure CMakeLists.txt is committed
- Verify source file changes are tracked
- Check compiler version consistency

#### 2. Static Analysis Failures
**Problem**: clang-tidy fails on CI but passes locally

**Solution**:
- Check compile_commands.json generation
- Ensure all headers are available
- Verify clang-tidy version compatibility

#### 3. Coverage Upload Fails
**Problem**: Codecov upload fails

**Solution**:
- Verify CODECOV_TOKEN is set in repository secrets
- Ensure coverage.info file is generated
- Check file permissions

#### 4. Sanitizer Failures
**Problem**: ASan reports false positives

**Solution**:
- Check for known sanitizer issues in dependencies
- Use suppression files if needed
- Verify Debug build configuration

#### 5. Build Time Too Long
**Problem**: CI builds are slow

**Solution**:
- Enable sccache
- Use Ninja generator
- Increase parallel job count
- Review build dependencies

### Debugging Workflow Failures

#### 1. Enable Verbose Output
```yaml
cmake-options: '-DCMAKE_VERBOSE_MAKEFILE=ON'
```

#### 2. Check Job Logs
- Review individual job logs in GitHub Actions
- Look for specific error messages
- Check dependency installation steps

#### 3. Use Debug Artifacts
Enable artifact uploads for debugging:
```yaml
# Add to your workflow
- name: Upload build directory
  uses: actions/upload-artifact@v4
  if: failure()
  with:
    name: build-debug
    path: build/
```

#### 4. Local Reproduction
Reproduce CI environment locally:
```bash
# Install same tools
sudo apt-get install cmake ninja-build clang-tidy cppcheck

# Use same compiler flags
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=20
cmake --build build
```

### Performance Tuning

#### 1. Cache Optimization
- Use specific cache keys
- Limit cache size if needed
- Monitor cache hit rates

#### 2. Build Optimization
```yaml
# For maximum performance
cmake-options: '-DCMAKE_CXX_FLAGS="-O3 -march=native -DNDEBUG"'
```

#### 3. Test Parallelization
```yaml
# Parallel test execution
parallel-jobs: '8'  # Adjust based on runner capabilities
```

---

## Migration Guide

### From Basic CI to Advanced Runner

**Before (simple ci.yml):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - run: cmake -B build
      - run: cmake --build build
      - run: ctest --test-dir build
```

**After (using runner):**
```yaml
name: CI
on: [push, pull_request]
jobs:
  build:
    uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
    with:
      build-type: 'Release'
      enable-tests: true
      enable-cache: true
      enable-static-analysis: true
```

**Benefits gained:**
- ✅ Build caching (2-12x faster)
- ✅ Static analysis integration
- ✅ Code formatting checks
- ✅ Comprehensive error reporting
- ✅ Multiple compiler support
- ✅ Sanitizer support

---

## Repository Setup

### 1. Fork or Import Template

```bash
# Option A: Use as reusable workflow (recommended)
# Reference in your project's .github/workflows/ci.yml

# Option B: Copy workflow to your repository
cp .github/workflows/cpp-linux-runner.yaml your-repo/.github/workflows/
```

### 2. Configure Repository Secrets

Add these secrets to your GitHub repository:

```
CODECOV_TOKEN=your_codecov_token_here
```

### 3. Update Workflow Reference

```yaml
uses: YOUR-ORG/github-cicd-templates/.github/workflows/cpp-linux-runner.yaml@v1
```

Replace `YOUR-ORG` with your GitHub organization.

### 4. Test Configuration

Create a test PR to verify:
- ✅ Build succeeds
- ✅ Tests run
- ✅ Cache works
- ✅ Coverage generates (if enabled)
- ✅ Static analysis runs

---

## FAQ

### Q: Can I use this with existing projects?
**A**: Yes! The workflow works with any CMake or Meson-based C++ project. Just reference the workflow in your CI configuration.

### Q: How much does sccache improve build times?
**A**: Typical improvements:
- First build: Same as normal
- Cached builds: 5-12x faster
- Large projects: Up to 30x faster

### Q: Can I add custom build steps?
**A**: Yes, you can extend the workflow or add additional jobs that run before/after the main CI job.

### Q: Does this work with self-hosted runners?
**A**: Yes, set `runner-type: 'self-hosted'` and ensure your runner has the required dependencies installed.

### Q: How do I handle project-specific dependencies?
**A**: Use the `cmake-options` input or create a setup script that runs before the main build.

### Q: Can I run different configurations in parallel?
**A**: Yes, use a matrix strategy with different inputs for each job.

---

## Contributing

To contribute improvements to the C++ Linux Runner:

1. Fork the template repository
2. Create a feature branch
3. Test your changes with sample projects
4. Submit a pull request

### Testing Changes

Use the provided test script:
```bash
bash scripts/test-cpp-runner.sh
```

This will test the workflow with various configurations.

---

## Support

For issues and questions:

1. **Documentation**: Check this guide and inline comments
2. **Issues**: Open an issue on the template repository
3. **Discussions**: Use GitHub Discussions for questions
4. **Examples**: See the `examples/` directory for sample configurations

---

**Last Updated**: 2025-10-14
**Version**: 1.0
**Compatibility**: GitHub Actions, Ubuntu 20.04/22.04, CMake 3.20+, GCC 9+, Clang 10+