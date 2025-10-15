# Dependency Audit Command

## Description
Performs comprehensive dependency analysis across all projects in the workspace. Identifies outdated packages, security vulnerabilities, license conflicts, and optimization opportunities using MCP servers for deep analysis.

## Usage
/dependency-audit [options]

## Parameters
- --projects: Specific projects to analyze (comma-separated, default: all)
- --severity: Minimum severity level (low, medium, high, critical)
- --fix: Automatically apply safe updates
- --report-format: Output format (json, markdown, csv)

## MCP Tools Required
- filesystem: read_file, search_files
- git: git_diff, git_status
- github: create_issue, get_file (for vulnerability reporting)

## Examples
/dependency-audit
/dependency-audit --severity=high --fix
/dependency-audit --projects=myproject1,myproject2 --report-format=json

## Expected Output
- Security vulnerability report
- Outdated package recommendations
- License compatibility analysis
- Dependency graph visualization
- Automated update suggestions
- Risk assessment per project