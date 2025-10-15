Refactor existing code following best practices and design patterns.

Usage: /refactor-code <file_path> <description>

This command will:
1. Analyze the specified code file
2. Identify improvement opportunities
3. Apply refactoring with test coverage
4. Ensure functionality remains intact
5. Update documentation as needed

Refactoring focus areas:
- Code readability and maintainability
- Performance optimization
- Design pattern implementation
- Error handling improvements
- Code deduplication
- Security enhancements

Examples:
- /refactor-code src/utils.py "Extract common patterns into reusable functions"
- /refactor-code lib/calculator.cpp "Implement proper error handling and input validation"

The refactoring maintains:
- Public API compatibility
- Existing behavior
- Test coverage
- Documentation accuracy