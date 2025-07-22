#!/bin/bash
set -x # Print commands and their arguments as they are executed
# Define base path for our Agent
# Default values
INSTRUCTIONS_FILE="/home/instructions.txt"
VALIDATION_SCRIPT="/home/validate_submission.sh"
CONDA_ENV="mlzero"
# Determine hardware available
if command -v nvidia-smi &> /dev/null && nvidia-smi --query-gpu=name --format=csv,noheader &> /dev/null; then
 HARDWARE=$(nvidia-smi --query-gpu=name --format=csv,noheader \
| sed 's/^[ \t]*//' \
| sed 's/[ \t]*$//' \
| sort \
| uniq -c \
| sed 's/^ *\([0-9]*\) *\(.*\)$/\1 \2/' \
| paste -sd ', ' -)
else
 HARDWARE="a CPU"
fi
export HARDWARE
# Convert $TIME_LIMIT_SECS to more readable format for prompt
format_time() {
local time_in_sec=$1
local hours=$((time_in_sec / 3600))
local minutes=$(((time_in_sec % 3600) / 60))
local seconds=$((time_in_sec % 60))
echo "${hours}hrs ${minutes}mins ${seconds}secs"
}
export TIME_LIMIT=$(format_time $TIME_LIMIT_SECS)
# Activate conda environment
eval "$(conda shell.bash hook)"
if ! conda activate "$CONDA_ENV"; then
echo "Failed to activate conda environment '$CONDA_ENV'"
exit 1
fi
# Check GPU availability
echo "Checking GPU availability..."
python -c "import torch; print(torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'WARNING: No GPU')"
python -c "import tensorflow as tf; print('GPUs Available: ', tf.config.list_physical_devices('GPU'))"

# --------- Construct instructions for agent 
# Update instructions for agent-specific details: replace `/home/` paths to make paths relative
# (since the agent will have its own copies of these files in its workspace).
# e.g. /home/submission/submission.csv -> submission/submission.csv
sed -i 's|/home/||g' $INSTRUCTIONS_FILE
# further, add a linebreak and add the additional_notes (after substituting in env variables)
echo "" >> $INSTRUCTIONS_FILE
envsubst < /home/additional_notes.txt >> $INSTRUCTIONS_FILE

mkdir /home/extracted_data

cp $VALIDATION_SCRIPT ${AGENT_DIR}/validate_submission.sh
cp $VALIDATION_SCRIPT /home/extracted_data/validate_submission.sh
cp $INSTRUCTIONS_FILE ${AGENT_DIR}/full_instructions.txt
cp $INSTRUCTIONS_FILE /home/extracted_data/full_instructions.txt

# Create necessary directories
mkdir -p ${AGENT_DIR}/workspaces/exp
# Set up symbolic linking
#ln -s ${LOGS_DIR} ${AGENT_DIR}/workspaces/exp
#ln -s ${CODE_DIR} ${AGENT_DIR}/workspaces/exp/bestcode
#ln -s ${SUBMISSION_DIR} ${AGENT_DIR}/workspaces/bestsubmission
# Run the agent with timeout
echo "Starting the agent with a time limit of $TIME_LIMIT..."
timeout $TIME_LIMIT_SECS mlzero \
    -e "/home/extracted_data/" \
    -i "/home/data/" \
    -o "${AGENT_DIR}/workspaces/exp" \
    -n 8 \
    -v 2 \
    -t "Solve in 6 hours with best quality." \
2>&1 | tee "${AGENT_DIR}/workspaces/exp/run.log"
# Check if the process timed out
if [ $? -eq 124 ]; then
echo "Timed out after $TIME_LIMIT"
exit 1
fi
# Check if the process was successful
if [ $? -ne 0 ]; then
echo "Error: Agent execution failed. Please check ${LOGS_DIR}/auto2ml_log.txt for details."
conda deactivate
exit 1
fi

#copy files
cp ${AGENT_DIR}/workspaces/exp/results.csv ${SUBMISSION_DIR}/submission.csv
cp ${AGENT_DIR}/workspaces/exp/generation_iter_0/generated_code.py ${CODE_DIR}/code.py
cp ${AGENT_DIR}/workspaces/exp/run.log ${LOGS_DIR}/run.log

# Validate submission
echo "Validating submission..."
bash /home/validate_submission.sh ${SUBMISSION_DIR}/submission.csv
echo "Process completed successfully!"
conda deactivate
echo "Results saved under ${AGENT_DIR}/workspaces/exp"
ls ${AGENT_DIR}/workspaces/exp
ls ${LOGS_DIR}
ls ${SUBMISSION_DIR}
ls ${CODE_DIR}
