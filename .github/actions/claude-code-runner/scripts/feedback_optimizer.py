#!/usr/bin/env python3
"""
Feedback loop optimization system for AI workflow automation.
Implements intelligent feedback analysis, adaptive learning, and
continuous optimization of Claude Code CLI workflows.
"""

import json
import time
import sys
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional, Tuple, Set
from dataclasses import dataclass, asdict, field
from enum import Enum
import re
import statistics
from collections import defaultdict, Counter
import sqlite3


class FeedbackType(Enum):
    SUCCESS = "success"
    ERROR = "error"
    WARNING = "warning"
    SUGGESTION = "suggestion"
    CORRECTION = "correction"
    OPTIMIZATION = "optimization"


class FeedbackSource(Enum):
    CI_PIPELINE = "ci_pipeline"
    CODE_REVIEW = "code_review"
    USER_FEEDBACK = "user_feedback"
    AUTOMATED_TESTS = "automated_tests"
    LINTING = "linting"
    SECURITY_SCAN = "security_scan"


@dataclass
class FeedbackItem:
    """Individual feedback item"""
    id: str
    type: FeedbackType
    source: FeedbackSource
    message: str
    severity: float  # 0.0 to 1.0
    timestamp: datetime
    context: Dict[str, Any] = field(default_factory=dict)
    tags: Set[str] = field(default_factory=set)
    related_files: List[str] = field(default_factory=list)
    resolution_time: Optional[float] = None  # Time to resolve in seconds
    resolved: bool = False
    actionable: bool = True


@dataclass
class FeedbackPattern:
    """Detected pattern in feedback"""
    pattern_id: str
    frequency: int
    first_seen: datetime
    last_seen: datetime
    avg_resolution_time: Optional[float] = None
    success_rate: float = 0.0
    auto_resolvable: bool = False
    suggested_action: Optional[str] = None
    related_patterns: List[str] = field(default_factory=list)


@dataclass
class OptimizationRecommendation:
    """Optimization recommendation based on feedback analysis"""
    id: str
    title: str
    description: str
    priority: float  # 0.0 to 1.0
    estimated_impact: float  # 0.0 to 1.0
    implementation_effort: float  # 0.0 to 1.0
    category: str
    action_items: List[str]
    expected_benefits: List[str]
    success_metrics: List[str]


class FeedbackDatabase:
    """Persistent storage for feedback data"""

    def __init__(self, db_path: Path = Path(".github/cache/feedback.db")):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_database()

    def _init_database(self):
        """Initialize database schema"""
        with sqlite3.connect(self.db_path) as conn:
            # Feedback items table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS feedback_items (
                    id TEXT PRIMARY KEY,
                    type TEXT NOT NULL,
                    source TEXT NOT NULL,
                    message TEXT NOT NULL,
                    severity REAL NOT NULL,
                    timestamp DATETIME NOT NULL,
                    context TEXT,
                    tags TEXT,
                    related_files TEXT,
                    resolution_time REAL,
                    resolved BOOLEAN DEFAULT FALSE,
                    actionable BOOLEAN DEFAULT TRUE
                )
            """)

            # Feedback patterns table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS feedback_patterns (
                    pattern_id TEXT PRIMARY KEY,
                    frequency INTEGER DEFAULT 0,
                    first_seen DATETIME NOT NULL,
                    last_seen DATETIME NOT NULL,
                    avg_resolution_time REAL,
                    success_rate REAL DEFAULT 0.0,
                    auto_resolvable BOOLEAN DEFAULT FALSE,
                    suggested_action TEXT,
                    related_patterns TEXT
                )
            """)

            # Optimization recommendations table
            conn.execute("""
                CREATE TABLE IF NOT EXISTS optimization_recommendations (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    description TEXT NOT NULL,
                    priority REAL NOT NULL,
                    estimated_impact REAL NOT NULL,
                    implementation_effort REAL NOT NULL,
                    category TEXT NOT NULL,
                    action_items TEXT,
                    expected_benefits TEXT,
                    success_metrics TEXT,
                    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
                    implemented BOOLEAN DEFAULT FALSE
                )
            """)

            # Create indexes
            conn.execute("CREATE INDEX IF NOT EXISTS idx_feedback_timestamp ON feedback_items(timestamp)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_feedback_type ON feedback_items(type)")
            conn.execute("CREATE INDEX IF NOT EXISTS idx_feedback_source ON feedback_items(source)")

    def store_feedback(self, feedback: FeedbackItem):
        """Store feedback item in database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO feedback_items
                (id, type, source, message, severity, timestamp, context, tags,
                 related_files, resolution_time, resolved, actionable)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                feedback.id,
                feedback.type.value,
                feedback.source.value,
                feedback.message,
                feedback.severity,
                feedback.timestamp,
                json.dumps(feedback.context),
                json.dumps(list(feedback.tags)),
                json.dumps(feedback.related_files),
                feedback.resolution_time,
                feedback.resolved,
                feedback.actionable
            ))

    def get_feedback(self,
                    limit: int = 1000,
                    start_time: Optional[datetime] = None,
                    end_time: Optional[datetime] = None,
                    feedback_type: Optional[FeedbackType] = None,
                    source: Optional[FeedbackSource] = None) -> List[FeedbackItem]:
        """Retrieve feedback items from database"""
        query = "SELECT * FROM feedback_items WHERE 1=1"
        params = []

        if start_time:
            query += " AND timestamp >= ?"
            params.append(start_time)

        if end_time:
            query += " AND timestamp <= ?"
            params.append(end_time)

        if feedback_type:
            query += " AND type = ?"
            params.append(feedback_type.value)

        if source:
            query += " AND source = ?"
            params.append(source.value)

        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)

        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, params)
            results = []

            for row in cursor.fetchall():
                feedback = FeedbackItem(
                    id=row["id"],
                    type=FeedbackType(row["type"]),
                    source=FeedbackSource(row["source"]),
                    message=row["message"],
                    severity=row["severity"],
                    timestamp=datetime.fromisoformat(row["timestamp"]),
                    context=json.loads(row["context"]) if row["context"] else {},
                    tags=set(json.loads(row["tags"])) if row["tags"] else set(),
                    related_files=json.loads(row["related_files"]) if row["related_files"] else [],
                    resolution_time=row["resolution_time"],
                    resolution_time=row["resolution_time"],
                    resolved=bool(row["resolved"]),
                    actionable=bool(row["actionable"])
                )
                results.append(feedback)

            return results

    def store_pattern(self, pattern: FeedbackPattern):
        """Store feedback pattern in database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO feedback_patterns
                (pattern_id, frequency, first_seen, last_seen, avg_resolution_time,
                 success_rate, auto_resolvable, suggested_action, related_patterns)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                pattern.pattern_id,
                pattern.frequency,
                pattern.first_seen,
                pattern.last_seen,
                pattern.avg_resolution_time,
                pattern.success_rate,
                pattern.auto_resolvable,
                pattern.suggested_action,
                json.dumps(pattern.related_patterns)
            ))

    def store_recommendation(self, recommendation: OptimizationRecommendation):
        """Store optimization recommendation in database"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                INSERT OR REPLACE INTO optimization_recommendations
                (id, title, description, priority, estimated_impact, implementation_effort,
                 category, action_items, expected_benefits, success_metrics)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                recommendation.id,
                recommendation.title,
                recommendation.description,
                recommendation.priority,
                recommendation.estimated_impact,
                recommendation.implementation_effort,
                recommendation.category,
                json.dumps(recommendation.action_items),
                json.dumps(recommendation.expected_benefits),
                json.dumps(recommendation.success_metrics)
            ))

    def get_statistics(self) -> Dict[str, Any]:
        """Get database statistics"""
        with sqlite3.connect(self.db_path) as conn:
            # Total feedback count
            total_feedback = conn.execute("SELECT COUNT(*) FROM feedback_items").fetchone()[0]

            # Feedback by type
            feedback_by_type = dict(conn.execute("""
                SELECT type, COUNT(*) FROM feedback_items GROUP BY type
            """).fetchall())

            # Feedback by source
            feedback_by_source = dict(conn.execute("""
                SELECT source, COUNT(*) FROM feedback_items GROUP BY source
            """).fetchall())

            # Resolution statistics
            resolved_count = conn.execute("SELECT COUNT(*) FROM feedback_items WHERE resolved = TRUE").fetchone()[0]
            resolution_rate = resolved_count / max(total_feedback, 1)

            # Average resolution time
            avg_resolution = conn.execute("""
                SELECT AVG(resolution_time) FROM feedback_items WHERE resolution_time IS NOT NULL
            """).fetchone()[0] or 0

            return {
                "total_feedback": total_feedback,
                "feedback_by_type": feedback_by_type,
                "feedback_by_source": feedback_by_source,
                "resolution_rate": resolution_rate,
                "average_resolution_time": avg_resolution
            }


class FeedbackAnalyzer:
    """Analyzes feedback to identify patterns and generate insights"""

    def __init__(self, database: FeedbackDatabase):
        self.database = database

    def identify_patterns(self, time_window: timedelta = timedelta(days=30)) -> List[FeedbackPattern]:
        """Identify recurring patterns in feedback"""
        end_time = datetime.now()
        start_time = end_time - time_window

        feedback_items = self.database.get_feedback(
            limit=10000,
            start_time=start_time,
            end_time=end_time
        )

        # Group feedback by similarity
        patterns = self._group_similar_feedback(feedback_items)

        # Analyze each pattern
        analyzed_patterns = []
        for pattern_id, items in patterns.items():
            pattern = self._analyze_pattern(pattern_id, items)
            analyzed_patterns.append(pattern)

        return analyzed_patterns

    def _group_similar_feedback(self, feedback_items: List[FeedbackItem]) -> Dict[str, List[FeedbackItem]]:
        """Group feedback items by similarity"""
        patterns = defaultdict(list)

        for item in feedback_items:
            # Generate pattern key based on message similarity
            pattern_key = self._generate_pattern_key(item.message)
            patterns[pattern_key].append(item)

        return dict(patterns)

    def _generate_pattern_key(self, message: str) -> str:
        """Generate pattern key from message"""
        # Normalize message: lowercase, remove specific values, keep structure
        normalized = message.lower()

        # Remove file paths, numbers, specific values
        normalized = re.sub(r'/[^/\s]+', '__FILE__', normalized)
        normalized = re.sub(r'\b\d+\b', '__NUM__', normalized)
        normalized = re.sub(r'"[^"]*"', '__STRING__', normalized)
        normalized = re.sub(r"'[^']*'", '__STRING__', normalized)

        # Remove extra whitespace
        normalized = re.sub(r'\s+', ' ', normalized).strip()

        # Generate hash
        import hashlib
        return hashlib.md5(normalized.encode()).hexdigest()[:16]

    def _analyze_pattern(self, pattern_id: str, items: List[FeedbackItem]) -> FeedbackPattern:
        """Analyze a group of similar feedback items"""
        if not items:
            raise ValueError("No items to analyze")

        # Calculate basic statistics
        frequency = len(items)
        first_seen = min(item.timestamp for item in items)
        last_seen = max(item.timestamp for item in items)

        # Calculate resolution statistics
        resolved_items = [item for item in items if item.resolved and item.resolution_time]
        avg_resolution_time = statistics.mean([item.resolution_time for item in resolved_items]) if resolved_items else None
        success_rate = len(resolved_items) / len(items) if items else 0

        # Determine if auto-resolvable
        auto_resolvable = self._is_auto_resolvable(items)

        # Generate suggested action
        suggested_action = self._generate_suggested_action(items)

        return FeedbackPattern(
            pattern_id=pattern_id,
            frequency=frequency,
            first_seen=first_seen,
            last_seen=last_seen,
            avg_resolution_time=avg_resolution_time,
            success_rate=success_rate,
            auto_resolvable=auto_resolvable,
            suggested_action=suggested_action
        )

    def _is_auto_resolvable(self, items: List[FeedbackItem]) -> bool:
        """Determine if a pattern can be automatically resolved"""
        if not items:
            return False

        # Check for common auto-resolvable patterns
        sample_messages = [item.message.lower() for item in items[:5]]

        auto_resolvable_patterns = [
            r"missing import",
            r"undefined variable",
            r"typo",
            r"indentation",
            r"syntax error",
            r"missing dependency",
            r"file not found"
        ]

        for pattern in auto_resolvable_patterns:
            if any(re.search(pattern, msg) for msg in sample_messages):
                return True

        return False

    def _generate_suggested_action(self, items: List[FeedbackItem]) -> Optional[str]:
        """Generate suggested action for pattern"""
        if not items:
            return None

        # Analyze common themes
        messages = [item.message.lower() for item in items[:10]]

        if any("import" in msg for msg in messages):
            return "Add missing import statements or fix module paths"
        elif any("dependency" in msg for msg in messages):
            return "Update dependencies or install missing packages"
        elif any("syntax" in msg for msg in messages):
            return "Fix syntax errors in source code"
        elif any("test" in msg for msg in messages):
            return "Update test cases or fix test configuration"
        elif any("security" in msg for msg in messages):
            return "Address security vulnerabilities"
        else:
            return "Review and address recurring issues"

    def generate_optimization_recommendations(self, patterns: List[FeedbackPattern]) -> List[OptimizationRecommendation]:
        """Generate optimization recommendations based on patterns"""
        recommendations = []

        # Sort patterns by frequency and impact
        sorted_patterns = sorted(
            patterns,
            key=lambda p: (p.frequency * (1 - p.success_rate)),
            reverse=True
        )

        for pattern in sorted_patterns[:10]:  # Top 10 patterns
            recommendation = self._create_recommendation(pattern)
            if recommendation:
                recommendations.append(recommendation)

        # Sort recommendations by priority
        recommendations.sort(key=lambda r: r.priority, reverse=True)

        return recommendations

    def _create_recommendation(self, pattern: FeedbackPattern) -> Optional[OptimizationRecommendation]:
        """Create optimization recommendation from pattern"""
        if pattern.frequency < 3:  # Skip low-frequency patterns
            return None

        # Calculate priority based on frequency, success rate, and resolution time
        priority = (pattern.frequency / 100) * (1 - pattern.success_rate)
        if pattern.avg_resolution_time:
            priority *= min(pattern.avg_resolution_time / 3600, 2)  # Weight by resolution time

        priority = min(priority, 1.0)

        # Determine category
        category = self._determine_category(pattern)

        # Generate action items
        action_items = self._generate_action_items(pattern, category)

        # Generate expected benefits
        expected_benefits = [
            f"Reduce {category.lower()} issues by {int(pattern.frequency * 0.8)} occurrences",
            f"Improve success rate from {int(pattern.success_rate * 100)}% to ~95%",
            "Reduce manual intervention required"
        ]

        if pattern.avg_resolution_time:
            time_saved = pattern.avg_resolution_time * pattern.frequency * 0.8
            expected_benefits.append(f"Save approximately {int(time_save / 60)} minutes of resolution time")

        return OptimizationRecommendation(
            id=f"opt_{pattern.pattern_id}",
            title=f"Optimize {category} Pattern: {pattern.suggested_action or 'Recurring Issue'}",
            description=f"Address recurring {category.lower()} pattern occurring {pattern.frequency} times with {int(pattern.success_rate * 100)}% success rate",
            priority=priority,
            estimated_impact=min(pattern.frequency / 50, 1.0),
            implementation_effort=0.3 if pattern.auto_resolvable else 0.7,
            category=category,
            action_items=action_items,
            expected_benefits=expected_benefits,
            success_metrics=[
                "Reduction in pattern frequency",
                "Improved success rate",
                "Reduced resolution time",
                "Fewer manual interventions"
            ]
        )

    def _determine_category(self, pattern: FeedbackPattern) -> str:
        """Determine category for pattern"""
        # This would ideally be based on the pattern content
        # For now, use a simple heuristic based on frequency and success rate
        if pattern.frequency > 20:
            return "Critical Process"
        elif pattern.frequency > 10:
            return "High-Impact Issue"
        elif pattern.success_rate < 0.5:
            return "Resolution Failure"
        else:
            return "Recurring Issue"

    def _generate_action_items(self, pattern: FeedbackPattern, category: str) -> List[str]:
        """Generate specific action items for pattern"""
        action_items = []

        if pattern.auto_resolvable:
            action_items.extend([
                "Implement automatic detection and resolution",
                "Add pre-commit hooks to prevent recurrence",
                "Update templates or boilerplate code"
            ])
        else:
            action_items.extend([
                "Investigate root cause of pattern",
                "Develop automated fix where possible",
                "Create documentation for manual resolution"
            ])

        if pattern.success_rate < 0.7:
            action_items.append("Improve current resolution process")

        return action_items


class FeedbackLoopOptimizer:
    """Main feedback loop optimization system"""

    def __init__(self, project_root: Path = Path.cwd()):
        self.project_root = project_root
        self.database = FeedbackDatabase(project_root / ".github/cache/feedback.db")
        self.analyzer = FeedbackAnalyzer(self.database)

    def add_feedback(self,
                    message: str,
                    feedback_type: FeedbackType,
                    source: FeedbackSource,
                    severity: float = 0.5,
                    context: Optional[Dict[str, Any]] = None,
                    related_files: Optional[List[str]] = None) -> str:
        """Add new feedback item"""
        feedback_id = f"feedback_{int(time.time())}_{hash(message) % 10000}"

        feedback = FeedbackItem(
            id=feedback_id,
            type=feedback_type,
            source=source,
            message=message,
            severity=severity,
            timestamp=datetime.now(),
            context=context or {},
            related_files=related_files or []
        )

        self.database.store_feedback(feedback)
        return feedback_id

    def mark_resolved(self, feedback_id: str, resolution_time: Optional[float] = None):
        """Mark feedback item as resolved"""
        # This would update the database record
        pass

    def analyze_and_optimize(self, time_window: timedelta = timedelta(days=30)) -> Dict[str, Any]:
        """Analyze feedback and generate optimization recommendations"""
        # Identify patterns
        patterns = self.analyzer.identify_patterns(time_window)

        # Generate recommendations
        recommendations = self.analyzer.generate_optimization_recommendations(patterns)

        # Store recommendations
        for rec in recommendations:
            self.database.store_recommendation(rec)

        # Get statistics
        stats = self.database.get_statistics()

        return {
            "analysis_timestamp": datetime.now().isoformat(),
            "time_window_days": time_window.days,
            "patterns_identified": len(patterns),
            "recommendations_generated": len(recommendations),
            "top_patterns": [asdict(p) for p in patterns[:5]],
            "top_recommendations": [asdict(r) for r in recommendations[:5]],
            "statistics": stats
        }

    def get_optimization_report(self) -> Dict[str, Any]:
        """Get comprehensive optimization report"""
        # Get recent feedback
        recent_feedback = self.database.get_feedback(limit=100)

        # Get current patterns
        patterns = self.analyzer.identify_patterns(timedelta(days=7))

        # Get recommendations
        recommendations = self.analyzer.generate_optimization_recommendations(patterns)

        # Generate insights
        insights = self._generate_insights(recent_feedback, patterns, recommendations)

        return {
            "report_timestamp": datetime.now().isoformat(),
            "insights": insights,
            "recent_feedback_summary": self._summarize_feedback(recent_feedback),
            "active_patterns": [asdict(p) for p in patterns],
            "optimization_recommendations": [asdict(r) for r in recommendations],
            "action_plan": self._generate_action_plan(recommendations)
        }

    def _generate_insights(self, feedback: List[FeedbackItem], patterns: List[FeedbackPattern], recommendations: List[OptimizationRecommendation]) -> List[str]:
        """Generate insights from analysis"""
        insights = []

        if not feedback:
            return ["No feedback data available for analysis"]

        # Analyze feedback trends
        recent_feedback = [f for f in feedback if f.timestamp > datetime.now() - timedelta(days=7)]
        older_feedback = [f for f in feedback if f.timestamp <= datetime.now() - timedelta(days=7)]

        if len(recent_feedback) > len(older_feedback):
            insights.append("📈 Feedback volume is increasing - may indicate growing issues")
        elif len(recent_feedback) < len(older_feedback):
            insights.append("📉 Feedback volume is decreasing - improvements are working")

        # Analyze resolution rates
        resolved_recent = sum(1 for f in recent_feedback if f.resolved)
        if recent_feedback:
            resolution_rate = resolved_recent / len(recent_feedback)
            if resolution_rate > 0.8:
                insights.append("✅ High resolution rate indicates effective problem handling")
            elif resolution_rate < 0.5:
                insights.append("⚠️ Low resolution rate requires attention")

        # Analyze patterns
        auto_resolvable_patterns = sum(1 for p in patterns if p.auto_resolvable)
        if auto_resolvable_patterns > 0:
            insights.append(f"🤖 {auto_resolvable_patterns} patterns could be automatically resolved")

        # Analyze recommendations
        high_priority_recs = sum(1 for r in recommendations if r.priority > 0.7)
        if high_priority_recs > 0:
            insights.append(f"🚨 {high_priority_recs} high-priority optimizations recommended")

        return insights

    def _summarize_feedback(self, feedback: List[FeedbackItem]) -> Dict[str, Any]:
        """Summarize feedback data"""
        if not feedback:
            return {"total": 0}

        # Count by type
        type_counts = Counter(f.type.value for f in feedback)

        # Count by source
        source_counts = Counter(f.source.value for f in feedback)

        # Calculate average severity
        avg_severity = statistics.mean(f.severity for f in feedback)

        # Resolution statistics
        resolved_count = sum(1 for f in feedback if f.resolved)
        resolution_rate = resolved_count / len(feedback)

        return {
            "total": len(feedback),
            "by_type": dict(type_counts),
            "by_source": dict(source_counts),
            "average_severity": avg_severity,
            "resolution_rate": resolution_rate,
            "resolved_count": resolved_count
        }

    def _generate_action_plan(self, recommendations: List[OptimizationRecommendation]) -> Dict[str, Any]:
        """Generate actionable plan from recommendations"""
        if not recommendations:
            return {"message": "No optimization recommendations at this time"}

        # Group by priority
        high_priority = [r for r in recommendations if r.priority > 0.7]
        medium_priority = [r for r in recommendations if 0.3 < r.priority <= 0.7]
        low_priority = [r for r in recommendations if r.priority <= 0.3]

        action_plan = {
            "immediate_actions": [],
            "short_term_goals": [],
            "long_term_improvements": []
        }

        for rec in high_priority:
            action_plan["immediate_actions"].append({
                "title": rec.title,
                "effort": rec.implementation_effort,
                "impact": rec.estimated_impact,
                "actions": rec.action_items[:2]  # Top 2 actions
            })

        for rec in medium_priority:
            action_plan["short_term_goals"].append({
                "title": rec.title,
                "actions": rec.action_items[:1]  # Top action
            })

        for rec in low_priority:
            action_plan["long_term_improvements"].append({
                "title": rec.title,
                "category": rec.category
            })

        return action_plan

    def cleanup_old_data(self, older_than: timedelta = timedelta(days=90)):
        """Clean up old feedback data"""
        cutoff_time = datetime.now() - older_than

        with sqlite3.connect(self.database.db_path) as conn:
            # Delete old feedback items
            cursor = conn.execute(
                "DELETE FROM feedback_items WHERE timestamp < ?",
                (cutoff_time,)
            )
            deleted_feedback = cursor.rowcount

            # Delete old patterns
            cursor = conn.execute(
                "DELETE FROM feedback_patterns WHERE last_seen < ?",
                (cutoff_time,)
            )
            deleted_patterns = cursor.rowcount

        return {
            "deleted_feedback_items": deleted_feedback,
            "deleted_patterns": deleted_patterns
        }


def main():
    """Main entry point for command-line usage"""
    import argparse

    parser = argparse.ArgumentParser(description="Feedback loop optimization")
    parser.add_argument("--project-root", type=str, default=".", help="Project root directory")
    parser.add_argument("--add-feedback", type=str, help="Add feedback item")
    parser.add_argument("--type", type=str, choices=[t.value for t in FeedbackType], help="Feedback type")
    parser.add_argument("--source", type=str, choices=[s.value for s in FeedbackSource], help="Feedback source")
    parser.add_argument("--severity", type=float, default=0.5, help="Feedback severity (0-1)")
    parser.add_argument("--analyze", action="store_true", help="Analyze feedback and generate recommendations")
    parser.add_argument("--report", action="store_true", help="Generate optimization report")
    parser.add_argument("--days", type=int, default=30, help="Time window for analysis (days)")
    parser.add_argument("--cleanup", action="store_true", help="Cleanup old data")

    args = parser.parse_args()

    try:
        optimizer = FeedbackLoopOptimizer(Path(args.project_root))

        if args.add_feedback:
            if not args.type or not args.source:
                print("Error: --type and --source required when adding feedback", file=sys.stderr)
                sys.exit(1)

            feedback_id = optimizer.add_feedback(
                message=args.add_feedback,
                feedback_type=FeedbackType(args.type),
                source=FeedbackSource(args.source),
                severity=args.severity
            )
            print(f"Added feedback: {feedback_id}")

        elif args.analyze:
            time_window = timedelta(days=args.days)
            results = optimizer.analyze_and_optimize(time_window)
            print(json.dumps(results, indent=2))

        elif args.report:
            report = optimizer.get_optimization_report()
            print(json.dumps(report, indent=2))

        elif args.cleanup:
            results = optimizer.cleanup_old_data()
            print(f"Cleaned up: {results}")

        else:
            # Default: show statistics
            stats = optimizer.database.get_statistics()
            print(json.dumps(stats, indent=2))

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()