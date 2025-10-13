# {{cookiecutter.project_name}}

{{cookiecutter.project_description}}

## Building

```bash
# Configure
cmake -B build {% if cookiecutter.use_ninja == "yes" %}-G Ninja{% endif %} -DCMAKE_BUILD_TYPE=Release

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

{{cookiecutter.author_name}} <{{cookiecutter.author_email}}>
