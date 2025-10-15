# Workspace Analysis Command

## Description
Performs comprehensive analysis of the entire workspace, identifying all projects, their dependencies, build systems, and potential integration points. Uses MCP servers to gather detailed information about code structure and project relationships.

## Usage
/workspace-analysis

## MCP Tools Required
- filesystem: read_file, list_directory, search_files
- git: git_status, git_log, git_diff

## Expected Output
- Complete project inventory
- Dependency graphs
- Cross-project relationships
- Architecture recommendations
- Potential integration opportunities