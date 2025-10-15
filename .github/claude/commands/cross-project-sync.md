# Cross-Project Synchronization Command

## Description
Synchronizes common configurations, dependencies, and patterns across multiple projects in the workspace. Ensures consistency while respecting project-specific requirements.

## Usage
/cross-project-sync [target-projects...]

## Parameters
- target-projects: Optional list of specific projects to sync (comma-separated)
- --dry-run: Preview changes without applying them
- --config-types: Types of configs to sync (eslint, prettier, ci-cd, dependencies)

## MCP Tools Required
- filesystem: read_file, write_file, list_directory
- git: git_status, git_add, git_commit

## Examples
/cross-project-sync
/cross-project-sync myproject1,myproject2 --config-types=dependencies,ci-cd
/cross-project-sync --dry-run

## Expected Output
- Synchronization plan
- Changes applied per project
- Validation results
- Rollback information if needed