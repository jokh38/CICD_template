# JavaScript/TypeScript-Specific Guidelines

## Code Style & Standards
- **ESLint Compliance**: Follow established linting rules
- **Naming Conventions**: camelCase for variables/functions, PascalCase for classes
- **Semicolons**: Consistent semicolon usage
- **Quotes**: Consistent quote preference (single vs double)
- **Indentation**: Proper indentation and formatting

## TypeScript Best Practices
- **Type Safety**: Strong typing over any types
- **Interfaces**: Proper interface definitions
- **Generics**: Appropriate use of generics
- **Type Inference**: Let TypeScript infer where appropriate
- **Strict Mode**: Enable strict TypeScript settings

## Asynchronous Programming
- **Promise Handling**: Proper promise chains and async/await
- **Error Handling**: Try/catch for async operations
- **Race Conditions**: Avoid race conditions in async code
- **Callback Hell**: Eliminate callback nesting
- **Parallel Execution**: Proper use of Promise.all()

## Performance & Optimization
- **Bundle Size**: Optimize import sizes and tree shaking
- **Memory Leaks**: Proper cleanup of event listeners and timers
- **Debouncing/Throttling**: Optimize frequent operations
- **Lazy Loading**: Code splitting and lazy loading
- **Caching**: Appropriate caching strategies

## Security Considerations
- **XSS Prevention**: Proper input sanitization
- **CSRF Protection**: Implement CSRF tokens
- **Data Validation**: Client and server-side validation
- **Sensitive Data**: Avoid exposing secrets in frontend
- **Content Security Policy**: Implement CSP headers

## Testing & Quality
- **Unit Tests**: Comprehensive test coverage
- **Integration Tests**: API and component integration
- **Mocking**: Proper mocking of dependencies
- **Test Structure**: Well-organized test suites
- **Coverage**: Maintain high test coverage

## Tooling
- **Linting**: ESLint, TSLint
- **Formatting**: Prettier
- **Type Checking**: TypeScript compiler
- **Testing**: Jest, Mocha, Cypress
- **Bundling**: Webpack, Vite, Rollup
- **Security**: npm audit, Snyk

## Common JavaScript Patterns

### Bad vs Good Examples
```javascript
// Bad
function fetchData() {
  fetch('/api/data')
    .then(response => response.json())
    .then(data => console.log(data))
    .catch(error => console.error(error));
}

// Good
async function fetchData() {
  try {
    const response = await fetch('/api/data');
    const data = await response.json();
    console.log(data);
  } catch (error) {
    console.error('Failed to fetch data:', error);
  }
}
```

```javascript
// Bad
var name = 'John';
var age = 30;

// Good
const name = 'John';
let age = 30;
```

```javascript
// Bad
var results = [];
for (var i = 0; i < items.length; i++) {
  if (items[i].active) {
    results.push(items[i].value);
  }
}

// Good
const results = items
  .filter(item => item.active)
  .map(item => item.value);
```

```typescript
// Bad
function processUserData(data: any) {
  return data.name.toUpperCase();
}

// Good
interface UserData {
  name: string;
  email: string;
  age?: number;
}

function processUserData(data: UserData): string {
  return data.name.toUpperCase();
}
```