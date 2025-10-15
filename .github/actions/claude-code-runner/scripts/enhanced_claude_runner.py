#!/usr/bin/env python3
"""
Enhanced Claude Code Runner with MCP Integration

This module extends the basic Claude Code runner with MCP server integration,
providing enhanced capabilities for multi-project support and advanced automation.
"""

import json
import subprocess
import asyncio
import sys
import os
import logging
from pathlib import Path
from typing import Optional, Dict, Any, List, Union
from dataclasses import dataclass
from enum import Enum

from mcp_server_manager import MCPServerManager, MCPServerType
from run_claude_code import ClaudeCodeRunner


class TaskType(Enum):
    """Supported task types for automation"""
    REFACTOR = "refactor"
    FIX_BUG = "fix-bug"
    ADD_FEATURE = "add-feature"
    GENERATE_TESTS = "generate-tests"
    SECURITY_AUDIT = "security-audit"
    OPTIMIZE_PERFORMANCE = "optimize-performance"
    CODE_REVIEW = "code-review"
    MULTI_LANGUAGE_ANALYSIS = "multi-language-analysis"


@dataclass
class ProjectContext:
    """Context information for a project"""
    name: str
    path: Path
    language: str
    dependencies: List[str]
    build_system: Optional[str] = None
    test_framework: Optional[str] = None


@dataclass
class TaskRequest:
    """A task request for Claude Code"""
    task_type: TaskType
    description: str
    project_context: Optional[ProjectContext] = None
    error_log: Optional[str] = None
    retry_count: int = 0
    additional_dirs: List[str] = None
    timeout: int = 300
    use_mcp: bool = True


class EnhancedClaudeRunner:
    """Enhanced Claude Code runner with MCP integration and multi-project support"""

    def __init__(self, workspace_root: Optional[Path] = None):
        self.workspace_root = workspace_root or Path.cwd()
        self.claude_runner = ClaudeCodeRunner()
        self.mcp_manager = MCPServerManager()
        self.logger = self._setup_logging()
        self.projects: Dict[str, ProjectContext] = {}

        # Discover projects
        self._discover_projects()

    def _setup_logging(self) -> logging.Logger:
        """Setup logging configuration"""
        logger = logging.getLogger("enhanced_claude")
        logger.setLevel(logging.INFO)

        if not logger.handlers:
            handler = logging.StreamHandler(sys.stderr)
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        return logger

    def _discover_projects(self):
        """Discover projects in the workspace"""
        project_indicators = {
            "python": ["pyproject.toml", "requirements.txt", "setup.py", "__init__.py"],
            "javascript": ["package.json", "package-lock.json", "yarn.lock"],
            "typescript": ["tsconfig.json", "package.json"],
            "cpp": ["CMakeLists.txt", "Makefile", "configure.ac"],
            "go": ["go.mod", "go.sum"],
            "rust": ["Cargo.toml", "Cargo.lock"],
            "java": ["pom.xml", "build.gradle", "build.gradle.kts"],
            "ruby": ["Gemfile", "Rakefile"],
            "php": ["composer.json", "composer.lock"]
        }

        for root, dirs, files in os.walk(self.workspace_root):
            # Skip hidden directories and common build/cache directories
            dirs[:] = [d for d in dirs if not d.startswith('.') and
                      d not in ['node_modules', 'target', 'build', '__pycache__', 'vendor']]

            for language, indicators in project_indicators.items():
                if any(indicator in files for indicator in indicators):
                    project_path = Path(root)
                    project_name = project_path.name

                    # Detect build system and test framework
                    build_system, test_framework = self._detect_build_system(project_path, language)

                    project = ProjectContext(
                        name=project_name,
                        path=project_path,
                        language=language,
                        dependencies=self._extract_dependencies(project_path, language),
                        build_system=build_system,
                        test_framework=test_framework
                    )

                    self.projects[project_name] = project
                    self.logger.info(f"Discovered {language} project: {project_name} at {project_path}")

    def _detect_build_system(self, project_path: Path, language: str) -> tuple[Optional[str], Optional[str]]:
        """Detect build system and test framework for a project"""
        build_systems = {
            "python": {
                "poetry": "pyproject.toml",
                "pip": "requirements.txt",
                "setuptools": "setup.py"
            },
            "javascript": {
                "npm": "package.json",
                "yarn": "yarn.lock"
            },
            "cpp": {
                "cmake": "CMakeLists.txt",
                "make": "Makefile"
            },
            "java": {
                "maven": "pom.xml",
                "gradle": "build.gradle"
            },
            "rust": {
                "cargo": "Cargo.toml"
            }
        }

        test_frameworks = {
            "python": ["pytest", "unittest", "nose2"],
            "javascript": ["jest", "mocha", "jasmine", "vitest"],
            "java": ["junit", "testng"],
            "cpp": ["googletest", "catch2"],
            "rust": ["cargo test"],
            "go": ["go test"]
        }

        # Detect build system
        build_system = None
        if language in build_systems:
            for system, indicator in build_systems[language].items():
                if (project_path / indicator).exists():
                    build_system = system
                    break

        # Detect test framework (simplified - in reality would parse config files)
        test_framework = None
        if language in test_frameworks:
            # Simple detection based on file names and dependencies
            files = [f.name for f in project_path.rglob("*") if f.is_file()]
            for framework in test_frameworks[language]:
                if any(framework.lower() in f.lower() for f in files):
                    test_framework = framework
                    break

        return build_system, test_framework

    def _extract_dependencies(self, project_path: Path, language: str) -> List[str]:
        """Extract dependencies from project configuration"""
        dependencies = []

        if language == "python":
            pyproject_path = project_path / "pyproject.toml"
            if pyproject_path.exists():
                try:
                    import tomllib  # Python 3.11+
                    with open(pyproject_path, 'rb') as f:
                        data = tomllib.load(f)
                        deps = data.get('project', {}).get('dependencies', [])
                        dependencies.extend(deps)
                except ImportError:
                    try:
                        import toml
                        with open(pyproject_path, 'r') as f:
                            data = toml.load(f)
                            deps = data.get('project', {}).get('dependencies', [])
                            dependencies.extend(deps)
                    except ImportError:
                        pass

            requirements_path = project_path / "requirements.txt"
            if requirements_path.exists():
                try:
                    with open(requirements_path, 'r') as f:
                        for line in f:
                            line = line.strip()
                            if line and not line.startswith('#'):
                                dependencies.append(line.split('==')[0].split('>=')[0].split('<=')[0])
                except IOError:
                    pass

        elif language == "javascript":
            package_json = project_path / "package.json"
            if package_json.exists():
                try:
                    with open(package_json, 'r') as f:
                        data = json.load(f)
                        deps = data.get('dependencies', {})
                        dependencies.extend(list(deps.keys()))
                except (IOError, json.JSONDecodeError):
                    pass

        return dependencies

    async def execute_task(self, request: TaskRequest) -> Dict[str, Any]:
        """Execute a task with MCP integration"""
        self.logger.info(f"Executing task: {request.task_type.value} - {request.description}")

        # Start MCP servers if requested
        mcp_tools = {}
        if request.use_mcp:
            try:
                await self.mcp_manager.start_all_enabled_servers()
                mcp_tools = self.mcp_manager.get_available_tools()
                self.logger.info(f"MCP servers started with tools: {list(mcp_tools.keys())}")
            except Exception as e:
                self.logger.warning(f"Failed to start MCP servers: {e}")

        try:
            # Build enhanced prompt with context
            prompt = self._build_enhanced_prompt(request, mcp_tools)

            # Prepare options for Claude Code runner
            options = {
                'timeout': request.timeout,
                'retry_count': request.retry_count
            }

            if request.additional_dirs:
                options['add_dirs'] = request.additional_dirs

            # Add project directories
            if request.project_context:
                options.setdefault('add_dirs', []).append(str(request.project_context.path))

            # Execute Claude Code
            results = await self.claude_runner.run_claude_command(prompt, options)

            return {
                "success": True,
                "results": results,
                "task_type": request.task_type.value,
                "mcp_tools_used": list(mcp_tools.keys()) if mcp_tools else [],
                "project_context": request.project_context.name if request.project_context else None
            }

        except Exception as e:
            self.logger.error(f"Task execution failed: {e}")
            return {
                "success": False,
                "error": str(e),
                "task_type": request.task_type.value,
                "mcp_tools_used": list(mcp_tools.keys()) if mcp_tools else []
            }

        finally:
            # Stop MCP servers
            self.mcp_manager.stop_all_servers()

    def _build_enhanced_prompt(self, request: TaskRequest, mcp_tools: Dict[str, List[str]]) -> str:
        """Build enhanced prompt with project context and MCP capabilities"""
        prompt_parts = []

        # Add task-specific context
        task_templates = {
            TaskType.REFACTOR: "You are performing code refactoring. Focus on improving code structure, readability, and maintainability while preserving functionality.",
            TaskType.FIX_BUG: "You are fixing a bug. Identify the root cause and implement a comprehensive fix with proper testing.",
            TaskType.ADD_FEATURE: "You are adding a new feature. Implement it following best practices and ensure it integrates well with existing code.",
            TaskType.GENERATE_TESTS: "You are generating tests. Create comprehensive test coverage for the specified functionality.",
            TaskType.SECURITY_AUDIT: "You are performing a security audit. Identify potential security vulnerabilities and suggest improvements.",
            TaskType.OPTIMIZE_PERFORMANCE: "You are optimizing performance. Identify bottlenecks and implement optimizations.",
            TaskType.CODE_REVIEW: "You are performing a code review. Provide constructive feedback on code quality, style, and potential improvements.",
            TaskType.MULTI_LANGUAGE_ANALYSIS: "You are analyzing a multi-language project. Consider cross-language interactions and dependencies."
        }

        prompt_parts.append(task_templates.get(request.task_type, "You are working on a development task."))

        # Add project context
        if request.project_context:
            project = request.project_context
            prompt_parts.append(f"""
PROJECT CONTEXT:
- Name: {project.name}
- Language: {project.language}
- Path: {project.path}
- Build System: {project.build_system or 'Unknown'}
- Test Framework: {project.test_framework or 'Unknown'}
- Dependencies: {', '.join(project.dependencies[:10])}{'...' if len(project.dependencies) > 10 else ''}
""")

        # Add MCP tools information
        if mcp_tools:
            available_tools = []
            for server, tools in mcp_tools.items():
                if tools:
                    available_tools.append(f"{server}: {', '.join(tools)}")

            if available_tools:
                prompt_parts.append(f"""
AVAILABLE TOOLS (via MCP servers):
{chr(10).join(available_tools)}

You can use these tools by requesting tool usage in your responses. For example: "I'll use the git_status tool to check the current repository state."
""")

        # Add error log if provided
        if request.error_log:
            prompt_parts.append(f"""
ERROR LOG TO FIX:
{request.error_log}
""")

        # Add retry information
        if request.retry_count > 0:
            prompt_parts.append(f"RETRY ATTEMPT: {request.retry_count + 1}")

        # Add main task description
        prompt_parts.append(f"""
TASK: {request.description}

Please analyze the request and provide a complete solution. If you need to use any of the available tools, clearly indicate which tool you want to use and what you want to accomplish with it.
""")

        return '\n'.join(prompt_parts)

    def get_project_list(self) -> List[Dict[str, Any]]:
        """Get list of discovered projects"""
        return [
            {
                "name": project.name,
                "path": str(project.path),
                "language": project.language,
                "build_system": project.build_system,
                "test_framework": project.test_framework,
                "dependency_count": len(project.dependencies)
            }
            for project in self.projects.values()
        ]

    def get_project_by_name(self, name: str) -> Optional[ProjectContext]:
        """Get project context by name"""
        return self.projects.get(name)

    def get_projects_by_language(self, language: str) -> List[ProjectContext]:
        """Get all projects of a specific language"""
        return [project for project in self.projects.values() if project.language == language]


async def main():
    """Main entry point for CLI usage"""
    import argparse

    parser = argparse.ArgumentParser(description="Enhanced Claude Code Runner with MCP Integration")
    parser.add_argument("--task-type", choices=[t.value for t in TaskType], required=True,
                       help="Type of task to execute")
    parser.add_argument("--description", required=True, help="Task description")
    parser.add_argument("--project", help="Target project name")
    parser.add_argument("--error-log", help="Path to error log file")
    parser.add_argument("--timeout", type=int, default=300, help="Timeout in seconds")
    parser.add_argument("--no-mcp", action="store_true", help="Disable MCP integration")
    parser.add_argument("--retry-count", type=int, default=0, help="Current retry attempt")
    parser.add_argument("--list-projects", action="store_true", help="List discovered projects")
    parser.add_argument("--workspace-root", type=Path, help="Workspace root directory")

    args = parser.parse_args()

    # Initialize enhanced runner
    runner = EnhancedClaudeRunner(args.workspace_root)

    # List projects if requested
    if args.list_projects:
        projects = runner.get_project_list()
        print(json.dumps(projects, indent=2))
        return

    # Get project context
    project_context = None
    if args.project:
        project_context = runner.get_project_by_name(args.project)
        if not project_context:
            print(f"Error: Project '{args.project}' not found", file=sys.stderr)
            sys.exit(1)

    # Read error log if provided
    error_log = None
    if args.error_log:
        try:
            with open(args.error_log, 'r') as f:
                error_log = f.read()
        except Exception as e:
            print(f"Warning: Could not read error log {args.error_log}: {e}", file=sys.stderr)

    # Create task request
    task_request = TaskRequest(
        task_type=TaskType(args.task_type),
        description=args.description,
        project_context=project_context,
        error_log=error_log,
        retry_count=args.retry_count,
        timeout=args.timeout,
        use_mcp=not args.no_mcp
    )

    # Execute task
    try:
        result = await runner.execute_task(task_request)
        print(json.dumps(result, indent=2))

        if not result["success"]:
            sys.exit(1)

    except KeyboardInterrupt:
        print("Task interrupted by user", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Unexpected error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    asyncio.run(main())