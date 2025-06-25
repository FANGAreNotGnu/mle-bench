rm agents/auto2ml/AutoMLAgent -r -f
cp /media/agent/AutoMLAgent -r agents/auto2ml/
export SUBMISSION_DIR=/home/submission
export LOGS_DIR=/home/logs
export CODE_DIR=/home/code
export AGENT_DIR=/home/agent
docker build --platform=linux/amd64 -t auto2ml agents/auto2ml/ --build-arg SUBMISSION_DIR=$SUBMISSION_DIR --build-arg LOGS_DIR=$LOGS_DIR --build-arg CODE_DIR=$CODE_DIR --build-arg AGENT_DIR=$AGENT_DIR
python run_agent.py --agent-id auto2ml --competition-set experiments/splits/multilabel.txt
bash submit_and_grade.sh 2025-05-02T08-14-24-GMT_run-group_auto2ml