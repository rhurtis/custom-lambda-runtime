# Define function directory
ARG FUNCTION_DIR="/function"
FROM python:buster as build-image
# Install aws-lambda-cpp build dependencies
RUN apt-get update && \
  apt-get install -y \
  g++ \
  make \
  cmake \
  unzip \
  libcurl4-openssl-dev
# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Create function directory
RUN mkdir -p ${FUNCTION_DIR}
# Copy function code
COPY home/app/ ${FUNCTION_DIR}
COPY requirements.txt requirements.txt
RUN pip install -r requirements.txt --target ${FUNCTION_DIR}
# Install the runtime interface client
RUN pip install \
        --target ${FUNCTION_DIR} \
        awslambdaric
# Multi-stage build: grab a fresh copy of the base image
FROM python:buster
# Install OpenJDK-11
RUN apt-get update && \
    apt-get install -y openjdk-11-jre-headless && \
    apt-get clean;

# Set JAVA_HOME as location of JAVA path.
RUN export JAVA_HOME=/usr/lib/java/java-11-openjdk-amd64

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}
# Copy in the build image dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
ENTRYPOINT [ "/usr/local/bin/python", "-m", "awslambdaric" ]
CMD [ "app.execute_extraction" ]
