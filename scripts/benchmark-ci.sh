#!/bin/bash
# CI Performance Benchmark Script
# Part of the CICD Template System - Phase 7.2

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
RUNS=3
OUTPUT_FORMAT="table"
SAVE_RESULTS=false

# Results storage
declare -A RESULTS
TIMES=()

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

Benchmark CI/CD performance for template-generated projects.

Arguments:
  project-directory    Path to project directory to benchmark

Options:
  -r, --runs N         Number of benchmark runs (default: 3)
  -f, --format FORMAT  Output format: table, json, csv (default: table)
  -s, --save           Save results to file
  -h, --help           Show this help message

Examples:
  $0 /path/to/python-project
  $0 -r 5 -f json -s /path/to/cpp-project
  $0 --runs 10 --format csv --save my-project

Supported Project Types:
  - Python projects (with pyproject.toml)
  - C++ projects (with CMakeLists.txt)

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--runs)
            RUNS="$2"
            shift 2
            ;;
        -f|--format)
            OUTPUT_FORMAT="$2"
            shift 2
            ;;
        -s|--save)
            SAVE_RESULTS=true
            shift
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

if ! [[ "$RUNS" =~ ^[0-9]+$ ]] || [ "$RUNS" -lt 1 ]; then
    log_error "Number of runs must be a positive integer"
    exit 1
fi

if [[ ! "$OUTPUT_FORMAT" =~ ^(table|json|csv)$ ]]; then
    log_error "Output format must be: table, json, or csv"
    exit 1
fi

# Detect project type
detect_project_type() {
    if [ -f "$PROJECT_DIR/pyproject.toml" ]; then
        echo "python"
    elif [ -f "$PROJECT_DIR/CMakeLists.txt" ]; then
        echo "cpp"
    else
        log_error "Unsupported project type. Must have pyproject.toml or CMakeLists.txt"
        exit 1
    fi
}

# Setup environment for Python projects
setup_python_env() {
    log_info "Setting up Python environment..."

    cd "$PROJECT_DIR"

    # Check for virtual environment
    if [ ! -d ".venv" ]; then
        log_info "Creating virtual environment..."
        python3 -m venv .venv
    fi

    # Activate virtual environment
    source .venv/bin/activate

    # Install dependencies
    if [ -f "pyproject.toml" ]; then
        log_info "Installing dependencies..."
        pip install -e .[dev] > /dev/null 2>&1
    fi

    # Install pre-commit hooks (for testing)
    if [ -f ".pre-commit-config.yaml" ]; then
        log_info "Installing pre-commit hooks..."
        pre-commit install > /dev/null 2>&1
    fi
}

# Setup environment for C++ projects
setup_cpp_env() {
    log_info "Setting up C++ environment..."

    cd "$PROJECT_DIR"

    # Check for sccache
    if command -v sccache &> /dev/null; then
        export CMAKE_C_COMPILER_LAUNCHER=sccache
        export CMAKE_CXX_COMPILER_LAUNCHER=sccache
        log_info "Using sccache for compilation caching"
    else
        log_warning "sccache not found, builds will be slower"
    fi
}

# Benchmark Python linting
benchmark_python_lint() {
    local description="Python Linting (Ruff)"
    local total_time=0

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        local start_time=$(date +%s.%N)
        ruff check . > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Benchmark Python formatting
benchmark_python_format() {
    local description="Python Formatting (Ruff)"
    local total_time=0

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        local start_time=$(date +%s.%N)
        ruff format --check . > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Benchmark Python testing
benchmark_python_test() {
    local description="Python Testing (pytest)"
    local total_time=0

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        local start_time=$(date +%s.%N)
        pytest tests/ -v > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Benchmark Python pre-commit
benchmark_python_precommit() {
    local description="Python Pre-commit Hooks"
    local total_time=0

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        local start_time=$(date +%s.%N)
        pre-commit run --all-files > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Benchmark C++ configure
benchmark_cpp_configure() {
    local description="C++ Configure (CMake)"
    local total_time=0

    # Clean build directory
    rm -rf build

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        local start_time=$(date +%s.%N)
        cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"

        # Clean for next run
        rm -rf build
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Benchmark C++ build (clean)
benchmark_cpp_build_clean() {
    local description="C++ Build (Clean)"
    local total_time=0

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        # Clean and configure
        rm -rf build
        cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1

        local start_time=$(date +%s.%N)
        cmake --build build -j$(nproc) > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Benchmark C++ build (incremental)
benchmark_cpp_build_incremental() {
    local description="C++ Build (Incremental)"
    local total_time=0

    # Initial build
    rm -rf build
    cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1
    cmake --build build -j$(nproc) > /dev/null 2>&1

    # Touch a source file to trigger rebuild
    touch src/main.cpp

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        local start_time=$(date +%s.%N)
        cmake --build build -j$(nproc) > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"

        # Touch file again for next run
        touch src/main.cpp
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Benchmark C++ testing
benchmark_cpp_test() {
    local description="C++ Testing (ctest)"
    local total_time=0

    # Ensure build exists
    if [ ! -d "build" ]; then
        cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release > /dev/null 2>&1
        cmake --build build -j$(nproc) > /dev/null 2>&1
    fi

    for i in $(seq 1 $RUNS); do
        log_info "Run $i/$RUNS: $description"

        local start_time=$(date +%s.%N)
        ctest --test-dir build --output-on-failure -j$(nproc) > /dev/null 2>&1
        local end_time=$(date +%s.%N)

        local duration=$(echo "$end_time - $start_time" | bc -l)
        total_time=$(echo "$total_time + $duration" | bc -l)
        TIMES+=("$duration")

        log_info "  Duration: ${duration}s"
    done

    local avg_time=$(echo "scale=3; $total_time / $RUNS" | bc -l)
    RESULTS["$description"]="$avg_time"
}

# Output results in table format
output_table() {
    echo ""
    echo "Benchmark Results"
    echo "================="
    echo "Project: $PROJECT_DIR"
    echo "Runs: $RUNS"
    echo "Date: $(date)"
    echo ""

    printf "%-30s | %-10s | %-15s\n" "Operation" "Avg Time" "Status"
    printf "%-30s-+-%-10s-+-%-15s\n" "------------------------------" "----------" "---------------"

    for operation in "${!RESULTS[@]}"; do
        local time="${RESULTS[$operation]}"
        local status="Good"

        # Determine status based on operation type and time
        if [[ "$operation" == *"Lint"* ]]; then
            if (( $(echo "$time > 10.0" | bc -l) )); then
                status="Slow"
            elif (( $(echo "$time < 2.0" | bc -l) )); then
                status="Fast"
            fi
        elif [[ "$operation" == *"Format"* ]]; then
            if (( $(echo "$time > 15.0" | bc -l) )); then
                status="Slow"
            elif (( $(echo "$time < 3.0" | bc -l) )); then
                status="Fast"
            fi
        elif [[ "$operation" == *"Build"* ]]; then
            if (( $(echo "$time > 300.0" | bc -l) )); then
                status="Slow"
            elif (( $(echo "$time < 60.0" | bc -l) )); then
                status="Fast"
            fi
        fi

        printf "%-30s | %-10.3fs | %-15s\n" "$operation" "$time" "$status"
    done

    echo ""

    # Performance analysis
    echo "Performance Analysis"
    echo "-------------------"

    # Calculate statistics
    local total_time=0
    local min_time=999999
    local max_time=0

    for time in "${RESULTS[@]}"; do
        total_time=$(echo "$total_time + $time" | bc -l)
        if (( $(echo "$time < $min_time" | bc -l) )); then
            min_time=$time
        fi
        if (( $(echo "$time > $max_time" | bc -l) )); then
            max_time=$time
        fi
    done

    local avg_time=$(echo "scale=3; $total_time / ${#RESULTS[@]}" | bc -l)

    echo "Operations benchmarked: ${#RESULTS[@]}"
    echo "Total average time: ${avg_time}s"
    echo "Fastest operation: ${min_time}s"
    echo "Slowest operation: ${max_time}s"
    echo ""
}

# Output results in JSON format
output_json() {
    local json="{"
    json+='"project":"'$PROJECT_DIR'",'
    json+='"runs":'$RUNS','
    json+='"date":"'$(date -Iseconds)'",'
    json+='"results":{'

    local first=true
    for operation in "${!RESULTS[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            json+=","
        fi
        json+='"'"$operation"'":'${RESULTS[$operation]}
    done

    json+='}}'

    echo "$json" | python3 -m json.tool
}

# Output results in CSV format
output_csv() {
    echo "operation,avg_time,project,runs,date"

    for operation in "${!RESULTS[@]}"; do
        echo "\"$operation\",${RESULTS[$operation]},\"$PROJECT_DIR\",$RUNS,\"$(date -Iseconds)\""
    done
}

# Save results to file
save_results() {
    local filename="benchmark-results-$(date +%Y%m%d-%H%M%S).${OUTPUT_FORMAT}"
    local filepath="$ROOT_DIR/$filename"

    log_info "Saving results to: $filepath"

    case $OUTPUT_FORMAT in
        json)
            output_json > "$filepath"
            ;;
        csv)
            output_csv > "$filepath"
            ;;
        table)
            output_table > "$filepath"
            ;;
    esac

    log_info "Results saved successfully"
}

# Main execution
main() {
    log "Starting CI/CD performance benchmark..."
    log_info "Project: $PROJECT_DIR"
    log_info "Runs: $RUNS"
    log_info "Output format: $OUTPUT_FORMAT"

    # Check dependencies
    if ! command -v bc &> /dev/null; then
        log_error "bc is required for calculations. Please install: apt-get install bc"
        exit 1
    fi

    # Detect project type and setup environment
    local project_type=$(detect_project_type)
    log_info "Detected project type: $project_type"

    case $project_type in
        python)
            setup_python_env
            benchmark_python_lint
            benchmark_python_format
            benchmark_python_test
            benchmark_python_precommit
            ;;
        cpp)
            setup_cpp_env
            benchmark_cpp_configure
            benchmark_cpp_build_clean
            benchmark_cpp_build_incremental
            benchmark_cpp_test
            ;;
    esac

    # Output results
    case $OUTPUT_FORMAT in
        table)
            output_table
            ;;
        json)
            output_json
            ;;
        csv)
            output_csv
            ;;
    esac

    # Save results if requested
    if [ "$SAVE_RESULTS" = true ]; then
        save_results
    fi

    log "Benchmark completed successfully"
}

# Run main function
main "$@"