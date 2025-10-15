#!/usr/bin/env python3
"""
Performance metrics collection system for AI workflow automation.
Collects, analyzes, and reports on various performance metrics to
optimize Claude Code CLI integration and workflow efficiency.
"""

import json
import time
import psutil
import threading
import sys
import os
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, Any, List, Optional, Callable
from dataclasses import dataclass, asdict, field
from enum import Enum
import statistics
import sqlite3
from contextlib import contextmanager


class MetricType(Enum):
    COUNTER = "counter"
    GAUGE = "gauge"
    HISTOGRAM = "histogram"
    TIMER = "timer"


@dataclass
class MetricValue:
    """Single metric value with timestamp"""
    value: float
    timestamp: datetime
    labels: Dict[str, str] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)


@dataclass
class MetricSummary:
    """Summary statistics for a metric"""
    name: str
    metric_type: MetricType
    count: int
    min_value: Optional[float] = None
    max_value: Optional[float] = None
    avg_value: Optional[float] = None
    median_value: Optional[float] = None
    sum_value: float = 0.0
    recent_value: Optional[float] = None
    trend: Optional[str] = None  # "increasing", "decreasing", "stable"


class PerformanceTracker:
    """Tracks performance metrics during execution"""

    def __init__(self):
        self.metrics: Dict[str, List[MetricValue]] = {}
        self.start_time: Optional[datetime] = None
        self.end_time: Optional[datetime] = None
        self.active_timers: Dict[str, float] = {}
        self.process = psutil.Process()

    def start_timer(self, name: str, labels: Optional[Dict[str, str]] = None):
        """Start a named timer"""
        self.active_timers[name] = time.time()
        if not self.start_time:
            self.start_time = datetime.now()

    def end_timer(self, name: str, labels: Optional[Dict[str, str]] = None):
        """End a named timer and record the duration"""
        if name not in self.active_timers:
            return

        duration = time.time() - self.active_timers[name]
        del self.active_timers[name]

        self.record_metric(name, duration, MetricType.TIMER, labels or {})

    @contextmanager
    def timer(self, name: str, labels: Optional[Dict[str, str]] = None):
        """Context manager for timing operations"""
        self.start_timer(name, labels)
        try:
            yield
        finally:
            self.end_timer(name, labels)

    def record_metric(self,
                     name: str,
                     value: float,
                     metric_type: MetricType,
                     labels: Optional[Dict[str, str]] = None,
                     metadata: Optional[Dict[str, Any]] = None):
        """Record a metric value"""
        if name not in self.metrics:
            self.metrics[name] = []

        metric_value = MetricValue(
            value=value,
            timestamp=datetime.now(),
            labels=labels or {},
            metadata=metadata or {}
        )

        self.metrics[name].append(metric_value)

    def increment_counter(self, name: str, value: float = 1.0, labels: Optional[Dict[str, str]] = None):
        """Increment a counter metric"""
        current_count = self._get_latest_value(name) or 0
        self.record_metric(name, current_count + value, MetricType.COUNTER, labels)

    def set_gauge(self, name: str, value: float, labels: Optional[Dict[str, str]] = None):
        """Set a gauge metric value"""
        self.record_metric(name, value, MetricType.GAUGE, labels)

    def record_histogram(self, name: str, value: float, labels: Optional[Dict[str, str]] = None):
        """Record a histogram value"""
        self.record_metric(name, value, MetricType.HISTOGRAM, labels)

    def _get_latest_value(self, name: str) -> Optional[float]:
        """Get the most recent value for a metric"""
        if name in self.metrics and self.metrics[name]:
            return self.metrics[name][-1].value
        return None

    def get_system_metrics(self) -> Dict[str, float]:
        """Get current system performance metrics"""
        try:
            # CPU metrics
            cpu_percent = self.process.cpu_percent()
            cpu_count = psutil.cpu_count()

            # Memory metrics
            memory_info = self.process.memory_info()
            memory_percent = self.process.memory_percent()

            # System metrics
            system_memory = psutil.virtual_memory()
            disk_usage = psutil.disk_usage(self.process.cwd())

            return {
                "cpu_percent": cpu_percent,
                "cpu_count": cpu_count,
                "memory_rss": memory_info.rss,
                "memory_vms": memory_info.vms,
                "memory_percent": memory_percent,
                "system_memory_percent": system_memory.percent,
                "disk_free": disk_usage.free,
                "disk_usage_percent": (disk_usage.used / disk_usage.total) * 100,
                "open_files": len(self.process.open_files()),
                "threads": self.process.num_threads()
            }
        except Exception as e:
            print(f"Warning: Failed to collect system metrics: {e}", file=sys.stderr)
            return {}

    def record_system_metrics(self, labels: Optional[Dict[str, str]] = None):
        """Record current system metrics"""
        metrics = self.get_system_metrics()
        for name, value in metrics.items():
            self.set_gauge(f"system_{name}", value, labels)

    def finish(self):
        """Mark tracking as finished"""
        self.end_time = datetime.now()

    def get_duration(self) -> Optional[float]:
        """Get total duration of tracking"""
        if self.start_time and self.end_time:
            return (self.end_time - self.start_time).total_seconds()
        elif self.start_time:
            return (datetime.now() - self.start_time).total_seconds()
        return None

    def get_summary(self) -> Dict[str, Any]:
        """Get summary of all tracked metrics"""
        summary = {
            "tracking_duration": self.get_duration(),
            "total_metrics": len(self.metrics),
            "metrics": {}
        }

        for name, values in self.metrics.items():
            if not values:
                continue

            metric_summary = self._summarize_metric(name, values)
            summary["metrics"][name] = metric_summary

        return summary

    def _summarize_metric(self, name: str, values: List[MetricValue]) -> Dict[str, Any]:
        """Summarize metrics for a specific name"""
        numeric_values = [v.value for v in values]

        summary = {
            "name": name,
            "count": len(values),
            "type": values[0].metadata.get("metric_type", "unknown"),
            "min": min(numeric_values),
            "max": max(numeric_values),
            "avg": statistics.mean(numeric_values),
            "sum": sum(numeric_values),
            "recent": values[-1].value,
            "first_timestamp": values[0].timestamp.isoformat(),
            "last_timestamp": values[-1].timestamp.isoformat()
        }

        if len(numeric_values) > 1:
            summary["median"] = statistics.median(numeric_values)
            summary["std_dev"] = statistics.stdev(numeric_values) if len(numeric_values) > 2 else 0

            # Calculate trend
            if len(numeric_values) >= 3:
                recent_avg = statistics.mean(numeric_values[-3:])
                earlier_avg = statistics.mean(numeric_values[:3])
                if recent_avg > earlier_avg * 1.1:
                    summary["trend"] = "increasing"
                elif recent_avg < earlier_avg * 0.9:
                    summary["trend"] = "decreasing"
                else:
                    summary["trend"] = "stable"

        return summary


class MetricsDatabase:
    """Persistent storage for metrics data"""

    def __init__(self, db_path: Path = Path(".github/cache/metrics.db")):
        self.db_path = db_path
        self.db_path.parent.mkdir(parents=True, exist_ok=True)
        self._init_database()

    def _init_database(self):
        """Initialize database schema"""
        with sqlite3.connect(self.db_path) as conn:
            conn.execute("""
                CREATE TABLE IF NOT EXISTS metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    name TEXT NOT NULL,
                    value REAL NOT NULL,
                    metric_type TEXT NOT NULL,
                    labels TEXT,
                    metadata TEXT,
                    timestamp DATETIME NOT NULL,
                    workflow_id TEXT,
                    run_id TEXT
                )
            """)

            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_metrics_name_timestamp
                ON metrics(name, timestamp)
            """)

            conn.execute("""
                CREATE INDEX IF NOT EXISTS idx_metrics_workflow
                ON metrics(workflow_id)
            """)

    def store_metrics(self,
                     metrics: Dict[str, List[MetricValue]],
                     workflow_id: Optional[str] = None,
                     run_id: Optional[str] = None):
        """Store metrics in database"""
        with sqlite3.connect(self.db_path) as conn:
            for name, values in metrics.items():
                for metric_value in values:
                    conn.execute("""
                        INSERT INTO metrics
                        (name, value, metric_type, labels, metadata, timestamp, workflow_id, run_id)
                        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    """, (
                        name,
                        metric_value.value,
                        metric_value.metadata.get("metric_type", "unknown"),
                        json.dumps(metric_value.labels),
                        json.dumps(metric_value.metadata),
                        metric_value.timestamp,
                        workflow_id,
                        run_id
                    ))

    def query_metrics(self,
                     name: Optional[str] = None,
                     start_time: Optional[datetime] = None,
                     end_time: Optional[datetime] = None,
                     workflow_id: Optional[str] = None,
                     limit: int = 1000) -> List[Dict[str, Any]]:
        """Query metrics from database"""
        query = "SELECT * FROM metrics WHERE 1=1"
        params = []

        if name:
            query += " AND name = ?"
            params.append(name)

        if start_time:
            query += " AND timestamp >= ?"
            params.append(start_time)

        if end_time:
            query += " AND timestamp <= ?"
            params.append(end_time)

        if workflow_id:
            query += " AND workflow_id = ?"
            params.append(workflow_id)

        query += " ORDER BY timestamp DESC LIMIT ?"
        params.append(limit)

        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, params)
            return [dict(row) for row in cursor.fetchall()]

    def get_aggregated_metrics(self,
                             name: str,
                             aggregation: str = "avg",
                             time_window: timedelta = timedelta(hours=24)) -> Dict[str, Any]:
        """Get aggregated metrics over time window"""
        start_time = datetime.now() - time_window

        aggregation_funcs = {
            "avg": "AVG(value)",
            "min": "MIN(value)",
            "max": "MAX(value)",
            "sum": "SUM(value)",
            "count": "COUNT(value)"
        }

        func = aggregation_funcs.get(aggregation, "AVG(value)")

        query = f"""
            SELECT
                name,
                {func} as aggregated_value,
                COUNT(*) as sample_count,
                MIN(timestamp) as first_timestamp,
                MAX(timestamp) as last_timestamp
            FROM metrics
            WHERE name = ? AND timestamp >= ?
        """

        with sqlite3.connect(self.db_path) as conn:
            conn.row_factory = sqlite3.Row
            cursor = conn.execute(query, (name, start_time))
            result = cursor.fetchone()

            if result:
                return dict(result)
            else:
                return {}

    def cleanup_old_metrics(self, older_than: timedelta = timedelta(days=30)):
        """Remove old metrics from database"""
        cutoff_time = datetime.now() - older_than

        with sqlite3.connect(self.db_path) as conn:
            cursor = conn.execute(
                "DELETE FROM metrics WHERE timestamp < ?",
                (cutoff_time,)
            )
            return cursor.rowcount

    def get_statistics(self) -> Dict[str, Any]:
        """Get database statistics"""
        with sqlite3.connect(self.db_path) as conn:
            # Total metrics count
            total_count = conn.execute("SELECT COUNT(*) FROM metrics").fetchone()[0]

            # Unique metric names
            unique_names = conn.execute("SELECT COUNT(DISTINCT name) FROM metrics").fetchone()[0]

            # Date range
            date_range = conn.execute("""
                SELECT MIN(timestamp), MAX(timestamp) FROM metrics
            """).fetchone()

            # Database size
            db_size = self.db_path.stat().st_size if self.db_path.exists() else 0

            return {
                "total_metrics": total_count,
                "unique_names": unique_names,
                "oldest_metric": date_range[0],
                "newest_metric": date_range[1],
                "database_size_bytes": db_size
            }


class MetricsAnalyzer:
    """Analyzes metrics and provides insights"""

    def __init__(self, database: MetricsDatabase):
        self.database = database

    def analyze_performance_trends(self, metric_name: str, time_window: timedelta = timedelta(days=7)) -> Dict[str, Any]:
        """Analyze performance trends for a specific metric"""
        end_time = datetime.now()
        start_time = end_time - time_window

        # Get metrics data
        metrics = self.database.query_metrics(
            name=metric_name,
            start_time=start_time,
            end_time=end_time
        )

        if not metrics:
            return {"error": "No data found for metric"}

        # Convert to numeric values
        values = [m["value"] for m in metrics]
        timestamps = [datetime.fromisoformat(m["timestamp"]) for m in metrics]

        # Calculate trend
        if len(values) >= 2:
            # Simple linear regression for trend
            n = len(values)
            x_values = list(range(n))

            x_mean = statistics.mean(x_values)
            y_mean = statistics.mean(values)

            numerator = sum((x_values[i] - x_mean) * (values[i] - y_mean) for i in range(n))
            denominator = sum((x_values[i] - x_mean) ** 2 for i in range(n))

            slope = numerator / denominator if denominator != 0 else 0

            # Determine trend direction
            if abs(slope) < 0.01:
                trend = "stable"
            elif slope > 0:
                trend = "improving" if metric_name.startswith("success") else "degrading"
            else:
                trend = "degrading" if metric_name.startswith("success") else "improving"
        else:
            trend = "insufficient_data"

        return {
            "metric_name": metric_name,
            "time_window_days": time_window.days,
            "data_points": len(values),
            "trend": trend,
            "slope": slope if len(values) >= 2 else 0,
            "statistics": {
                "min": min(values),
                "max": max(values),
                "avg": statistics.mean(values),
                "median": statistics.median(values),
                "std_dev": statistics.stdev(values) if len(values) > 2 else 0
            },
            "recent_values": values[-5:],
            "analysis_timestamp": datetime.now().isoformat()
        }

    def detect_anomalies(self,
                        metric_name: str,
                        threshold_std: float = 2.0,
                        time_window: timedelta = timedelta(days=1)) -> List[Dict[str, Any]]:
        """Detect anomalies in metrics data"""
        end_time = datetime.now()
        start_time = end_time - time_window

        metrics = self.database.query_metrics(
            name=metric_name,
            start_time=start_time,
            end_time=end_time
        )

        if len(metrics) < 10:  # Need sufficient data for anomaly detection
            return []

        values = [m["value"] for m in metrics]

        # Calculate baseline statistics (excluding recent values)
        baseline_values = values[:-5]
        if len(baseline_values) < 5:
            return []

        baseline_mean = statistics.mean(baseline_values)
        baseline_std = statistics.stdev(baseline_values) if len(baseline_values) > 2 else 0

        anomalies = []
        for i, (metric_record, value) in enumerate(zip(metrics[-5:], values[-5:])):
            if baseline_std > 0:
                z_score = abs(value - baseline_mean) / baseline_std
                if z_score > threshold_std:
                    anomalies.append({
                        "timestamp": metric_record["timestamp"],
                        "value": value,
                        "baseline_mean": baseline_mean,
                        "z_score": z_score,
                        "severity": "high" if z_score > 3 else "medium"
                    })

        return anomalies

    def generate_performance_report(self, time_window: timedelta = timedelta(days=7)) -> Dict[str, Any]:
        """Generate comprehensive performance report"""
        # Get unique metric names
        with sqlite3.connect(self.database.db_path) as conn:
            metric_names = [row[0] for row in conn.execute("SELECT DISTINCT name FROM metrics").fetchall()]

        report = {
            "report_timestamp": datetime.now().isoformat(),
            "time_window_days": time_window.days,
            "metrics_summary": {},
            "anomalies": {},
            "recommendations": []
        }

        for name in metric_names:
            # Analyze trends
            trend_analysis = self.analyze_performance_trends(name, time_window)
            report["metrics_summary"][name] = trend_analysis

            # Detect anomalies
            anomalies = self.detect_anomalies(name, time_window=time_window)
            if anomalies:
                report["anomalies"][name] = anomalies

        # Generate recommendations
        report["recommendations"] = self._generate_recommendations(report)

        return report

    def _generate_recommendations(self, report: Dict[str, Any]) -> List[str]:
        """Generate performance recommendations based on analysis"""
        recommendations = []

        # Check for degrading performance
        for metric_name, analysis in report["metrics_summary"].items():
            if analysis.get("trend") == "degrading":
                if "duration" in metric_name:
                    recommendations.append(f"⚠️ {metric_name} is increasing - consider optimization")
                elif "memory" in metric_name:
                    recommendations.append(f"⚠️ {metric_name} usage is increasing - investigate memory leaks")
                elif "error" in metric_name:
                    recommendations.append(f"🚨 {metric_name} is increasing - urgent attention needed")

        # Check for anomalies
        if report["anomalies"]:
            total_anomalies = sum(len(anomalies) for anomalies in report["anomalies"].values())
            if total_anomalies > 5:
                recommendations.append(f"🚨 Detected {total_anomalies} anomalies - investigate system stability")

        # Check for performance improvements
        for metric_name, analysis in report["metrics_summary"].items():
            if analysis.get("trend") == "improving" and "success" in metric_name:
                recommendations.append(f"✅ {metric_name} is improving - keep up the good work")

        return recommendations


class AdvancedMetricsCollector:
    """Main metrics collection system"""

    def __init__(self, project_root: Path = Path.cwd()):
        self.project_root = project_root
        self.database = MetricsDatabase(project_root / ".github/cache/metrics.db")
        self.analyzer = MetricsAnalyzer(self.database)
        self.active_tracker: Optional[PerformanceTracker] = None

    def start_tracking(self, workflow_id: Optional[str] = None, run_id: Optional[str] = None) -> PerformanceTracker:
        """Start a new performance tracking session"""
        self.active_tracker = PerformanceTracker()
        self.active_tracker.workflow_id = workflow_id
        self.active_tracker.run_id = run_id
        return self.active_tracker

    def stop_tracking(self):
        """Stop current tracking session and store metrics"""
        if not self.active_tracker:
            return

        self.active_tracker.finish()
        self.database.store_metrics(
            self.active_tracker.metrics,
            getattr(self.active_tracker, 'workflow_id', None),
            getattr(self.active_tracker, 'run_id', None)
        )

        self.active_tracker = None

    def collect_system_metrics_periodically(self, interval: float = 30.0):
        """Collect system metrics periodically in background"""
        def collect_metrics():
            while self.active_tracker:
                if self.active_tracker:
                    self.active_tracker.record_system_metrics()
                time.sleep(interval)

        thread = threading.Thread(target=collect_metrics, daemon=True)
        thread.start()

    def get_performance_report(self, time_window: timedelta = timedelta(days=7)) -> Dict[str, Any]:
        """Get comprehensive performance report"""
        return self.analyzer.generate_performance_report(time_window)

    def cleanup(self, older_than: timedelta = timedelta(days=30)):
        """Cleanup old metrics data"""
        return self.database.cleanup_old_metrics(older_than)

    def get_statistics(self) -> Dict[str, Any]:
        """Get system statistics"""
        return self.database.get_statistics()


def main():
    """Main entry point for command-line usage"""
    import argparse

    parser = argparse.ArgumentParser(description="Advanced metrics collection")
    parser.add_argument("--project-root", type=str, default=".", help="Project root directory")
    parser.add_argument("--report", action="store_true", help="Generate performance report")
    parser.add_argument("--days", type=int, default=7, help="Time window for analysis (days)")
    parser.add_argument("--cleanup", action="store_true", help="Cleanup old metrics")
    parser.add_argument("--stats", action="store_true", help="Show database statistics")
    parser.add_argument("--metric", type=str, help="Analyze specific metric")

    args = parser.parse_args()

    try:
        collector = AdvancedMetricsCollector(Path(args.project_root))

        if args.cleanup:
            deleted = collector.cleanup()
            print(f"Cleaned up {deleted} old metric records")
            return

        if args.stats:
            stats = collector.get_statistics()
            print(json.dumps(stats, indent=2))
            return

        if args.report:
            time_window = timedelta(days=args.days)
            report = collector.get_performance_report(time_window)
            print(json.dumps(report, indent=2))
            return

        if args.metric:
            time_window = timedelta(days=args.days)
            analysis = collector.analyzer.analyze_performance_trends(args.metric, time_window)
            print(json.dumps(analysis, indent=2))
            return

        # Default: show database statistics
        stats = collector.get_statistics()
        print(json.dumps(stats, indent=2))

    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()