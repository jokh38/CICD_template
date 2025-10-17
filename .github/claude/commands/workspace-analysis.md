# Workspace Analysis Command (Serena-Powered)

## Description
**Serena performs autonomous workspace optimization and management** through comprehensive multi-project analysis, dependency mapping, and intelligent workspace organization. Uses Serena's advanced capabilities to discover, analyze, optimize, and maintain entire workspace structure automatically.

## Serena Workspace Optimization

### Autonomous Workspace Management
- **Discover**: Automatically identify all projects and their relationships
- **Analyze**: Deep analysis of cross-project dependencies and integration points
- **Optimize**: Improve project organization, structure, and tooling consistency
- **Synchronize**: Keep projects compatible and eliminate redundancy
- **Automate**: Eliminate duplicate configurations and streamline processes

### Advanced Workspace Features
- **Cross-Project Refactoring**: Safe refactoring across project boundaries
- **Shared Dependency Management**: Optimize dependencies across workspace
- **Unified Tooling**: Standardize tools, configurations, and workflows
- **Integration Testing**: Auto-generate cross-project integration tests
- **Workspace Health Monitoring**: Continuous monitoring and optimization
- **Resource Optimization**: Optimize build times and resource usage

## Usage
/workspace-analysis [scope] [options]

## Parameters
- scope: Analysis scope (single-project, multi-project, full-workspace)
- --focus: Areas to focus on (dependencies, tooling, integration, performance, all)
- --optimize: Automatically apply optimizations (default: true)
- --synchronize: Synchronize configurations across projects (default: false)
- --generate-tests: Generate cross-project integration tests (default: false)
- --create-docs: Generate workspace documentation (default: true)

## Serena Tools Required
- **filesystem**: read_file, list_directory, search_files, write_file
- **shell**: execute_shell_command (for build and test operations)
- **git**: git_status, git_log, git_diff (for change analysis across projects)
- **github**: create_issue, create_pull_request (for workspace improvements)
- **web**: WebFetch (for workspace optimization best practices)

## Serena Automation Workflow

### Phase 1: Workspace Discovery
```bash
# Serena discovers and maps entire workspace
/workspace-analysis full-workspace --focus=all
```
**Serena will:**
1. **Project Discovery**: Identify all projects and their types/languages
2. **Structure Mapping**: Map workspace structure and organization
3. **Dependency Analysis**: Analyze inter-project dependencies and relationships
4. **Tooling Inventory**: Catalog build systems, tools, and configurations
5. **Integration Points**: Identify potential integration opportunities
6. **Redundancy Detection**: Find duplicate configurations and efforts

### Phase 2: Analysis and Optimization Planning
```bash
# Serena analyzes workspace and creates optimization plan
/workspace-analysis multi-project --focus=dependencies,tooling --create-docs
```
**Serena will:**
1. **Dependency Optimization**: Identify shared dependencies and optimization opportunities
2. **Tooling Standardization**: Recommend tool and configuration standardization
3. **Build Optimization**: Analyze and optimize build processes across projects
4. **Integration Opportunities**: Identify areas for better project integration
5. **Performance Analysis**: Identify bottlenecks and optimization opportunities
6. **Documentation Generation**: Create comprehensive workspace documentation

### Phase 3: Automated Optimization
```bash
# Serena implements workspace optimizations
/workspace-analysis full-workspace --optimize --synchronize --generate-tests
```
**Serena will:**
1. **Configuration Synchronization**: Standardize configurations across projects
2. **Dependency Optimization**: Optimize shared dependencies and versions
3. **Build Improvement**: Implement build optimizations and caching
4. **Integration Testing**: Create cross-project integration test suites
5. **Documentation Updates**: Update workspace and project documentation
6. **Monitoring Setup**: Implement workspace health monitoring

## Examples

### Complete Workspace Optimization
```bash
/workspace-analysis full-workspace --focus=all --optimize --synchronize --generate-tests
```
**Serena delivers:**
- Complete workspace analysis and optimization
- Standardized tooling and configurations
- Optimized dependencies and build processes
- Cross-project integration test suite
- Comprehensive workspace documentation
- Health monitoring and alerting setup

### Multi-Project Dependency Optimization
```bash
/workspace-analysis multi-project --focus=dependencies --optimize
```
**Serena delivers:**
- Shared dependency identification and optimization
- Version conflict resolution
- Dependency security auditing and updates
- Bundle size optimization
- License compatibility analysis

### Tooling Standardization
```bash
/workspace-analysis full-workspace --focus=tooling --synchronize
```
**Serena delivers:**
- Unified build system configurations
- Standardized linting and formatting rules
- Consistent CI/CD pipeline configurations
- Shared development environment setup
- Standardized testing frameworks and configurations

## Expected Serena Output

### Workspace Analysis
- **Project Inventory**: Complete catalog of all projects with metadata
- **Dependency Graphs**: Visual representation of cross-project dependencies
- **Architecture Overview**: High-level workspace architecture and relationships
- **Tooling Matrix**: Analysis of tools, versions, and configurations across projects
- **Integration Map**: Potential integration points and opportunities
- **Redundancy Report**: Identification of duplicate efforts and configurations

### Optimization Recommendations
- **Dependency Optimization**: Shared dependency opportunities and version alignment
- **Tooling Standardization**: Recommendations for tool and configuration consistency
- **Build Performance**: Build optimization suggestions and caching strategies
- **Integration Strategy**: Plan for better project integration and communication
- **Resource Efficiency**: Resource usage optimization and cost reduction opportunities
- **Workflow Automation**: Automation opportunities and process improvements

### Automated Implementation
- **Configuration Synchronization**: Standardized configurations across all projects
- **Dependency Management**: Optimized and secured dependencies
- **Build Optimization**: Improved build performance and caching
- **Integration Infrastructure**: Cross-project integration testing and monitoring
- **Documentation Suite**: Complete workspace and project documentation
- **Monitoring Dashboard**: Workspace health and performance monitoring

## Cross-Project Integration Features

### Unified Development Environment
- **Shared Configuration**: Common development environment setup
- **Standardized Tools**: Consistent tool versions and configurations
- **Unified Scripts**: Shared build, test, and deployment scripts
- **Common Templates**: Standardized project templates and scaffolding

### Integration Testing Infrastructure
- **Cross-Project Tests**: Integration tests spanning multiple projects
- **API Contract Testing**: Automated API contract validation
- **End-to-End Testing**: Complete workflow testing across projects
- **Performance Testing**: Cross-project performance impact analysis

### Dependency Management
- **Shared Libraries**: Identification and creation of shared libraries
- **Version Alignment**: Coordinated version management across projects
- **Security Updates**: Coordinated security patch management
- **License Compliance**: Cross-project license compatibility management

## Integration with Development Workflow

### Multi-Project Development
- Serena provides guidance for cross-project feature development
- Identifies impact of changes across dependent projects
- Coordinates releases and version management
- Maintains API compatibility across projects

### Continuous Integration Enhancement
- Serena optimizes CI/CD pipelines for multi-project builds
- Implements intelligent build caching and parallelization
- Coordinates testing across project boundaries
- Provides unified reporting and monitoring

### Workspace Governance
- Serena maintains consistency across projects
- Enforces coding standards and best practices
- Monitors workspace health and performance
- Provides recommendations for continuous improvement