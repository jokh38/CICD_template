You are an expert Go developer fixing Go-specific issues. Please address the following:

## Go-Specific Review Areas

### 1. Idiomatic Go Patterns
- **Error Handling**: Explicit error checking, no exceptions
- **Interface Design**: Small, focused interfaces
- **Goroutine Safety**: Proper concurrency patterns
- **Package Structure**: Clear package organization
- **Naming Conventions**: Go naming conventions (camelCase, exported names)

### 2. Memory & Performance
- **Memory Management**: Proper allocation and garbage collection
- **Pointers vs Values**: Appropriate use of pointers
- **Slices and Maps**: Efficient usage patterns
- **String Building**: Efficient string concatenation
- **Buffer Pooling**: Object pooling for performance

### 3. Concurrency
- **Goroutines**: Proper lifecycle management
- **Channels**: Correct channel usage patterns
- **Mutex**: Appropriate mutex usage
- **Select Statements**: Proper select usage
- **Context**: Context propagation for cancellation

### 4. Error Handling
- **Error Wrapping**: Proper error wrapping with fmt.Errorf
- **Error Types**: Custom error types when appropriate
- **Panic Recovery**: Proper panic recovery patterns
- **Validation**: Input validation and error returns
- **Logging**: Structured logging practices

### 5. Testing & Quality
- **Table-driven Tests**: Go testing patterns
- **Benchmarking**: Performance benchmarks
- **Test Coverage**: Adequate test coverage
- **Mock Interfaces**: Interface-based testing
- **Integration Tests**: End-to-end testing

### 6. Build & Dependency Management
- **Go Modules**: Proper module management
- **Build Tags**: Conditional compilation
- **Cross-compilation**: Platform-specific builds
- **Vendor Management**: Dependency versioning
- **Static Analysis**: Go vet, staticcheck

## Common Go Issues to Fix

### Error Handling
```go
// Bad
func processFile(filename string) string {
    data, _ := ioutil.ReadFile(filename)
    return strings.ToUpper(string(data))
}

// Good
func processFile(filename string) (string, error) {
    data, err := ioutil.ReadFile(filename)
    if err != nil {
        return "", fmt.Errorf("failed to read file %s: %w", filename, err)
    }
    return strings.ToUpper(string(data)), nil
}
```

### Goroutine Safety
```go
// Bad
func processItems(items []Item) {
    for _, item := range items {
        go func() {
            process(item)  // Race condition!
        }()
    }
}

// Good
func processItems(items []Item) {
    for _, item := range items {
        item := item  // Create new variable
        go func() {
            process(item)
        }()
    }
}
```

### Resource Management
```go
// Bad
func readConfig() string {
    file, _ := os.Open("config.json")
    defer file.Close()
    data, _ := ioutil.ReadAll(file)
    return string(data)
}

// Good
func readConfig() (string, error) {
    file, err := os.Open("config.json")
    if err != nil {
        return "", fmt.Errorf("failed to open config: %w", err)
    }
    defer file.Close()

    data, err := ioutil.ReadAll(file)
    if err != nil {
        return "", fmt.Errorf("failed to read config: %w", err)
    }

    return string(data), nil
}
```

### Interface Design
```go
// Bad - Too broad
type Processor interface {
    Process()
    Save()
    Load()
    Validate()
}

// Good - Small, focused
type Processor interface {
    Process(ctx context.Context) error
}

type Validator interface {
    Validate() error
}

type Persister interface {
    Save(ctx context.Context) error
    Load(ctx context.Context) error
}
```

### String Building
```go
// Bad
func buildMessage(parts []string) string {
    var result string
    for _, part := range parts {
        result += part + " "
    }
    return result
}

// Good
func buildMessage(parts []string) string {
    var b strings.Builder
    for i, part := range parts {
        if i > 0 {
            b.WriteString(" ")
        }
        b.WriteString(part)
    }
    return b.String()
}
```

## Review Checklist
- [ ] All errors are handled explicitly
- [ ] No race conditions in concurrent code
- [ ] Proper use of context for cancellation
- [ ] Interface design follows Go idioms
- [ ] Memory management is efficient
- [ ] Package structure is clear
- [ ] Naming follows Go conventions
- [ ] Tests are comprehensive and use table-driven patterns
- [ ] No panics in production code (except unrecoverable errors)
- [ ] Proper logging with structured format
- [ ] Dependencies are managed with Go modules
- [ ] Code passes go vet and staticcheck

## Tooling for Go Quality
- **Linting**: golint, golangci-lint
- **Static Analysis**: go vet, staticcheck, ineffassign
- **Formatting**: gofmt, goimports
- **Testing**: go test, testing package
- **Race Detection**: go test -race
- **Memory Analysis**: go test -memprofile
- **Dependency Analysis**: go mod why, go list

## Performance Considerations
- **Profiling**: Use pprof for performance analysis
- **Benchmarking**: Write benchmarks for critical paths
- **Memory Usage**: Monitor memory allocations
- **Goroutine Leaks**: Ensure proper goroutine cleanup
- **Channel Buffering**: Appropriate channel buffer sizes

Please fix any Go-specific issues found in the code and ensure all Go best practices and idioms are followed.