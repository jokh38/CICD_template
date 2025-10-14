#!/bin/bash
# Performance Measurement Script for Pilot Projects
# Part of the CICD Template System - Phase 9.1

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"

# Default values
PROJECT_DIR=""
METRICS_FILE="performance-metrics.json"
GITHUB_TOKEN=""
REPO_OWNER=""
REPO_NAME=""
OUTPUT_FORMAT="json"
COMPARE_WITH_BASELINE=false
BASELINE_FILE=""

# Logging functions
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

log_error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

log_info() {
    echo -e "${BLUE}[INFO] $1${NC}"
}

# Usage information
usage() {
    cat << EOF
Usage: $0 [options] <project-directory>

Measure and analyze CI/CD performance for pilot projects.

Arguments:
  project-directory    Path to project directory to measure

Options:
  -o, --output FILE    Output metrics file (default: performance-metrics.json)
  -f, --format FORMAT  Output format: json, csv, table (default: json)
  -t, --token TOKEN    GitHub token for API access
  -r, --repo OWNER/REPO Repository in format owner/repo
  -c, --compare FILE   Compare with baseline file
  -h, --help           Show this help message

Examples:
  $0 /path/to/python-project
  $0 -f table -r myorg/myproject /path/to/project
  $0 -c baseline.json -t \$GITHUB_TOKEN /path/to/project

GitHub Token Required For:
- CI/CD workflow run analysis
- Repository statistics
- Historical data

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -o|--output)
            METRICS_FILE="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -t|--token)
            GITHUB_TOKEN="$2"
            shift 2
            ;;
        -r|--repo)
            REPO_INFO="$2"
            REPO_OWNER=$(echo "$REPO_INFO" | cut -d'/' -f1)
            REPO_NAME=$(echo "$REPO_INFO" | cut -d'/' -f2)
            shift 2
            ;;
        -c|--compare)
            BASELINE_FILE="$2"
            COMPARE_WITH_BASELINE=true
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            log_error "Unknown option: $1"
            usage
            exit 1
            ;;
        *)
            if [ -z "$PROJECT_DIR" ]; then
                PROJECT_DIR="$1"
            else
                log_error "Multiple project directories specified"
                usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate arguments
if [ -z "$PROJECT_DIR" ]; then
    log_error "Project directory is required"
    usage
    exit 1
fi

if [ ! -d "$PROJECT_DIR" ]; then
    log_error "Project directory does not exist: $PROJECT_DIR"
    exit 1
fi

if [[ ! "$OUTPUT_FORMAT" =~ ^(json|csv|table)$ ]]; then
    log_error "Output format must be: json, csv, or table"
    exit 1
fi

if [ "$COMPARE_WITH_BASELINE" = true ] && [ ! -f "$BASELINE_FILE" ]; then
    log_error "Baseline file does not exist: $BASELINE_FILE"
    exit 1
fi

# Detect project type
detect_project_type() {
    if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
        echo "python"
    elif [ -f "$PROJECT_DIR/CMakeLists.txt" ]; then
        echo "cpp"
    else
        log_error "Unsupported project type"
        exit 1
    fi
}

# Get GitHub CI/CD metrics
get_github_metrics() {
    local metrics_file="$1"

    if [ -z "$GITHUB_TOKEN" ] || [ -z "$REPO_OWNER" ] || [ -z "$REPO_NAME" ]; then
        log_warning "GitHub token or repository not provided. Skipping CI/CD metrics."
        return
    fi

    log_info "Fetching GitHub CI/CD metrics..."

    # Export token for GitHub CLI
    export GH_TOKEN="$GITHUB_TOKEN"

    # Get recent workflow runs
    local workflow_runs
    workflow_runs=$(gh api repos/"$REPO_OWNER"/"$REPO_NAME"/actions/runs \
        --jq '.workflow_runs[] | select(.name | contains("CI") or contains("test") or contains("build")) | {
            name: .name,
            status: .status,
            conclusion: .conclusion,
            duration: ((.updated_at | fromdateiso8601) - (.created_at | fromdateiso8601)),
            created_at: .created_at,
            head_branch: .head_branch
        }' 2>/dev/null || echo "[]")

    if [ "$workflow_runs" = "[]" ]; then
        log_warning "No CI/CD workflow runs found"
        return
    fi

    # Process runs and calculate statistics
    local successful_runs
    successful_runs=$(echo "$workflow_runs" | jq '[.[] | select(.conclusion == "success")]')

    if [ "$successful_runs" = "[]" ]; then
        log_warning "No successful CI/CD runs found"
        return
    fi

    # Calculate metrics
    local avg_duration
    avg_duration=$(echo "$successful_runs" | jq '[.[] | .duration] | add / length')

    local total_runs
    total_runs=$(echo "$workflow_runs" | jq 'length')

    local success_rate
    success_rate=$(echo "$workflow_runs" | jq '[.[] | select(.conclusion == "success")] | length / length * 100')

    # Add to metrics
    local temp_metrics
    temp_metrics=$(mktemp)
    cat > "$temp_metrics" << EOF
{
  "cicd": {
    "total_runs": $total_runs,
    "successful_runs": $(echo "$successful_runs" | jq 'length'),
    "success_rate": $success_rate,
    "average_duration_seconds": $avg_duration,
    "data_collected": "$(date -Iseconds)",
    "repository": "$REPO_OWNER/$REPO_NAME"
  }
}
EOF

    # Merge with existing metrics
    if [ -f "$metrics_file" ]; then
        jq -s '.[0] * .[1]' "$metrics_file" "$temp_metrics" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    else
        cp "$temp_metrics" "$metrics_file"
    fi

    rm -f "$temp_metrics"

    log_info "CI/CD metrics collected: $total_runs runs, ${success_rate}% success rate"
}

# Measure local development metrics
measure_local_metrics() {
    local project_type="$1"
    local metrics_file="$2"

    log_info "Measuring local development performance..."

    cd "$PROJECT_DIR"

    local temp_metrics
    temp_metrics=$(mktemp)

    # Initialize metrics structure
    cat > "$temp_metrics" << EOF
{
  "project": {
    "name": "$(basename "$PROJECT_DIR")",
    "type": "$project_type",
    "path": "$PROJECT_DIR"
  },
  "local_performance": {
    "timestamp": "$(date -Iseconds)",
    "machine": "$(uname -a)",
    "python_version": "$(python3 --version 2>&1)"
  }
}
EOF

    case $project_type in
        python)
            measure_python_performance "$temp_metrics"
            ;;
        cpp)
            measure_cpp_performance "$temp_metrics"
            ;;
    esac

    # Merge with existing metrics
    if [ -f "$metrics_file" ]; then
        jq -s '.[0] * .[1]' "$metrics_file" "$temp_metrics" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    else
        cp "$temp_metrics" "$metrics_file"
    fi

    rm -f "$temp_metrics"
}

# Measure Python project performance
measure_python_performance() {
    local metrics_file="$1"

    log_info "Measuring Python project performance..."

    # Setup environment
    if [ ! -d ".venv" ]; then
        log_info "Creating virtual environment..."
        python3 -m venv .venv
    fi

    source .venv/bin/activate

    # Install dependencies if needed
    if [ -f "pyproject.toml" ]; then
        pip install -e .[dev] > /dev/null 2>&1
    fi

    # Measure linting performance
    local lint_time
    if command -v ruff &> /dev/null; then
        lint_time=$(time_command "ruff check .")
        jq --arg time "$lint_time" '.local_performance.linting_ruff_seconds = ($time | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Measure formatting performance
    local format_time
    if command -v ruff &> /dev/null; then
        format_time=$(time_command "ruff format --check .")
        jq --arg time "$format_time" '.local_performance.formatting_ruff_seconds = ($time | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Measure test performance
    local test_time
    if [ -d "tests" ] && command -v pytest &> /dev/null; then
        test_time=$(time_command "pytest tests/ -v")
        jq --arg time "$test_time" '.local_performance.testing_pytest_seconds = ($time | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Measure pre-commit performance
    local precommit_time
    if [ -f ".pre-commit-config.yaml" ] && command -v pre-commit &> /dev/null; then
        precommit_time=$(time_command "pre-commit run --all-files")
        jq --arg time "$precommit_time" '.local_performance.precommit_seconds = ($time | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Get project statistics
    local py_files
    py_files=$(find . -name "*.py" -not -path "./.venv/*" -not -path "./build/*" | wc -l)

    local loc
    loc=$(find . -name "*.py" -not -path "./.venv/*" -not -path "./build/*" -exec wc -l {} + | tail -1 | awk '{print $1}')

    jq --arg files "$py_files" --arg lines "$loc" '.local_performance.python_files = ($files | tonumber) | .local_performance.lines_of_code = ($lines | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
}

# Measure C++ project performance
measure_cpp_performance() {
    local metrics_file="$1"

    log_info "Measuring C++ project performance..."

    # Check for sccache
    local using_sccache=false
    if command -v sccache &> /dev/null; then
        using_sccache=true
        export CMAKE_C_COMPILER_LAUNCHER=sccache
        export CMAKE_CXX_COMPILER_LAUNCHER=sccache
    fi

    # Clean build
    rm -rf build

    # Measure configure time
    local configure_time
    if command -v cmake &> /dev/null; then
        configure_time=$(time_command "cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release")
        jq --arg time "$configure_time" '.local_performance.configure_cmake_seconds = ($time | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Measure build time (clean)
    local build_time
    if [ -d "build" ] && command -v cmake &> /dev/null; then
        build_time=$(time_command "cmake --build build -j\$(nproc)")
        jq --arg time "$build_time" '.local_performance.build_clean_seconds = ($time | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Measure test time
    local test_time
    if [ -d "build" ] && command -v ctest &> /dev/null; then
        test_time=$(time_command "ctest --test-dir build --output-on-failure -j\$(nproc)")
        jq --arg time "$test_time" '.local_performance.testing_ctest_seconds = ($time | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Get sccache statistics if available
    if [ "$using_sccache" = true ]; then
        local sccache_stats
        sccache_stats=$(sccache --show-stats 2>/dev/null || echo "{}")
        local cache_hits=$(echo "$sccache_stats" | jq -r '.cache_hits // 0')
        local cache_misses=$(echo "$sccache_stats" | jq -r '.cache_misses // 0')

        jq --arg hits "$cache_hits" --arg misses "$cache_misses" '.local_performance.sccache_cache_hits = ($hits | tonumber) | .local_performance.sccache_cache_misses = ($misses | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
    fi

    # Get project statistics
    local cpp_files
    cpp_files=$(find . -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" -o -name "*.c" | wc -l)

    local header_files
    header_files=$(find . -name "*.hpp" -o -name "*.hh" -o -name "*.hxx" -o -name "*.h" | wc -l)

    local loc
    loc=$(find . -name "*.cpp" -o -name "*.cc" -o -name "*.cxx" -o -name "*.c" -o -name "*.hpp" -o -name "*.hh" -o -name "*.hxx" -o -name "*.h" -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}')

    jq --arg cpp_files "$cpp_files" --arg header_files "$header_files" --arg lines "$loc" '.local_performance.cpp_source_files = ($cpp_files | tonumber) | .local_performance.cpp_header_files = ($header_files | tonumber) | .local_performance.lines_of_code = ($lines | tonumber)' "$metrics_file" > "${metrics_file}.tmp" && mv "${metrics_file}.tmp" "$metrics_file"
}

# Time a command and return duration in seconds
time_command() {
    local cmd="$1"
    local start_time=$(date +%s.%N)

    eval "$cmd" > /dev/null 2>&1 || true

    local end_time=$(date +%s.%N)
    echo "$(echo "$end_time - $start_time" | bc -l)"
}

# Generate performance report
generate_report() {
    local metrics_file="$1"
    local output_format="$2"

    case $output_format in
        json)
            jq '.' "$metrics_file"
            ;;
        csv)
            generate_csv_report "$metrics_file"
            ;;
        table)
            generate_table_report "$metrics_file"
            ;;
    esac
}

# Generate CSV report
generate_csv_report() {
    local metrics_file="$1"

    echo "metric,value,unit,timestamp"

    # Project info
    local project_name
    project_name=$(jq -r '.project.name' "$metrics_file")
    echo "project_name,$project_name,string,$(date -Iseconds)"

    # Local performance metrics
    if jq -e '.local_performance.linting_ruff_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.linting_ruff_seconds' "$metrics_file")
        echo "linting_ruff_time,$value,seconds,$(date -Iseconds)"
    fi

    if jq -e '.local_performance.testing_pytest_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.testing_pytest_seconds' "$metrics_file")
        echo "testing_pytest_time,$value,seconds,$(date -Iseconds)"
    fi

    if jq -e '.local_performance.build_clean_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.build_clean_seconds' "$metrics_file")
        echo "build_clean_time,$value,seconds,$(date -Iseconds)"
    fi

    # CI/CD metrics
    if jq -e '.cicd.average_duration_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.cicd.average_duration_seconds' "$metrics_file")
        echo "cicd_average_duration,$value,seconds,$(date -Iseconds)"
    fi

    if jq -e '.cicd.success_rate' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.cicd.success_rate' "$metrics_file")
        echo "cicd_success_rate,$value,percent,$(date -Iseconds)"
    fi
}

# Generate table report
generate_table_report() {
    local metrics_file="$1"

    echo ""
    echo "Performance Measurement Report"
    echo "============================="

    # Project info
    local project_name
    local project_type
    project_name=$(jq -r '.project.name' "$metrics_file")
    project_type=$(jq -r '.project.type' "$metrics_file")

    echo "Project: $project_name"
    echo "Type: $project_type"
    echo "Measured: $(jq -r '.local_performance.timestamp' "$metrics_file")"
    echo ""

    # Local performance
    echo "Local Development Performance"
    echo "----------------------------"

    if jq -e '.local_performance.linting_ruff_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.linting_ruff_seconds' "$metrics_file")
        printf "Ruff Linting:     %.3f seconds\n" "$value"
    fi

    if jq -e '.local_performance.formatting_ruff_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.formatting_ruff_seconds' "$metrics_file")
        printf "Ruff Formatting:  %.3f seconds\n" "$value"
    fi

    if jq -e '.local_performance.testing_pytest_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.testing_pytest_seconds' "$metrics_file")
        printf "pytest Testing:   %.3f seconds\n" "$value"
    fi

    if jq -e '.local_performance.configure_cmake_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.configure_cmake_seconds' "$metrics_file")
        printf "CMake Configure:  %.3f seconds\n" "$value"
    fi

    if jq -e '.local_performance.build_clean_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.build_clean_seconds' "$metrics_file")
        printf "Clean Build:      %.3f seconds\n" "$value"
    fi

    if jq -e '.local_performance.testing_ctest_seconds' "$metrics_file" > /dev/null; then
        local value
        value=$(jq -r '.local_performance.testing_ctest_seconds' "$metrics_file")
        printf "ctest Testing:    %.3f seconds\n" "$value"
    fi

    echo ""

    # Project statistics
    echo "Project Statistics"
    echo "------------------"

    if jq -e '.local_performance.python_files' "$metrics_file" > /dev/null; then
        local files
        local lines
        files=$(jq -r '.local_performance.python_files' "$metrics_file")
        lines=$(jq -r '.local_performance.lines_of_code' "$metrics_file")
        printf "Python Files: %d\n" "$files"
        printf "Lines of Code: %d\n" "$lines"
    fi

    if jq -e '.local_performance.cpp_source_files' "$metrics_file" > /dev/null; then
        local source_files
        local header_files
        local lines
        source_files=$(jq -r '.local_performance.cpp_source_files' "$metrics_file")
        header_files=$(jq -r '.local_performance.cpp_header_files' "$metrics_file")
        lines=$(jq -r '.local_performance.lines_of_code' "$metrics_file")
        printf "C++ Source Files: %d\n" "$source_files"
        printf "C++ Header Files: %d\n" "$header_files"
        printf "Lines of Code: %d\n" "$lines"
    fi

    echo ""

    # CI/CD metrics
    if jq -e '.cicd' "$metrics_file" > /dev/null; then
        echo "CI/CD Performance"
        echo "-----------------"

        local total_runs
        local success_rate
        local avg_duration
        total_runs=$(jq -r '.cicd.total_runs' "$metrics_file")
        success_rate=$(jq -r '.cicd.success_rate' "$metrics_file")
        avg_duration=$(jq -r '.cicd.average_duration_seconds' "$metrics_file")

        printf "Total Runs: %d\n" "$total_runs"
        printf "Success Rate: %.1f%%\n" "$success_rate"
        printf "Average Duration: %.1f seconds\n" "$avg_duration"

        if jq -e '.cicd.repository' "$metrics_file" > /dev/null; then
            local repo
            repo=$(jq -r '.cicd.repository' "$metrics_file")
            printf "Repository: %s\n" "$repo"
        fi
    fi

    echo ""
}

# Compare with baseline
compare_baseline() {
    local current_file="$1"
    local baseline_file="$2"

    log_info "Comparing with baseline: $baseline_file"

    echo ""
    echo "Baseline Comparison"
    echo "=================="

    # Extract key metrics
    local current_lint
    local baseline_lint
    current_lint=$(jq -r '.local_performance.linting_ruff_seconds // 0' "$current_file")
    baseline_lint=$(jq -r '.local_performance.linting_ruff_seconds // 0' "$baseline_file")

    if [ "$baseline_lint" != "0" ] && [ "$current_lint" != "0" ]; then
        local improvement
        improvement=$(echo "scale=1; ($baseline_lint - $current_lint) / $baseline_lint * 100" | bc -l)
        printf "Linting Time: %.3fs → %.3fs (%.1f%% %s)\n" \
            "$baseline_lint" "$current_lint" "$improvement" \
            "$(if (( $(echo "$improvement > 0" | bc -l) )); then echo "improvement"; else echo "regression"; fi)"
    fi

    local current_build
    local baseline_build
    current_build=$(jq -r '.local_performance.build_clean_seconds // 0' "$current_file")
    baseline_build=$(jq -r '.local_performance.build_clean_seconds // 0' "$baseline_file")

    if [ "$baseline_build" != "0" ] && [ "$current_build" != "0" ]; then
        local improvement
        improvement=$(echo "scale=1; ($baseline_build - $current_build) / $baseline_build * 100" | bc -l)
        printf "Build Time: %.3fs → %.3fs (%.1f%% %s)\n" \
            "$baseline_build" "$current_build" "$improvement" \
            "$(if (( $(echo "$improvement > 0" | bc -l) )); then echo "improvement"; else echo "regression"; fi)"
    fi

    echo ""
}

# Main execution
main() {
    log "Starting performance measurement..."

    # Check dependencies
    if ! command -v bc &> /dev/null; then
        log_error "bc is required for calculations. Please install: apt-get install bc"
        exit 1
    fi

    if ! command -v jq &> /dev/null; then
        log_error "jq is required for JSON processing. Please install: apt-get install jq"
        exit 1
    fi

    # Detect project type
    local project_type
    project_type=$(detect_project_type)
    log_info "Detected project type: $project_type"

    # Measure local performance
    measure_local_metrics "$project_type" "$METRICS_FILE"

    # Get GitHub metrics if available
    get_github_metrics "$METRICS_FILE"

    # Generate report
    generate_report "$METRICS_FILE" "$OUTPUT_FORMAT"

    # Compare with baseline if requested
    if [ "$COMPARE_WITH_BASELINE" = true ]; then
        compare_baseline "$METRICS_FILE" "$BASELINE_FILE"
    fi

    log "Performance measurement completed"
    log "Results saved to: $METRICS_FILE"
}

# Run main function with all arguments
main "$@"