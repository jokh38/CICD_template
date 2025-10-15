# Architecture Evolution Command

## Description
Analyzes current codebase architecture and proposes evolutionary improvements. Uses MCP servers to understand project structure, dependencies, and patterns, then provides actionable architectural recommendations.

## Usage
/architecture-evolution [scope] [options]

## Parameters
- scope: Analysis scope (micro, macro, full-system)
- --focus: Specific areas to focus on (performance, scalability, maintainability, security)
- --create-roadmap: Generate implementation roadmap
- --estimate-effort: Provide effort estimates for changes

## MCP Tools Required
- filesystem: read_file, list_directory, search_files
- git: git_log, git_diff (for change patterns)
- github: create_issue (for tracking architecture improvements)

## Examples
/architecture-evolution macro --focus=performance,scalability
/architecture-evolution full-system --create-roadmap
/architecture-evolution micro --focus=maintainability

## Expected Output
- Current architecture analysis
- Technical debt assessment
- Scalability evaluation
- Performance bottlenecks identification
- Security architecture review
- Improvement roadmap with priorities
- Implementation recommendations
- Risk assessment for changes