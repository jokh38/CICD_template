#!/usr/bin/env python3
"""
Advanced context management with intelligent caching for AI workflows.
Implements context compression, selective caching, and adaptive context
strategies for optimal Claude Code CLI performance.
"""

import json
import hashlib
import os
import sys
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional, Set, Tuple
from dataclasses import dataclass, asdict, field
from enum import Enum
import gzip
import pickle


class ContextPriority(Enum):
    CRITICAL = "critical"
    HIGH = "high"
    MEDIUM = "medium"
    LOW = "low"


class ContextType(Enum):
    PROJECT_CONFIG = "project_config"
    SOURCE_CODE = "source_code"
    DOCUMENTATION = "documentation"
    DEPENDENCIES = "dependencies"
    BUILD_CONFIG = "build_config"
    TEST_CONFIG = "test_config"
    ERROR_HISTORY = "error_history"
    WORKFLOW_STATE = "workflow_state"


@dataclass
class ContextItem:
    """Represents a piece of contextual information"""
    content: str
    type: ContextType
    priority: ContextPriority
    source_path: Optional[str] = None
    size_bytes: int = 0
    last_modified: Optional[datetime] = None
    access_count: int = 0
    last_accessed: Optional[datetime] = None
    tags: Set[str] = field(default_factory=set)
    metadata: Dict[str, Any] = field(default_factory=dict)

    def __post_init__(self):
        if self.size_bytes == 0:
            self.size_bytes = len(self.content.encode('utf-8'))
        if self.last_modified is None and self.source_path:
            try:
                self.last_modified = datetime.fromtimestamp(Path(self.source_path).stat().st_mtime)
            except:
                self.last_modified = datetime.now()


@dataclass
class ContextCache:
    """Cache entry for context items"""
    item: ContextItem
    compressed_content: Optional[bytes] = None
    checksum: str = ""
    expiry_time: Optional[datetime] = None
    hit_count: int = 0
    created_at: datetime = field(default_factory=datetime.now)


class ContextCompressor:
    """Compresses and optimizes context for token efficiency"""

    def __init__(self, max_tokens: int = 150000):
        self.max_tokens = max_tokens
        self.approx_token_ratio = 4  # Rough estimate: 1 token ≈ 4 characters

    def estimate_tokens(self, text: str) -> int:
        """Estimate token count for text"""
        return len(text) // self.approx_token_ratio

    def compress_context_list(self, contexts: List[ContextItem]) -> List[ContextItem]:
        """Compress a list of context items to fit within token limit"""
        if not contexts:
            return []

        # Sort by priority and recency
        sorted_contexts = sorted(
            contexts,
            key=lambda x: (
                self._priority_score(x.priority),
                x.last_accessed or datetime.min,
                -x.access_count
            ),
            reverse=True
        )

        compressed = []
        current_tokens = 0

        for context in sorted_contexts:
            context_tokens = self.estimate_tokens(context.content)

            if current_tokens + context_tokens <= self.max_tokens:
                compressed.append(context)
                current_tokens += context_tokens
            else:
                # Try to compress the content
                compressed_content = self._compress_content(context.content)
                compressed_tokens = self.estimate_tokens(compressed_content)

                if current_tokens + compressed_tokens <= self.max_tokens:
                    # Create compressed version
                    compressed_context = ContextItem(
                        content=compressed_content,
                        type=context.type,
                        priority=context.priority,
                        source_path=context.source_path,
                        tags=context.tags | {"compressed"},
                        metadata={
                            **context.metadata,
                            "original_size": context.size_bytes,
                            "compressed": True
                        }
                    )
                    compressed.append(compressed_context)
                    current_tokens += compressed_tokens
                else:
                    # Skip this context
                    continue

        return compressed

    def _priority_score(self, priority: ContextPriority) -> int:
        """Convert priority to numeric score"""
        scores = {
            ContextPriority.CRITICAL: 1000,
            ContextPriority.HIGH: 100,
            ContextPriority.MEDIUM: 10,
            ContextPriority.LOW: 1
        }
        return scores.get(priority, 0)

    def _compress_content(self, content: str) -> str:
        """Compress content while preserving essential information"""
        lines = content.split('\n')
        compressed_lines = []

        for line in lines:
            stripped = line.strip()

            # Skip empty lines and common comments
            if not stripped or stripped.startswith('#') or stripped.startswith('//'):
                continue

            # Truncate very long lines
            if len(stripped) > 200:
                stripped = stripped[:197] + "..."

            compressed_lines.append(stripped)

        # Join and limit overall size
        compressed = '\n'.join(compressed_lines)
        if len(compressed) > 5000:
            compressed = compressed[:4970] + "\n... [truncated]"

        return compressed


class ContextCacheManager:
    """Manages caching of context items"""

    def __init__(self, cache_dir: Path = Path(".github/cache/context")):
        self.cache_dir = cache_dir
        self.cache_dir.mkdir(parents=True, exist_ok=True)
        self.memory_cache: Dict[str, ContextCache] = {}
        self.max_memory_items = 100
        self.default_ttl = timedelta(hours=6)

    def _get_cache_key(self, source_path: str, content: str) -> str:
        """Generate cache key for context item"""
        content_hash = hashlib.md5(content.encode()).hexdigest()
        path_hash = hashlib.md5(source_path.encode()).hexdigest()
        return f"{path_hash}_{content_hash}"

    def _get_cache_path(self, cache_key: str) -> Path:
        """Get file path for cache key"""
        return self.cache_dir / f"{cache_key}.cache"

    def get(self, source_path: str, content: str) -> Optional[ContextItem]:
        """Get cached context item"""
        cache_key = self._get_cache_key(source_path, content)

        # Check memory cache first
        if cache_key in self.memory_cache:
            cache_entry = self.memory_cache[cache_key]

            # Check expiry
            if cache_entry.expiry_time and datetime.now() > cache_entry.expiry_time:
                del self.memory_cache[cache_key]
                return None

            cache_entry.hit_count += 1
            cache_entry.item.last_accessed = datetime.now()
            cache_entry.item.access_count += 1

            return cache_entry.item

        # Check disk cache
        cache_path = self._get_cache_path(cache_key)
        if cache_path.exists():
            try:
                with gzip.open(cache_path, 'rb') as f:
                    cache_data = pickle.load(f)

                cache_entry = ContextCache(**cache_data)

                # Check expiry
                if cache_entry.expiry_time and datetime.now() > cache_entry.expiry_time:
                    cache_path.unlink()
                    return None

                cache_entry.hit_count += 1
                cache_entry.item.last_accessed = datetime.now()
                cache_entry.item.access_count += 1

                # Add to memory cache
                self._add_to_memory_cache(cache_key, cache_entry)

                return cache_entry.item

            except Exception as e:
                print(f"Warning: Failed to load cache entry {cache_key}: {e}", file=sys.stderr)
                try:
                    cache_path.unlink()
                except:
                    pass

        return None

    def put(self, item: ContextItem, ttl: Optional[timedelta] = None):
        """Cache a context item"""
        if not item.source_path:
            return

        cache_key = self._get_cache_key(item.source_path, item.content)
        expiry_time = datetime.now() + (ttl or self.default_ttl)

        cache_entry = ContextCache(
            item=item,
            checksum=hashlib.md5(item.content.encode()).hexdigest(),
            expiry_time=expiry_time,
            created_at=datetime.now()
        )

        # Add to memory cache
        self._add_to_memory_cache(cache_key, cache_entry)

        # Save to disk
        cache_path = self._get_cache_path(cache_key)
        try:
            with gzip.open(cache_path, 'wb') as f:
                pickle.dump(asdict(cache_entry), f)
        except Exception as e:
            print(f"Warning: Failed to cache entry {cache_key}: {e}", file=sys.stderr)

    def _add_to_memory_cache(self, cache_key: str, cache_entry: ContextCache):
        """Add item to memory cache with size management"""
        # Remove oldest items if cache is full
        while len(self.memory_cache) >= self.max_memory_items:
            oldest_key = min(
                self.memory_cache.keys(),
                key=lambda k: self.memory_cache[k].created_at
            )
            del self.memory_cache[oldest_key]

        self.memory_cache[cache_key] = cache_entry

    def invalidate(self, source_path: str):
        """Invalidate cache for specific source path"""
        keys_to_remove = []

        for cache_key in self.memory_cache:
            if cache_key.startswith(hashlib.md5(source_path.encode()).hexdigest()):
                keys_to_remove.append(cache_key)

        for key in keys_to_remove:
            del self.memory_cache[key]
            cache_path = self._get_cache_path(key)
            try:
                cache_path.unlink()
            except:
                pass

    def cleanup_expired(self):
        """Remove expired cache entries"""
        now = datetime.now()
        expired_keys = []

        for cache_key, cache_entry in self.memory_cache.items():
            if cache_entry.expiry_time and now > cache_entry.expiry_time:
                expired_keys.append(cache_key)

        for key in expired_keys:
            del self.memory_cache[key]
            cache_path = self._get_cache_path(key)
            try:
                cache_path.unlink()
            except:
                pass

        # Cleanup disk cache
        for cache_file in self.cache_dir.glob("*.cache"):
            try:
                with gzip.open(cache_file, 'rb') as f:
                    cache_data = pickle.load(f)

                expiry_time = cache_data.get('expiry_time')
                if expiry_time and datetime.fromisoformat(expiry_time) < now:
                    cache_file.unlink()
            except:
                try:
                    cache_file.unlink()
                except:
                    pass

    def get_statistics(self) -> Dict[str, Any]:
        """Get cache statistics"""
        total_items = len(self.memory_cache)
        total_hits = sum(entry.hit_count for entry in self.memory_cache.values())

        # Calculate disk cache size
        disk_size = sum(f.stat().st_size for f in self.cache_dir.glob("*.cache"))

        return {
            "memory_items": total_items,
            "memory_hits": total_hits,
            "disk_size_bytes": disk_size,
            "disk_items": len(list(self.cache_dir.glob("*.cache"))),
            "hit_rate": total_hits / max(total_items, 1)
        }


class ContextCollector:
    """Collects context from various sources"""

    def __init__(self, project_root: Path):
        self.project_root = project_root
        self.context_patterns = self._initialize_patterns()

    def _initialize_patterns(self) -> Dict[ContextType, List[Dict[str, Any]]]:
        """Initialize file patterns for different context types"""
        return {
            ContextType.PROJECT_CONFIG: [
                {"patterns": ["*.json", "*.toml", "*.yaml", "*.yml"], "priority": ContextPriority.HIGH},
                {"patterns": ["setup.py", "setup.cfg", "pyproject.toml"], "priority": ContextPriority.CRITICAL}
            ],
            ContextType.SOURCE_CODE: [
                {"patterns": ["*.py", "*.js", "*.ts", "*.cpp", "*.c", "*.h"], "priority": ContextPriority.MEDIUM},
                {"patterns": ["src/**/*", "lib/**/*", "app/**/*"], "priority": ContextPriority.HIGH}
            ],
            ContextType.DOCUMENTATION: [
                {"patterns": ["*.md", "*.rst", "*.txt"], "priority": ContextPriority.LOW},
                {"patterns": ["README*", "CHANGELOG*", "LICENSE*"], "priority": ContextPriority.MEDIUM}
            ],
            ContextType.DEPENDENCIES: [
                {"patterns": ["requirements*.txt", "Pipfile*", "poetry.lock", "package*.json"], "priority": ContextPriority.HIGH},
                {"patterns": ["Cargo.toml", "go.mod", "composer.json"], "priority": ContextPriority.HIGH}
            ],
            ContextType.BUILD_CONFIG: [
                {"patterns": ["Makefile", "CMakeLists.txt", "Dockerfile", "*.dockerfile"], "priority": ContextPriority.HIGH},
                {"patterns": ["*.mk", "build.gradle", "pom.xml"], "priority": ContextPriority.MEDIUM}
            ],
            ContextType.TEST_CONFIG: [
                {"patterns": ["pytest.ini", "tox.ini", "jest.config.*", "unittest.cfg"], "priority": ContextPriority.MEDIUM},
                {"patterns": ["test/**/*", "tests/**/*", "*_test.py", "*_test.*"], "priority": ContextPriority.LOW}
            ]
        }

    def collect_context(self, max_items_per_type: int = 5) -> List[ContextItem]:
        """Collect context items from the project"""
        context_items = []

        for context_type, patterns in self.context_patterns.items():
            type_items = []

            for pattern_info in patterns:
                for pattern in pattern_info["patterns"]:
                    try:
                        matches = list(self.project_root.glob(pattern))
                        for match in matches:
                            if match.is_file() and self._should_include_file(match):
                                item = self._create_context_item(match, context_type, pattern_info["priority"])
                                if item:
                                    type_items.append(item)
                    except Exception as e:
                        print(f"Warning: Failed to process pattern {pattern}: {e}", file=sys.stderr)

            # Sort by priority and limit items
            type_items.sort(key=lambda x: (-x.access_count, -(x.last_accessed or datetime.min).timestamp()))
            context_items.extend(type_items[:max_items_per_type])

        return context_items

    def _should_include_file(self, file_path: Path) -> bool:
        """Determine if a file should be included in context"""
        # Skip certain files and directories
        skip_patterns = [
            ".git", "__pycache__", "node_modules", ".pytest_cache",
            ".venv", "venv", "env", "build", "dist", ".coverage",
            "*.pyc", "*.pyo", "*.pyd", "*.so", "*.dll", "*.dylib"
        ]

        file_str = str(file_path)
        for pattern in skip_patterns:
            if pattern in file_str:
                return False

        # Skip files that are too large (>100KB)
        try:
            if file_path.stat().st_size > 100 * 1024:
                return False
        except:
            return False

        return True

    def _create_context_item(self, file_path: Path, context_type: ContextType, priority: ContextPriority) -> Optional[ContextItem]:
        """Create a context item from file"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()

            # Generate tags based on file path and content
            tags = set()
            if "test" in file_path.parts:
                tags.add("test")
            if "config" in file_path.name.lower():
                tags.add("config")
            if file_path.suffix in [".py", ".js", ".ts"]:
                tags.add("code")

            return ContextItem(
                content=content,
                type=context_type,
                priority=priority,
                source_path=str(file_path.relative_to(self.project_root)),
                tags=tags,
                metadata={"file_size": file_path.stat().st_size}
            )

        except Exception as e:
            print(f"Warning: Failed to read file {file_path}: {e}", file=sys.stderr)
            return None


class AdvancedContextManager:
    """Main context management system"""

    def __init__(self, project_root: Path = Path.cwd(), cache_dir: Optional[Path] = None):
        self.project_root = project_root
        self.cache_manager = ContextCacheManager(cache_dir)
        self.collector = ContextCollector(project_root)
        self.compressor = ContextCompressor()

    def build_context(self,
                     max_items: int = 20,
                     max_tokens: int = 150000,
                     include_cached: bool = True,
                     force_refresh: bool = False) -> str:
        """Build optimized context string"""

        context_items = []

        # Collect fresh context
        fresh_items = self.collector.collect_context()

        for item in fresh_items:
            # Check cache if not forcing refresh
            if include_cached and not force_refresh and item.source_path:
                cached_item = self.cache_manager.get(item.source_path, item.content)
                if cached_item:
                    context_items.append(cached_item)
                else:
                    context_items.append(item)
                    # Cache the item
                    self.cache_manager.put(item)
            else:
                context_items.append(item)

        # Sort by priority and relevance
        context_items.sort(key=lambda x: (
            self._priority_score(x.priority),
            x.access_count,
            -(x.last_accessed or datetime.min).timestamp()
        ), reverse=True)

        # Limit items
        context_items = context_items[:max_items]

        # Compress to fit token limit
        compressed_items = self.compressor.compress_context_list(context_items)

        # Build final context string
        context_parts = []

        for item in compressed_items:
            header_parts = [f"TYPE: {item.type.value.upper()}"]
            if item.source_path:
                header_parts.append(f"SOURCE: {item.source_path}")
            if item.tags:
                header_parts.append(f"TAGS: {', '.join(sorted(item.tags))}")

            header = " | ".join(header_parts)
            separator = "=" * len(header)

            context_parts.extend([
                header,
                separator,
                item.content,
                "",  # Empty line
                "-" * 50,  # Separator between items
                ""
            ])

        return "\n".join(context_parts).strip()

    def _priority_score(self, priority: ContextPriority) -> int:
        """Convert priority to numeric score"""
        scores = {
            ContextPriority.CRITICAL: 1000,
            ContextPriority.HIGH: 100,
            ContextPriority.MEDIUM: 10,
            ContextPriority.LOW: 1
        }
        return scores.get(priority, 0)

    def update_context_access(self, source_path: str):
        """Update access statistics for context item"""
        # This will be handled automatically by the cache manager
        pass

    def invalidate_context(self, source_path: str):
        """Invalidate cached context for specific path"""
        self.cache_manager.invalidate(source_path)

    def cleanup(self):
        """Cleanup expired cache entries"""
        self.cache_manager.cleanup_expired()

    def get_statistics(self) -> Dict[str, Any]:
        """Get context management statistics"""
        cache_stats = self.cache_manager.get_statistics()

        return {
            "cache_stats": cache_stats,
            "project_root": str(self.project_root),
            "max_tokens": self.compressor.max_tokens
        }


def main():
    """Main entry point for command-line usage"""
    import argparse

    parser = argparse.ArgumentParser(description="Advanced context management")
    parser.add_argument("--project-root", type=str, default=".", help="Project root directory")
    parser.add_argument("--max-items", type=int, default=20, help="Maximum context items")
    parser.add_argument("--max-tokens", type=int, default=150000, help="Maximum tokens")
    parser.add_argument("--force-refresh", action="store_true", help="Force refresh of all context")
    parser.add_argument("--stats", action="store_true", help="Show statistics")
    parser.add_argument("--cleanup", action="store_true", help="Cleanup expired cache")
    parser.add_argument("--output", type=str, help="Output file for context")

    args = parser.parse_args()

    try:
        manager = AdvancedContextManager(Path(args.project_root))

        if args.cleanup:
            manager.cleanup()
            print("Cache cleanup completed")
            return

        if args.stats:
            stats = manager.get_statistics()
            print(json.dumps(stats, indent=2))
            return

        # Build context
        context = manager.build_context(
            max_items=args.max_items,
            max_tokens=args.max_tokens,
            force_refresh=args.force_refresh
        )

        if args.output:
            with open(args.output, 'w') as f:
                f.write(context)
            print(f"Context written to {args.output}")
        else:
            print(context)

        # Show statistics
        stats = manager.get_statistics()
        print(f"\nContext Statistics:", file=sys.stderr)
        print(f"- Cache hit rate: {stats['cache_stats']['hit_rate']:.2f}", file=sys.stderr)
        print(f"- Memory items: {stats['cache_stats']['memory_items']}", file=sys.stderr)
        print(f"- Context length: {len(context)} characters", file=sys.stderr)

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()