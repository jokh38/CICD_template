# Dependency Audit Command (Serena-Powered)

## Description
**Serena provides autonomous dependency management and security** through comprehensive dependency analysis, vulnerability detection, automated updates, and intelligent conflict resolution. Uses Serena's advanced capabilities to audit, fix, and maintain project dependencies automatically.

## Serena Autonomous Dependency Management

### Self-Managing Dependencies
- **Audit**: Comprehensive security and compatibility analysis across all dependencies
- **Update**: Automatically apply safe updates and security patches
- **Resolve**: Intelligent conflict resolution and version optimization
- **Validate**: Ensure updates don't break functionality or violate constraints
- **Document**: Maintain comprehensive dependency documentation and changelogs

### Advanced Dependency Features
- **Security Auto-Fix**: Automatically apply security patches and vulnerability fixes
- **Version Optimization**: Choose optimal versions based on compatibility and performance
- **License Compliance**: Ensure license compatibility across all dependencies
- **Performance Optimization**: Select packages based on performance metrics and bundle size
- **Dependency Health Monitoring**: Continuous monitoring and proactive maintenance
- **Cross-Project Coordination**: Coordinate dependency updates across multiple projects

## Usage
/dependency-audit [scope] [options]

## Parameters
- scope: Audit scope (single-project, multi-project, full-workspace)
- --projects: Specific projects to analyze (comma-separated, default: all)
- --severity: Minimum severity level (low, medium, high, critical)
- --fix: Automatically apply safe updates (default: true)
- --security-focus: Prioritize security vulnerabilities (default: true)
- --performance-optimize: Optimize for performance and bundle size (default: false)
- --license-check: Perform license compatibility analysis (default: true)
- --report-format: Output format (json, markdown, csv, html)
- --create-pr: Create pull requests for updates (default: true)
- --rollback: Enable rollback capability (default: true)

## Serena Tools Required
- **filesystem**: read_file, search_files, write_file
- **shell**: execute_shell_command (for package installation and testing)
- **git**: git_diff, git_status, git_log (for change tracking and validation)
- **github**: create_issue, create_pull_request (for update tracking and review)
- **web**: WebFetch (for vulnerability databases and security research)

## Serena Automation Workflow

### Phase 1: Comprehensive Dependency Analysis
```bash
# Serena performs deep dependency audit
/dependency-audit full-workspace --severity=medium --license-check
```
**Serena will:**
1. **Dependency Discovery**: Catalog all dependencies across projects
2. **Vulnerability Scanning**: Check against security vulnerability databases
3. **Version Analysis**: Identify outdated packages and update opportunities
4. **License Analysis**: Analyze license compatibility and compliance
5. **Dependency Graph Mapping**: Map dependency relationships and conflicts
6. **Performance Impact**: Analyze performance and bundle size impact

### Phase 2: Intelligent Update Planning
```bash
# Serena creates intelligent update strategy
/dependency-audit multi-project --fix --security-focus --performance-optimize
```
**Serena will:**
1. **Risk Assessment**: Evaluate risks and benefits of each update
2. **Compatibility Analysis**: Ensure compatibility across project dependencies
3. **Update Sequencing**: Plan optimal order for applying updates
4. **Rollback Strategy**: Prepare rollback plans for each update
5. **Testing Strategy**: Define validation tests for each update
6. **Documentation Planning**: Plan changelog and documentation updates

### Phase 3: Automated Safe Updates
```bash
# Serena applies updates safely and validates
/dependency-audit --fix --create-pr --rollback
```
**Serena will:**
1. **Incremental Updates**: Apply updates in safe, incremental steps
2. **Automated Testing**: Run comprehensive tests after each update
3. **Validation**: Ensure functionality and performance are maintained
4. **Rollback if Needed**: Automatically rollback if issues arise
5. **Documentation**: Update changelogs and dependency documentation
6. **PR Creation**: Create pull requests with detailed update information

## Examples

### Complete Dependency Management
```bash
/dependency-audit full-workspace --fix --security-focus --performance-optimize --create-pr
```
**Serena delivers:**
- Comprehensive dependency audit and vulnerability assessment
- Automated security patches and performance optimizations
- Safe update application with rollback capability
- Detailed changelogs and documentation updates
- Pull requests with comprehensive update information
- Cross-project dependency coordination and optimization

### Security-Focused Audit
```bash
/dependency-audit --severity=high --security-focus --fix --create-pr
```
**Serena delivers:**
- Critical and high-severity vulnerability detection
- Automated security patch application
- Security assessment reports and recommendations
- Emergency security update capabilities
- Compliance and security documentation updates

### Performance Optimization
```bash
/dependency-audit --performance-optimize --fix --report-format=json
```
**Serena delivers:**
- Performance impact analysis of dependencies
- Bundle size optimization and tree-shaking improvements
- Alternative package recommendations for better performance
- Performance benchmarking and monitoring setup
- Optimization tracking and reporting

## Expected Serena Output

### Security Analysis
- **Vulnerability Report**: Comprehensive security vulnerability assessment
- **Patch Recommendations**: Automated patch suggestions and security fixes
- **Risk Assessment**: Security risk analysis and prioritization
- **Compliance Report**: Security compliance and regulatory assessment
- **Monitoring Setup**: Security monitoring and alerting configuration

### Dependency Optimization
- **Update Recommendations**: Intelligent version update suggestions
- **Performance Analysis**: Performance impact and optimization opportunities
- **Bundle Optimization**: Bundle size analysis and optimization recommendations
- **Alternative Analysis**: Alternative package recommendations
- **Cost Analysis**: License cost and compliance analysis

### Automated Updates
- **Safe Updates**: Automated application of safe dependency updates
- **Validation Results**: Comprehensive testing and validation results
- **Rollback Logs**: Detailed rollback information and change tracking
- **Documentation Updates**: Updated changelogs, READMEs, and API docs
- **Pull Requests**: Detailed PRs with update information and testing results

## Advanced Dependency Features

### Security Automation
- **Vulnerability Monitoring**: Continuous monitoring for new vulnerabilities
- **Automated Patching**: Automatic application of security patches
- **Emergency Response**: Rapid response to critical security issues
- **Compliance Reporting**: Automated security compliance reporting
- **Security Testing**: Integration with security testing pipelines

### Performance Intelligence
- **Bundle Analysis**: Detailed bundle size and performance analysis
- **Loading Optimization**: Package loading and initialization optimization
- **Caching Strategy**: Intelligent dependency caching strategies
- **Alternative Selection**: Performance-based package selection
- **Monitoring Integration**: Performance monitoring and alerting

### Cross-Project Coordination
- **Version Synchronization**: Coordinated version management across projects
- **Conflict Resolution**: Intelligent dependency conflict resolution
- **Shared Dependencies**: Optimization of shared dependency usage
- **Release Coordination**: Coordinated release planning and execution
- **Impact Analysis**: Cross-project impact analysis for updates

## Integration with Development Workflow

### Continuous Security Monitoring
- Serena provides continuous dependency security monitoring
- Automated alerts for new vulnerabilities
- Emergency patch deployment capabilities
- Security compliance tracking and reporting

### Automated Maintenance
- Serena handles routine dependency maintenance automatically
- Optimizes dependencies for performance and security
- Maintains comprehensive dependency documentation
- Coordinates updates across development teams

### Development Support
- Serena provides dependency guidance for new features
- Ensures compatibility with existing dependency constraints
- Optimizes dependencies for specific use cases
- Maintains dependency best practices and standards