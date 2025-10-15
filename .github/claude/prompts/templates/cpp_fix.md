You are an expert C++ developer fixing C++-specific issues. Please address the following:

## C++-Specific Review Areas

### 1. Memory Management
- **RAII**: Resource Acquisition Is Initialization principles
- **Smart Pointers**: Proper use of std::unique_ptr, std::shared_ptr, std::weak_ptr
- **Memory Leaks**: No raw new/delete without RAII
- **Buffer Overflows**: Proper bounds checking and safe functions

### 2. Modern C++ Features
- **C++11/14/17/20**: Use modern language features appropriately
- **Auto Keyword**: Proper use for type inference
- **Range-based For**: Prefer over traditional loops
- **Move Semantics**: Efficient resource transfer
- **Lambda Expressions**: Proper capture and usage

### 3. Template & Generic Programming
- **Template Design**: Proper template constraints and concepts
- **SFINAE**: Substitution Failure Is Not An Error
- **Header Organization**: Proper include guards and organization
- **Inline Functions**: Appropriate use for performance

### 4. Error Handling & Safety
- **Exceptions**: Proper exception handling and RAII
- **Assertions**: Use of assert for debugging
- **Const Correctness**: Proper use of const keyword
- **Null Pointer Checks**: Validation of pointers before dereferencing

### 5. Performance & Optimization
- **Algorithm Complexity**: Appropriate choice of algorithms and containers
- **Compiler Optimizations**: Proper use of inline, constexpr
- **Cache Efficiency**: Memory access patterns
- **Move vs Copy**: Minimize unnecessary copies

### 6. Build System & Dependencies
- **CMake**: Proper CMake configuration
- **Header Dependencies**: Minimal include dependencies
- **Linkage**: Proper static/dynamic library usage
- **Cross-Platform**: Platform-independent code where possible

## Common C++ Issues to Fix

### Memory Management
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

### Smart Pointers
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

### Modern C++
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

### Exception Safety
```cpp
// Bad
void riskyOperation() {
    Resource* r1 = new Resource();
    Resource* r2 = new Resource();  // Leak if this throws
    delete r1;
    delete r2;
}

// Good
void riskyOperation() {
    auto r1 = std::make_unique<Resource>();
    auto r2 = std::make_unique<Resource>();
    // Automatic cleanup on exception
}
```

## Review Checklist
- [ ] No raw pointers without RAII
- [ ] Smart pointers used appropriately
- [ ] No memory leaks (check with Valgrind/AddressSanitizer)
- [ ] Modern C++ features used where beneficial
- [ ] Proper exception safety
- [ ] Const correctness throughout
- [ ] No buffer overflows or unsafe functions
- [ ] Appropriate algorithm choices
- [ ] Clean, compilable CMake configuration
- [ ] Proper include organization
- [ ] Thread safety where applicable
- [ ] No undefined behavior

## Tooling for C++ Quality
- **Static Analysis**: clang-tidy, cppcheck
- **Sanitizers**: AddressSanitizer, MemorySanitizer, ThreadSanitizer
- **Formatters**: clang-format
- **Build**: CMake with proper warnings
- **Testing**: Google Test, Catch2

Please fix any C++-specific issues found in the code and ensure all modern C++ best practices are followed.