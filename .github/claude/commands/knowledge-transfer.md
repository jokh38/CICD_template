# Knowledge Transfer Command

## Description
Creates comprehensive documentation and knowledge transfer materials based on codebase analysis. Uses MCP servers to understand project structure, patterns, and implementation details to generate developer-friendly documentation.

## Usage
/knowledge-transfer [options]

## Parameters
- --format: Output formats (markdown, html, wiki, api-docs)
- --audience: Target audience (new-dev, senior-dev, architect, ops)
- --sections: Specific sections to generate (architecture, api, deployment, troubleshooting)
- --interactive: Generate interactive tutorials and examples
- --update-existing: Update existing documentation files

## MCP Tools Required
- filesystem: read_file, list_directory, search_files
- git: git_log, git_blame (for code history and ownership)
- github: create_issue, get_file (for documentation issues)

## Examples
/knowledge-transfer --format=markdown,wiki --audience=new-dev
/knowledge-transfer --sections=architecture,api --interactive
/knowledge-transfer --update-existing --audience=architect

## Expected Output
- Architecture documentation
- API reference guides
- Setup and deployment guides
- Troubleshooting playbooks
- Code style guides
- Best practices documentation
- Interactive tutorials
- Developer onboarding materials
- Decision logs (ADRs)
- System diagrams