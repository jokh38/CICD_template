#!/usr/bin/env python3
"""
Multi-Project Manager for Claude Code Integration

This module provides comprehensive multi-project management capabilities,
including project discovery, dependency analysis, cross-project operations,
and workspace orchestration.
"""

import json
import subprocess
import asyncio
import sys
import os
import logging
import hashlib
from pathlib import Path
from typing import Dict, List, Any, Optional, Set, Tuple
from dataclasses import dataclass, asdict
from enum import Enum
from datetime import datetime

from enhanced_claude_runner import ProjectContext, TaskType, TaskRequest, EnhancedClaudeRunner


class ProjectStatus(Enum):
    """Project status enumeration"""
    ACTIVE = "active"
    INACTIVE = "inactive"
    ARCHIVED = "archived"
    BOOTSTRAP = "bootstrap"
    MAINTENANCE = "maintenance"


class DependencyType(Enum):
    """Types of dependencies between projects"""
    CODE_DEPENDENCY = "code_dependency"
    SHARED_LIBRARY = "shared_library"
    CONFIG_DEPENDENCY = "config_dependency"
    BUILD_DEPENDENCY = "build_dependency"
    TEST_DEPENDENCY = "test_dependency"
    DEPLOYMENT_DEPENDENCY = "deployment_dependency"


@dataclass
class ProjectDependency:
    """Represents a dependency between projects"""
    source_project: str
    target_project: str
    dependency_type: DependencyType
    description: str
    strength: float  # 0.0 to 1.0, how strong the dependency is
    bidirectional: bool = False


@dataclass
class ProjectMetrics:
    """Metrics for a project"""
    lines_of_code: int
    test_coverage: float
    last_commit_date: str
    active_developers: int
    bug_count: int
    feature_count: int
    technical_debt_score: float
    complexity_score: float


@dataclass
class WorkspaceConfig:
    """Configuration for the entire workspace"""
    name: str
    description: str
    default_branch: str = "main"
    shared_tools: List[str] = None
    global_configs: Dict[str, Any] = None
    ci_templates: Dict[str, str] = None
    notification_settings: Dict[str, Any] = None

    def __post_init__(self):
        if self.shared_tools is None:
            self.shared_tools = []
        if self.global_configs is None:
            self.global_configs = {}
        if self.ci_templates is None:
            self.ci_templates = {}
        if self.notification_settings is None:
            self.notification_settings = {}


class MultiProjectManager:
    """Manages multiple projects in a workspace"""

    def __init__(self, workspace_root: Optional[Path] = None):
        self.workspace_root = workspace_root or Path.cwd()
        self.config_file = self.workspace_root / ".github" / "workspace" / "workspace_config.json"
        self.projects_file = self.workspace_root / ".github" / "workspace" / "projects.json"
        self.dependencies_file = self.workspace_root / ".github" / "workspace" / "dependencies.json"

        self.projects: Dict[str, ProjectContext] = {}
        self.dependencies: List[ProjectDependency] = []
        self.metrics: Dict[str, ProjectMetrics] = {}
        self.workspace_config: WorkspaceConfig

        self.logger = self._setup_logging()
        self.claude_runner = EnhancedClaudeRunner(self.workspace_root)

        # Initialize workspace
        self._initialize_workspace()

    def _setup_logging(self) -> logging.Logger:
        """Setup logging configuration"""
        logger = logging.getLogger("multi_project_manager")
        logger.setLevel(logging.INFO)

        if not logger.handlers:
            handler = logging.StreamHandler(sys.stderr)
            formatter = logging.Formatter(
                '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
            )
            handler.setFormatter(formatter)
            logger.addHandler(handler)

        return logger

    def _initialize_workspace(self):
        """Initialize workspace configuration and load projects"""
        # Create workspace directory if it doesn't exist
        self.config_file.parent.mkdir(parents=True, exist_ok=True)

        # Load workspace configuration
        self._load_workspace_config()

        # Load projects
        self._load_projects()

        # Load dependencies
        self._load_dependencies()

        # Analyze cross-project dependencies
        self._analyze_dependencies()

        # Calculate metrics
        self._calculate_metrics()

    def _load_workspace_config(self):
        """Load workspace configuration"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r') as f:
                    config_data = json.load(f)
                self.workspace_config = WorkspaceConfig(**config_data)
            except (json.JSONDecodeError, TypeError) as e:
                self.logger.error(f"Invalid workspace config: {e}")
                self._create_default_workspace_config()
        else:
            self._create_default_workspace_config()

    def _create_default_workspace_config(self):
        """Create default workspace configuration"""
        self.workspace_config = WorkspaceConfig(
            name=self.workspace_root.name,
            description=f"Multi-project workspace at {self.workspace_root}"
        )
        self._save_workspace_config()

    def _save_workspace_config(self):
        """Save workspace configuration"""
        with open(self.config_file, 'w') as f:
            json.dump(asdict(self.workspace_config), f, indent=2)

    def _load_projects(self):
        """Load projects from enhanced runner"""
        self.projects = {p.name: p for p in self.claude_runner.projects.values()}

    def _load_dependencies(self):
        """Load project dependencies from file"""
        if self.dependencies_file.exists():
            try:
                with open(self.dependencies_file, 'r') as f:
                    deps_data = json.load(f)

                self.dependencies = []
                for dep_data in deps_data:
                    self.dependencies.append(ProjectDependency(
                        source_project=dep_data['source_project'],
                        target_project=dep_data['target_project'],
                        dependency_type=DependencyType(dep_data['dependency_type']),
                        description=dep_data['description'],
                        strength=dep_data['strength'],
                        bidirectional=dep_data.get('bidirectional', False)
                    ))
            except (json.JSONDecodeError, KeyError, ValueError) as e:
                self.logger.error(f"Invalid dependencies config: {e}")
                self.dependencies = []

    def _analyze_dependencies(self):
        """Analyze cross-project dependencies"""
        # Clear existing auto-detected dependencies
        self.dependencies = [d for d in self.dependencies if d.description.startswith("Manual:")]

        for project_name, project in self.projects.items():
            # Analyze imports and requires statements
            self._analyze_code_dependencies(project)

            # Analyze build system dependencies
            self._analyze_build_dependencies(project)

            # Analyze test dependencies
            self._analyze_test_dependencies(project)

    def _analyze_code_dependencies(self, project: ProjectContext):
        """Analyze code-level dependencies"""
        if project.language == "python":
            self._analyze_python_dependencies(project)
        elif project.language in ["javascript", "typescript"]:
            self._analyze_js_dependencies(project)
        elif project.language == "cpp":
            self._analyze_cpp_dependencies(project)

    def _analyze_python_dependencies(self, project: ProjectContext):
        """Analyze Python project dependencies"""
        for py_file in project.path.rglob("*.py"):
            try:
                with open(py_file, 'r') as f:
                    content = f.read()

                # Look for relative imports that might reference other projects
                lines = content.split('\n')
                for line_num, line in enumerate(lines, 1):
                    line = line.strip()
                    if line.startswith('from ') or line.startswith('import '):
                        # Simple heuristic - look for imports that might reference other projects
                        for other_project in self.projects:
                            if other_project != project.name and other_project in line:
                                self._add_dependency(
                                    project.name, other_project,
                                    DependencyType.CODE_DEPENDENCY,
                                    f"Python import in {py_file.relative_to(self.workspace_root)}:{line_num}",
                                    strength=0.7
                                )
            except (UnicodeDecodeError, IOError):
                continue

    def _analyze_js_dependencies(self, project: ProjectContext):
        """Analyze JavaScript/TypeScript dependencies"""
        for js_file in project.path.rglob("*.{js,ts,jsx,tsx}"):
            try:
                with open(js_file, 'r') as f:
                    content = f.read()

                lines = content.split('\n')
                for line_num, line in enumerate(lines, 1):
                    line = line.strip()
                    if line.startswith('import ') or line.startswith('require('):
                        for other_project in self.projects:
                            if other_project != project.name and other_project in line:
                                self._add_dependency(
                                    project.name, other_project,
                                    DependencyType.CODE_DEPENDENCY,
                                    f"JS/TS import in {js_file.relative_to(self.workspace_root)}:{line_num}",
                                    strength=0.7
                                )
            except (UnicodeDecodeError, IOError):
                continue

    def _analyze_cpp_dependencies(self, project: ProjectContext):
        """Analyze C++ dependencies"""
        for cpp_file in project.path.rglob("*.{cpp,hpp,h,c}"):
            try:
                with open(cpp_file, 'r') as f:
                    content = f.read()

                lines = content.split('\n')
                for line_num, line in enumerate(lines, 1):
                    line = line.strip()
                    if line.startswith('#include '):
                        include_path = line[8:].strip('"<>')
                        for other_project in self.projects:
                            if other_project != project.name and other_project in include_path:
                                self._add_dependency(
                                    project.name, other_project,
                                    DependencyType.CODE_DEPENDENCY,
                                    f"C++ include in {cpp_file.relative_to(self.workspace_root)}:{line_num}",
                                    strength=0.6
                                )
            except (UnicodeDecodeError, IOError):
                continue

    def _analyze_build_dependencies(self, project: ProjectContext):
        """Analyze build system dependencies"""
        if project.language == "python":
            # Look for local path dependencies in pyproject.toml
            pyproject_path = project.path / "pyproject.toml"
            if pyproject_path.exists():
                try:
                    import toml
                    with open(pyproject_path, 'r') as f:
                        data = toml.load(f)

                    # Check for local path dependencies
                    deps = data.get('project', {}).get('dependencies', [])
                    for dep in deps:
                        if 'path =' in dep or 'file://' in dep:
                            for other_project in self.projects:
                                if other_project in dep:
                                    self._add_dependency(
                                        project.name, other_project,
                                        DependencyType.BUILD_DEPENDENCY,
                                        f"Local path dependency in pyproject.toml",
                                        strength=0.8
                                    )
                except ImportError:
                    pass

    def _analyze_test_dependencies(self, project: ProjectContext):
        """Analyze test dependencies"""
        test_dirs = ["tests", "test", "__tests__", "spec"]
        for test_dir in test_dirs:
            test_path = project.path / test_dir
            if test_path.exists():
                # Look for test files that might test other projects
                for test_file in test_path.rglob("*"):
                    if test_file.suffix in ['.py', '.js', '.ts', '.cpp']:
                        try:
                            with open(test_file, 'r') as f:
                                content = f.read()

                            for other_project in self.projects:
                                if other_project != project.name and other_project in content:
                                    self._add_dependency(
                                        project.name, other_project,
                                        DependencyType.TEST_DEPENDENCY,
                                        f"Test file references other project: {test_file.relative_to(self.workspace_root)}",
                                        strength=0.5
                                    )
                        except (UnicodeDecodeError, IOError):
                            continue

    def _add_dependency(self, source: str, target: str, dep_type: DependencyType,
                       description: str, strength: float):
        """Add a dependency if it doesn't already exist"""
        # Check if dependency already exists
        for dep in self.dependencies:
            if (dep.source_project == source and
                dep.target_project == target and
                dep.dependency_type == dep_type):
                # Update strength if this one is stronger
                if strength > dep.strength:
                    dep.strength = strength
                return

        # Add new dependency
        self.dependencies.append(ProjectDependency(
            source_project=source,
            target_project=target,
            dependency_type=dep_type,
            description=description,
            strength=strength
        ))

    def _calculate_metrics(self):
        """Calculate metrics for all projects"""
        for project_name, project in self.projects.items():
            self.metrics[project_name] = self._calculate_project_metrics(project)

    def _calculate_project_metrics(self, project: ProjectContext) -> ProjectMetrics:
        """Calculate metrics for a single project"""
        lines_of_code = 0
        test_files = 0
        source_files = 0

        # Count lines of code
        for file_path in project.path.rglob("*"):
            if file_path.is_file() and self._is_source_file(file_path):
                try:
                    with open(file_path, 'r') as f:
                        lines = len(f.readlines())
                        lines_of_code += lines
                        source_files += 1

                        if 'test' in file_path.name.lower() or 'test' in str(file_path).lower():
                            test_files += 1
                except (UnicodeDecodeError, IOError):
                    continue

        # Calculate test coverage (simplified)
        test_coverage = (test_files / max(source_files, 1)) * 100

        # Get last commit date
        last_commit_date = self._get_last_commit_date(project.path)

        # Calculate complexity (simplified - based on lines of code and dependencies)
        complexity_score = min(100, (lines_of_code / 1000) * 10 +
                              len([d for d in self.dependencies
                                  if d.source_project == project.name]) * 5)

        return ProjectMetrics(
            lines_of_code=lines_of_code,
            test_coverage=test_coverage,
            last_commit_date=last_commit_date,
            active_developers=1,  # Would need git history analysis
            bug_count=0,  # Would need issue tracker integration
            feature_count=0,  # Would need issue tracker integration
            technical_debt_score=complexity_score * 0.3,  # Simplified
            complexity_score=complexity_score
        )

    def _is_source_file(self, file_path: Path) -> bool:
        """Check if file is a source file"""
        source_extensions = {
            '.py', '.js', '.ts', '.jsx', '.tsx', '.cpp', '.hpp',
            '.h', '.c', '.java', '.go', '.rs', '.rb', '.php'
        }
        return file_path.suffix in source_extensions

    def _get_last_commit_date(self, project_path: Path) -> str:
        """Get last commit date for a project"""
        try:
            result = subprocess.run(
                ['git', 'log', '-1', '--format=%ci', str(project_path)],
                capture_output=True, text=True, cwd=self.workspace_root
            )
            if result.returncode == 0:
                return result.stdout.strip()
        except subprocess.SubprocessError:
            pass
        return "Unknown"

    def get_dependency_graph(self) -> Dict[str, Any]:
        """Get dependency graph representation"""
        graph = {
            "nodes": [],
            "edges": []
        }

        # Add nodes
        for project_name, project in self.projects.items():
            metrics = self.metrics.get(project_name)
            graph["nodes"].append({
                "id": project_name,
                "language": project.language,
                "build_system": project.build_system,
                "metrics": asdict(metrics) if metrics else {}
            })

        # Add edges
        for dep in self.dependencies:
            graph["edges"].append({
                "source": dep.source_project,
                "target": dep.target_project,
                "type": dep.dependency_type.value,
                "strength": dep.strength,
                "description": dep.description
            })

        return graph

    def get_project_hierarchy(self) -> List[List[str]]:
        """Get project hierarchy based on dependencies"""
        # Simple topological sort
        visited = set()
        temp_visited = set()
        result = []

        def visit(project_name: str):
            if project_name in temp_visited:
                return  # Cycle detected
            if project_name in visited:
                return

            temp_visited.add(project_name)

            # Visit dependencies first
            dependencies = [d.target_project for d in self.dependencies
                          if d.source_project == project_name]
            for dep in dependencies:
                visit(dep)

            temp_visited.remove(project_name)
            visited.add(project_name)
            result.append(project_name)

        for project_name in self.projects:
            if project_name not in visited:
                visit(project_name)

        return result

    def get_cross_project_impact(self, changed_project: str) -> Dict[str, List[str]]:
        """Get impact analysis for changes in a project"""
        impact = {}

        # Find projects that depend on the changed project
        for project_name in self.projects:
            if project_name == changed_project:
                continue

            dependencies = [d for d in self.dependencies
                          if d.target_project == changed_project and
                             d.source_project == project_name]

            if dependencies:
                impact[project_name] = [d.description for d in dependencies]

        return impact

    async def execute_cross_project_task(self, task_type: TaskType, description: str,
                                       affected_projects: List[str] = None) -> Dict[str, Any]:
        """Execute a task across multiple projects"""
        if affected_projects is None:
            affected_projects = list(self.projects.keys())

        results = {}

        for project_name in affected_projects:
            if project_name not in self.projects:
                continue

            project = self.projects[project_name]
            self.logger.info(f"Executing {task_type.value} on project: {project_name}")

            try:
                task_request = TaskRequest(
                    task_type=task_type,
                    description=f"[{project_name}] {description}",
                    project_context=project,
                    use_mcp=True
                )

                result = await self.claude_runner.execute_task(task_request)
                results[project_name] = result

            except Exception as e:
                self.logger.error(f"Failed to execute task on {project_name}: {e}")
                results[project_name] = {"success": False, "error": str(e)}

        return {
            "cross_project_task": True,
            "task_type": task_type.value,
            "description": description,
            "results": results,
            "summary": self._summarize_results(results)
        }

    def _summarize_results(self, results: Dict[str, Any]) -> Dict[str, Any]:
        """Summarize cross-project results"""
        total = len(results)
        successful = sum(1 for r in results.values() if r.get("success", False))
        failed = total - successful

        return {
            "total_projects": total,
            "successful": successful,
            "failed": failed,
            "success_rate": (successful / total) * 100 if total > 0 else 0
        }

    def save_state(self):
        """Save current state to files"""
        # Save dependencies
        with open(self.dependencies_file, 'w') as f:
            deps_data = []
            for dep in self.dependencies:
                deps_data.append({
                    "source_project": dep.source_project,
                    "target_project": dep.target_project,
                    "dependency_type": dep.dependency_type.value,
                    "description": dep.description,
                    "strength": dep.strength,
                    "bidirectional": dep.bidirectional
                })
            json.dump(deps_data, f, indent=2)

        # Save projects with metrics
        projects_data = {}
        for project_name, project in self.projects.items():
            projects_data[project_name] = {
                "name": project.name,
                "path": str(project.path),
                "language": project.language,
                "dependencies": project.dependencies,
                "build_system": project.build_system,
                "test_framework": project.test_framework,
                "metrics": asdict(self.metrics.get(project_name, ProjectMetrics(0, 0, "", 0, 0, 0, 0, 0)))
            }

        with open(self.projects_file, 'w') as f:
            json.dump(projects_data, f, indent=2)

    def generate_workspace_report(self) -> Dict[str, Any]:
        """Generate comprehensive workspace report"""
        return {
            "workspace_config": asdict(self.workspace_config),
            "projects": {name: asdict(project) for name, project in self.projects.items()},
            "dependency_graph": self.get_dependency_graph(),
            "project_hierarchy": self.get_project_hierarchy(),
            "metrics": {name: asdict(metrics) for name, metrics in self.metrics.items()},
            "summary": {
                "total_projects": len(self.projects),
                "languages": list(set(p.language for p in self.projects.values())),
                "total_dependencies": len(self.dependencies),
                "total_lines_of_code": sum(m.lines_of_code for m in self.metrics.values()),
                "average_test_coverage": sum(m.test_coverage for m in self.metrics.values()) / max(len(self.metrics), 1)
            }
        }


async def main():
    """Main entry point for CLI usage"""
    import argparse

    parser = argparse.ArgumentParser(description="Multi-Project Manager")
    parser.add_argument("--workspace-root", type=Path, help="Workspace root directory")
    parser.add_argument("action", choices=[
        "report", "dependencies", "hierarchy", "impact",
        "cross-project-task", "save-state"
    ], help="Action to perform")
    parser.add_argument("--project", help="Target project for specific actions")
    parser.add_argument("--task-type", choices=[t.value for t in TaskType],
                       help="Task type for cross-project execution")
    parser.add_argument("--description", help="Task description")
    parser.add_argument("--affected-projects", help="Comma-separated list of affected projects")

    args = parser.parse_args()

    manager = MultiProjectManager(args.workspace_root)

    try:
        if args.action == "report":
            report = manager.generate_workspace_report()
            print(json.dumps(report, indent=2))

        elif args.action == "dependencies":
            graph = manager.get_dependency_graph()
            print(json.dumps(graph, indent=2))

        elif args.action == "hierarchy":
            hierarchy = manager.get_project_hierarchy()
            print(json.dumps(hierarchy, indent=2))

        elif args.action == "impact":
            if not args.project:
                print("Error: --project required for impact analysis", file=sys.stderr)
                sys.exit(1)
            impact = manager.get_cross_project_impact(args.project)
            print(json.dumps(impact, indent=2))

        elif args.action == "cross-project-task":
            if not args.task_type or not args.description:
                print("Error: --task-type and --description required for cross-project tasks", file=sys.stderr)
                sys.exit(1)

            affected_projects = None
            if args.affected_projects:
                affected_projects = [p.strip() for p in args.affected_projects.split(',')]

            result = await manager.execute_cross_project_task(
                TaskType(args.task_type), args.description, affected_projects
            )
            print(json.dumps(result, indent=2))

        elif args.action == "save-state":
            manager.save_state()
            print("Workspace state saved")

    finally:
        pass  # Cleanup if needed


if __name__ == "__main__":
    asyncio.run(main())