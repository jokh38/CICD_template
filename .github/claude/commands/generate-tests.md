Generate comprehensive tests for existing code.

Usage: /generate-tests <file_path> [test_type]

This command will:
1. Analyze the specified code file
2. Identify testable functions and methods
3. Generate comprehensive unit tests
4. Add integration tests where appropriate
5. Include edge cases and error scenarios
6. Ensure test coverage targets are met

Test types:
- unit: Generate unit tests (default)
- integration: Generate integration tests
- e2e: Generate end-to-end tests
- all: Generate all test types

Examples:
- /generate-tests src/utils.py
- /generate-tests lib/calculator.cpp unit
- /generate-tests api/endpoints.py integration

Generated tests include:
- Functionality verification
- Boundary condition testing
- Error handling validation
- Performance benchmarks
- Mock dependencies appropriately