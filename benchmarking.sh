#!/bin/bash

# Configuration
DATASETS_FILE="${1:-example_datasets.txt}"
AGENT_ID="${2:-mlzero}"
N_RUNS="${3:-3}"

# Environment variables for Docker build
export SUBMISSION_DIR=/home/submission
export LOGS_DIR=/home/logs
export CODE_DIR=/home/code
export AGENT_DIR=/home/agent

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to get timestamp
get_timestamp() {
    date -u +"%Y%m%d_%H%M%S"
}

# Function to create a single dataset file
create_single_dataset_file() {
    local dataset="$1"
    local temp_file=$(mktemp)
    echo "$dataset" > "$temp_file"
    echo "$temp_file"
}

# Function to run a single dataset
run_single_dataset() {
    local dataset="$1"
    local run_id="$2"
    local timestamp="$3"

    print_status "Running dataset: $dataset (run $run_id : $timestamp)"
    
    # Create temporary file with single dataset
    local single_dataset_file=$(create_single_dataset_file "$dataset")
    
    # Create custom run directory name
    local custom_run_dir="${timestamp}_${dataset}_${AGENT_ID}"
    
    # Run the agent
    print_status "Executing run_agent.py for $dataset (run $timestamp)"
    if python run_agent.py \
        --agent-id "$AGENT_ID" \
        --competition-set "$single_dataset_file" \
        --run-dir "${custom_run_dir}"; then
        
        print_success "Successfully completed run_agent.py for $dataset (run $timestamp)"
        
        # Find the actual run group directory created by run_agent.py
        # local run_group_dir=$(find "$custom_run_dir" -maxdepth 1 -type d -name "*run-group*" | head -1)
        
        # if [ -z "$run_group_dir" ]; then
            # If no run-group directory found, use the base directory
        #     run_group_dir="$custom_run_dir"
        # fi
        
        # Extract just the directory name for submit_and_grade.sh
        # local run_group_name=$(basename "$run_group_dir")
        
        # Run submit_and_grade.sh
        print_status "Executing submit_and_grade.sh for $dataset (run $timestamp)"
        if bash submit_and_grade.sh "$custom_run_dir"; then
            print_success "Successfully completed submit_and_grade.sh for $dataset (run $timestamp)"
        else
            print_error "Failed to execute submit_and_grade.sh for $dataset (run $timestamp)"
        fi
    else
        print_error "Failed to execute run_agent.py for $dataset (run $timestamp)"
    fi
    
    # Clean up temporary file
    rm -f "$single_dataset_file"
}

# Main script
main() {
    print_status "Starting dataset runs with configuration:"
    print_status "  Datasets file: $DATASETS_FILE"
    print_status "  Agent ID: $AGENT_ID"
    print_status "  Number of runs per dataset: $N_RUNS"
    
    # Check if datasets file exists
    if [ ! -f "$DATASETS_FILE" ]; then
        print_error "Datasets file '$DATASETS_FILE' not found!"
        exit 1
    fi
    
    # Build Docker image
    print_status "Building Docker image for agent: $AGENT_ID"
    if docker build --platform=linux/amd64 --no-cache -t "$AGENT_ID" "agents/$AGENT_ID/" \
        --build-arg SUBMISSION_DIR="$SUBMISSION_DIR" \
        --build-arg LOGS_DIR="$LOGS_DIR" \
        --build-arg CODE_DIR="$CODE_DIR" \
        --build-arg AGENT_DIR="$AGENT_DIR"; then
        print_success "Docker image built successfully"
    else
        print_error "Failed to build Docker image"
        exit 1
    fi
    
    # Read datasets and run each one
    local datasets=()
    while IFS= read -r line; do
        # Skip empty lines and comments
        if [[ -n "$line" && ! "$line" =~ ^[[:space:]]*# ]]; then
            datasets+=("$line")
        fi
    done < "$DATASETS_FILE"
    
    if [ ${#datasets[@]} -eq 0 ]; then
        print_error "No datasets found in $DATASETS_FILE"
        exit 1
    fi
    
    print_status "Found ${#datasets[@]} datasets to process"
    
    # Track overall progress
    local total_runs=$((${#datasets[@]} * N_RUNS))
    local current_run=0
    
    # Run each dataset N times
    for dataset in "${datasets[@]}"; do
        print_status "Processing dataset: $dataset"
        
        for run_id in $(seq 1 "$N_RUNS"); do
            current_run=$((current_run + 1))
            local timestamp=$(get_timestamp)
            
            print_status "Progress: $current_run/$total_runs"
            run_single_dataset "$dataset" "$run_id" "$timestamp"
            
            # Add a small delay between runs to ensure unique timestamps
            sleep 2
        done
        
        print_success "Completed all runs for dataset: $dataset"
    done
    
    print_success "All datasets completed!"
}

# Help function
show_help() {
    cat << EOF
Usage: $0 [DATASETS_FILE] [AGENT_ID] [N_RUNS]

Run multiple datasets with an agent, executing each dataset N times.

Arguments:
  DATASETS_FILE   Path to file containing dataset names (default: example_datasets.txt)
  AGENT_ID        Agent identifier (default: mlzero)
  N_RUNS          Number of runs per dataset (default: 3)

Examples:
  $0                                    # Use all defaults
  $0 my_datasets.txt                    # Custom datasets file
  $0 my_datasets.txt myagent            # Custom datasets and agent
  $0 my_datasets.txt myagent 5          # Custom datasets, agent, and 5 runs
  $0 my_datasets.txt myagent 5 /tmp/runs # All custom parameters

The script will create directories with the format:
  <timestamp>_<dataset>_<agent_name>

EOF
}

# Check for help flag
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
fi

# Run main function
main "$@"
