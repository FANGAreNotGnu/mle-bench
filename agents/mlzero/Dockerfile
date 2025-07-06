FROM mlebench-env
# where to put submission.csv, will be extracted
ARG SUBMISSION_DIR
ENV SUBMISSION_DIR=${SUBMISSION_DIR}
# where to put any logs, will be extracted
ARG LOGS_DIR
ENV LOGS_DIR=${LOGS_DIR}
# where to put any code, will be extracted
ARG CODE_DIR
ENV CODE_DIR=${CODE_DIR}
# where to put any other agent-specific files, will not be necessarily extracted
ARG AGENT_DIR
ENV AGENT_DIR=${AGENT_DIR}
RUN mkdir -p ${LOGS_DIR} ${CODE_DIR} ${AGENT_DIR}
# Specify the name of the conda environment to use
ENV CONDA_ENV_NAME=mlzero
# Create new conda environment
RUN conda create -n ${CONDA_ENV_NAME} python=3.11 -y
# Put all the agent files in the expected location
COPY . ${AGENT_DIR}
RUN eval "$(conda shell.bash hook)" && \
    conda activate ${CONDA_ENV_NAME} && \
    # Install with constraints
    python3 -m pip install uv && \
    cd ${AGENT_DIR} && \
    git clone -b mlebench0625 https://github.com/FANGAreNotGnu/autogluon-assistant.git && \
    python3 -m uv pip install -e autogluon-assistant && \
    conda deactivate
# Set the working directory
WORKDIR ${AGENT_DIR}