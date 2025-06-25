#!/bin/bash

# Check if experiment name is provided
if [ $# -eq 0 ]; then
    echo "Error: Experiment name is required as an argument"
    echo "Usage: $0 <experiment-name>"
    exit 1
fi

# Store the experiment name from argument
EXPERIMENT_NAME=$1

# Run the Python script
python experiments/make_submission.py --metadata runs/${EXPERIMENT_NAME}/metadata.json --output runs/${EXPERIMENT_NAME}/submission.jsonl

# Run the grading command
mlebench grade --submission runs/${EXPERIMENT_NAME}/submission.jsonl --output-dir runs/${EXPERIMENT_NAME}

echo "Processing completed for experiment: ${EXPERIMENT_NAME}"
