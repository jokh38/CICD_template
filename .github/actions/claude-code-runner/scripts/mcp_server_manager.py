#!/usr/bin/env python3
"""
MCP Server Manager for Claude Code Integration

This module provides MCP (Model Context Protocol) server management capabilities
to extend Claude Code's functionality with various tools and services.
"""

import json
import subprocess
import asyncio
import sys
import os
import logging
from pathlib import Path
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass
from enum import Enum


class MCPServerType(Enum):
    """Supported MCP server types"""
    GIT = "git"
    GITHUB = "github"
    FILESYSTEM = "filesystem"
    DATABASE = "database"
    DOCKER = "docker"
    KUBERNETES = "kubernetes"
    CUSTOM = "custom"


@dataclass
class MCPServerConfig:
    """Configuration for an MCP server"""
    name: str
    server_type: MCPServerType
    command: str
    args: List[str]
    env: Dict[str, str]
    enabled: bool = True
    timeout: int = 30
    retry_count: int = 3


class MCPServerManager:
    """Manages MCP servers for Claude Code integration"""

    def __init__(self, config_file: Optional[Path] = None):
        self.config_file = config_file or Path(".github/claude/mcp_config.json")
        self.servers: Dict[str, MCPServerConfig] = {}
        self.running_servers: Dict[str, subprocess.Popen] = {}
        self.logger = self._setup_logging()

        # Load configuration
        self._load_config()

    def _setup_logging(self) -> logging.Logger:
        """Setup logging configuration"""
        logger = logging.getLogger("mcp_manager")
        logger.setLevel(logging.INFO)

        if not logger.handlers:
            handler = logging.StreamHandler(sys.stderr)
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        return logger

    def _load_config(self):
        """Load MCP server configuration from file"""
        if not self.config_file.exists():
            self.logger.info(f"Config file {self.config_file} not found, creating default configuration")
            self._create_default_config()
            return

        try:
            with open(self.config_file, 'r') as f:
                config_data = json.load(f)

            for server_name, server_data in config_data.get('servers', {}).items():
                try:
                    server_config = MCPServerConfig(
                        name=server_name,
                        server_type=MCPServerType(server_data['server_type']),
                        command=server_data['command'],
                        args=server_data.get('args', []),
                        env=server_data.get('env', {}),
                        enabled=server_data.get('enabled', True),
                        timeout=server_data.get('timeout', 30),
                        retry_count=server_data.get('retry_count', 3)
                    )
                    self.servers[server_name] = server_config
                except (KeyError, ValueError) as e:
                    self.logger.error(f"Invalid configuration for server {server_name}: {e}")

        except (json.JSONDecodeError, IOError) as e:
            self.logger.error(f"Failed to load MCP config: {e}")
            self._create_default_config()

    def _create_default_config(self):
        """Create default MCP server configuration"""
        default_config = {
            "servers": {
                "git": {
                    "server_type": "git",
                    "command": "npx",
                    "args": ["@modelcontextprotocol/server-git"],
                    "env": {"GIT_DIR": os.getcwd()},
                    "enabled": True,
                    "timeout": 30,
                    "retry_count": 3
                },
                "github": {
                    "server_type": "github",
                    "command": "npx",
                    "args": ["@modelcontextprotocol/server-github"],
                    "env": {"GITHUB_TOKEN": "${GITHUB_TOKEN}"},
                    "enabled": True,
                    "timeout": 30,
                    "retry_count": 3
                },
                "filesystem": {
                    "server_type": "filesystem",
                    "command": "npx",
                    "args": ["@modelcontextprotocol/server-filesystem"],
                    "env": {"FILESYSTEM_ROOT": os.getcwd()},
                    "enabled": True,
                    "timeout": 30,
                    "retry_count": 3
                }
            }
        }

        # Ensure config directory exists
        self.config_file.parent.mkdir(parents=True, exist_ok=True)

        try:
            with open(self.config_file, 'w') as f:
                json.dump(default_config, f, indent=2)
            self.logger.info(f"Created default MCP configuration at {self.config_file}")
        except IOError as e:
            self.logger.error(f"Failed to create default config: {e}")

    def add_server(self, server_config: MCPServerConfig):
        """Add a new MCP server configuration"""
        self.servers[server_config.name] = server_config
        self._save_config()

    def remove_server(self, server_name: str) -> bool:
        """Remove an MCP server configuration"""
        if server_name in self.servers:
            # Stop server if running
            self.stop_server(server_name)
            del self.servers[server_name]
            self._save_config()
            return True
        return False

    def _save_config(self):
        """Save current configuration to file"""
        config_data = {
            "servers": {}
        }

        for name, server in self.servers.items():
            config_data["servers"][name] = {
                "server_type": server.server_type.value,
                "command": server.command,
                "args": server.args,
                "env": server.env,
                "enabled": server.enabled,
                "timeout": server.timeout,
                "retry_count": server.retry_count
            }

        try:
            with open(self.config_file, 'w') as f:
                json.dump(config_data, f, indent=2)
        except IOError as e:
            self.logger.error(f"Failed to save config: {e}")

    async def start_server(self, server_name: str) -> bool:
        """Start an MCP server"""
        if server_name not in self.servers:
            self.logger.error(f"Server {server_name} not found in configuration")
            return False

        if server_name in self.running_servers:
            self.logger.warning(f"Server {server_name} is already running")
            return True

        server_config = self.servers[server_name]

        if not server_config.enabled:
            self.logger.info(f"Server {server_name} is disabled, skipping")
            return False

        # Prepare environment variables
        env = os.environ.copy()
        for key, value in server_config.env.items():
            # Expand environment variable references
            if value.startswith("${") and value.endswith("}"):
                env_var = value[2:-1]
                env[key] = os.environ.get(env_var, "")
            else:
                env[key] = value

        try:
            process = subprocess.Popen(
                [server_config.command] + server_config.args,
                env=env,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                stdin=subprocess.PIPE
            )

            # Give the server a moment to start
            await asyncio.sleep(2)

            if process.poll() is None:  # Process is still running
                self.running_servers[server_name] = process
                self.logger.info(f"Started MCP server: {server_name}")
                return True
            else:
                # Server failed to start
                stdout, stderr = process.communicate()
                self.logger.error(f"Failed to start server {server_name}: {stderr.decode()}")
                return False

        except Exception as e:
            self.logger.error(f"Error starting server {server_name}: {e}")
            return False

    def stop_server(self, server_name: str) -> bool:
        """Stop an MCP server"""
        if server_name not in self.running_servers:
            return True

        process = self.running_servers[server_name]

        try:
            process.terminate()
            process.wait(timeout=5)
            self.logger.info(f"Stopped MCP server: {server_name}")
        except subprocess.TimeoutExpired:
            process.kill()
            self.logger.warning(f"Forcefully killed MCP server: {server_name}")
        except Exception as e:
            self.logger.error(f"Error stopping server {server_name}: {e}")

        del self.running_servers[server_name]
        return True

    async def start_all_enabled_servers(self) -> Dict[str, bool]:
        """Start all enabled MCP servers"""
        results = {}

        for server_name in self.servers:
            if self.servers[server_name].enabled:
                results[server_name] = await self.start_server(server_name)
                # Small delay between starting servers
                await asyncio.sleep(1)

        return results

    def stop_all_servers(self):
        """Stop all running MCP servers"""
        for server_name in list(self.running_servers.keys()):
            self.stop_server(server_name)

    async def check_server_health(self, server_name: str) -> Tuple[bool, str]:
        """Check if a server is healthy and responsive"""
        if server_name not in self.running_servers:
            return False, "Server not running"

        process = self.running_servers[server_name]

        if process.poll() is not None:
            return False, f"Process terminated with code {process.returncode}"

        # For now, just check if process is alive
        # In a real implementation, you might want to send a health check ping
        return True, "Server is running"

    async def get_server_status(self) -> Dict[str, Dict[str, Any]]:
        """Get status of all configured servers"""
        status = {}

        for server_name, server_config in self.servers.items():
            is_running = server_name in self.running_servers
            health_ok, health_message = await self.check_server_health(server_name) if is_running else (False, "Not running")

            status[server_name] = {
                "configured": True,
                "enabled": server_config.enabled,
                "running": is_running,
                "healthy": health_ok,
                "health_message": health_message,
                "server_type": server_config.server_type.value,
                "command": f"{server_config.command} {' '.join(server_config.args)}"
            }

        return status

    def get_available_tools(self) -> Dict[str, List[str]]:
        """Get available tools from each server type"""
        # This is a static mapping based on known MCP server capabilities
        # In a real implementation, you might query the servers dynamically
        tools = {
            MCPServerType.GIT.value: [
                "git_status", "git_diff", "git_log", "git_blame",
                "git_add", "git_commit", "git_push", "git_pull"
            ],
            MCPServerType.GITHUB.value: [
                "create_issue", "update_issue", "create_pr", "merge_pr",
                "list_issues", "list_prs", "add_comment", "get_file"
            ],
            MCPServerType.FILESYSTEM.value: [
                "read_file", "write_file", "list_directory", "search_files",
                "get_file_info", "create_directory", "delete_file"
            ],
            MCPServerType.DATABASE.value: [
                "execute_query", "get_schema", "list_tables", "describe_table"
            ],
            MCPServerType.DOCKER.value: [
                "list_containers", "run_container", "stop_container", "get_logs",
                "build_image", "push_image", "pull_image"
            ],
            MCPServerType.KUBERNETES.value: [
                "get_pods", "get_services", "deploy_app", "scale_deployment",
                "get_logs", "exec_command", "apply_manifest"
            ]
        }

        return {name: tools.get(server.server_type.value, [])
                for name, server in self.servers.items()
                if server.enabled}

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        self.stop_all_servers()


async def main():
    """Main entry point for CLI usage"""
    import argparse

    parser = argparse.ArgumentParser(description="MCP Server Manager")
    parser.add_argument("--config", type=Path, help="Path to config file")
    parser.add_argument("action", choices=["start", "stop", "status", "tools"],
                       help="Action to perform")
    parser.add_argument("--server", help="Specific server name (optional)")

    args = parser.parse_args()

    manager = MCPServerManager(args.config)

    try:
        if args.action == "start":
            if args.server:
                success = await manager.start_server(args.server)
                print(f"Started {args.server}: {success}")
            else:
                results = await manager.start_all_enabled_servers()
                for server, success in results.items():
                    print(f"Started {server}: {success}")

        elif args.action == "stop":
            if args.server:
                success = manager.stop_server(args.server)
                print(f"Stopped {args.server}: {success}")
            else:
                manager.stop_all_servers()
                print("Stopped all servers")

        elif args.action == "status":
            status = await manager.get_server_status()
            print(json.dumps(status, indent=2))

        elif args.action == "tools":
            tools = manager.get_available_tools()
            print(json.dumps(tools, indent=2))

    finally:
        manager.stop_all_servers()


if __name__ == "__main__":
    asyncio.run(main())