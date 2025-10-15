## Phase 6: MCP Server Integration (Week 3, Days 4-7)

### Objective
Integrate Model Context Protocol (MCP) servers for extended functionality.

### 6.1 MCP Configuration

**Task**: Set up MCP servers for Git and GitHub integration

**File**: `.github/claude/mcp-config.json`

```json
{
  "mcpServers": {
    "git": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-git"],
      "env": {
        "GIT_DIR": "{{PROJECT_ROOT}}/.git"
      },
      "description": "Git operations for commit history, diffs, and branch management"
    },
    "github": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "env": {
        "GITHUB_TOKEN": "{{GITHUB_TOKEN}}"
      },
      "description": "GitHub API access for issues, PRs, and repository data"
    },
    "filesystem": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-filesystem", "{{PROJECT_ROOT}}"],
      "description": "Read project files with permissions"
    }
  },
  "settings": {
    "timeout": 30000,
    "retries": 2
  }
}
```

**Implementation Steps**:
1. Create MCP configuration template
2. Add environment variable substitution
3. Document MCP server capabilities
4. Test MCP server connectivity

**Deliverables**:
- [ ] MCP configuration template
- [ ] Environment setup documentation
- [ ] Connection tests

### 6.2 MCP Integration in Runner

**Task**: Integrate MCP servers into Claude Code runner

**File**: `.github/actions/claude-code-runner/scripts/mcp_integration.py`

```python
"""
MCP Server integration for Claude Code workflows.
"""

import json
import os
from pathlib import Path
from typing import Dict, Optional


class MCPManager:
    """Manage MCP server configuration for Claude Code"""

    def __init__(self, config_path: Path, project_root: Path):
        self.config_path = config_path
        self.project_root = project_root
        self.config = self._load_config()

    def _load_config(self) -> Dict:
        """Load MCP configuration from file"""
        if not self.config_path.exists():
            return {"mcpServers": {}}

        with open(self.config_path) as f:
            return json.load(f)

    def setup_servers(self, github_token: Optional[str] = None) -> Dict:
        """
        Set up MCP servers with environment variables.

        Args:
            github_token: GitHub token for API access

        Returns:
            Configured MCP server dictionary
        """
        servers = self.config.get("mcpServers", {})

        # Substitute environment variables
        for server_name, server_config in servers.items():
            if "env" in server_config:
                for key, value in server_config["env"].items():
                    # Replace template variables
                    if value == "{{PROJECT_ROOT}}":
                        server_config["env"][key] = str(self.project_root)
                    elif value == "{{GITHUB_TOKEN}}":
                        if github_token:
                            server_config["env"][key] = github_token
                        else:
                            # Try to get from environment
                            server_config["env"][key] = os.getenv("GITHUB_TOKEN", "")

        return servers

    def get_server_config_for_claude(self) -> str:
        """
        Generate Claude Code compatible MCP config.

        Returns:
            JSON string for Claude Code --mcp-config
        """
        servers = self.setup_servers()
        return json.dumps({"mcpServers": servers}, indent=2)

    def write_temp_config(self, output_path: Path, github_token: Optional[str] = None):
        """Write temporary MCP config file"""
        servers = self.setup_servers(github_token)
        config = {
            "mcpServers": servers,
            **self.config.get("settings", {})
        }

        with open(output_path, 'w') as f:
            json.dump(config, f, indent=2)
```

**Implementation Steps**:
1. Create MCP manager class
2. Implement config loading and template substitution
3. Add Claude Code integration
4. Create temporary config file generation
5. Write tests

**Deliverables**:
- [ ] `mcp_integration.py` with MCP management
- [ ] Template variable substitution
- [ ] Claude Code integration
- [ ] Unit tests

### 6.3 Update Runner to Use MCP

**Task**: Modify main runner to include MCP configuration

**File**: `.github/actions/claude-code-runner/scripts/run_claude_code.py`

**Updates**:
```python
# Add to ClaudeCodeRunner class

from mcp_integration import MCPManager

class ClaudeCodeRunner:
    def __init__(self, project_root: Path, context_file: Path):
        self.project_root = project_root
        self.context_file = context_file
        self.max_retries = 3
        self.max_tokens = 200000

        # Initialize MCP manager
        mcp_config_path = project_root / ".github" / "claude" / "mcp-config.json"
        self.mcp_manager = MCPManager(mcp_config_path, project_root)

    async def run_claude_command(
        self,
        prompt: str,
        task_type: str,
        options: Optional[Dict] = None
    ) -> Dict[str, Any]:
        """Execute Claude Code with MCP servers"""

        # Create temporary MCP config
        temp_mcp_config = Path("/tmp/mcp-config.json")
        github_token = os.getenv("GITHUB_TOKEN")
        self.mcp_manager.write_temp_config(temp_mcp_config, github_token)

        cmd = [
            "claude-code",
            "-p",
            "-",
            "--output-format", "stream-json",
            "--max-turns", "1",
            "--mcp-config", str(temp_mcp_config),  # Add MCP config
        ]

        # ... rest of the method
```

**Implementation Steps**:
1. Integrate MCPManager into runner
2. Add temporary config file creation
3. Pass MCP config to Claude Code CLI
4. Test with actual MCP servers
5. Add error handling for MCP failures

**Deliverables**:
- [ ] Updated runner with MCP support
- [ ] MCP error handling
- [ ] Integration tests
