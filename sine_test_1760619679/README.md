# sine_test_1760619679

A C++ project

## Building

```bash
# Configure
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release

# Build
cmake --build build -j$(nproc)

# Test
ctest --test-dir build --output-on-failure
```

## Development

```bash
# Install pre-commit hooks
pre-commit install

# Format code
clang-format -i src/*.cpp include/**/*.hpp
```

## Author

Your Name <your.email@example.com>
