export SUBMISSION_DIR=/home/submission
export LOGS_DIR=/home/logs
export CODE_DIR=/home/code
export AGENT_DIR=/home/agent
docker build --platform=linux/amd64 -t mlzero agents/mlzero/ --build-arg SUBMISSION_DIR=$SUBMISSION_DIR --build-arg LOGS_DIR=$LOGS_DIR --build-arg CODE_DIR=$CODE_DIR --build-arg AGENT_DIR=$AGENT_DIR
python run_agent.py --agent-id mlzero --competition-set experiments/splits/test.txt
bash submit_and_grade.sh 2025-07-01T01-15-27-GMT_run-group_mlzero