# C++-Specific Guidelines

## Memory Management
- **RAII**: Resource Acquisition Is Initialization principles
- **Smart Pointers**: Proper use of std::unique_ptr, std::shared_ptr, std::weak_ptr
- **Memory Leaks**: No raw new/delete without RAII
- **Buffer Overflows**: Proper bounds checking and safe functions

## Modern C++ Features
- **C++11/14/17/20**: Use modern language features appropriately
- **Auto Keyword**: Proper use for type inference
- **Range-based For**: Prefer over traditional loops
- **Move Semantics**: Efficient resource transfer
- **Lambda Expressions**: Proper capture and usage

## Template & Generic Programming
- **Template Design**: Proper template constraints and concepts
- **SFINAE**: Substitution Failure Is Not An Error
- **Header Organization**: Proper include guards and organization
- **Inline Functions**: Appropriate use for performance

## Error Handling & Safety
- **Exceptions**: Proper exception handling and RAII
- **Assertions**: Use of assert for debugging
- **Const Correctness**: Proper use of const keyword
- **Null Pointer Checks**: Validation of pointers before dereferencing

## Performance & Optimization
- **Algorithm Complexity**: Appropriate choice of algorithms and containers
- **Compiler Optimizations**: Proper use of inline, constexpr
- **Cache Efficiency**: Memory access patterns
- **Move vs Copy**: Minimize unnecessary copies

## Build System & Dependencies
- **CMake**: Proper CMake configuration
- **Header Dependencies**: Minimal include dependencies
- **Linkage**: Proper static/dynamic library usage
- **Cross-Platform**: Platform-independent code where possible

## Tooling
- **Formatting**: `clang-format`
- **Linting**: `clang-tidy`
- **Static Analysis**: `cppcheck`
- **Sanitizers**: AddressSanitizer, MemorySanitizer, ThreadSanitizer
- **Testing**: Google Test, Catch2
- **Build**: CMake

## Common C++ Patterns

### Bad vs Good Examples
```cpp
// Bad
void processData() {
    int* data = new int[1000];
    // ... process data
    delete[] data;  // Risk of forgetting delete
}

// Good
void processData() {
    std::vector<int> data(1000);
    // ... process data
    // Automatic cleanup
}
```

```cpp
// Bad
class MyClass {
    Resource* resource;
public:
    MyClass() : resource(new Resource()) {}
    ~MyClass() { delete resource; }  // Risk in copy/move
};

// Good
class MyClass {
    std::unique_ptr<Resource> resource;
public:
    MyClass() : resource(std::make_unique<Resource>()) {}
    // Default destructor handles cleanup
};
```

```cpp
// Bad
for (std::vector<int>::iterator it = vec.begin(); it != vec.end(); ++it) {
    std::cout << *it << std::endl;
}

// Good
for (const auto& value : vec) {
    std::cout << value << std::endl;
}
```