FROM python:3.11

# System setup
ENV HOME=/root
ENV APP=/var/app
ENV PATH=$PATH:/usr/bin/ix
RUN mkdir -p /usr/bin/ix
COPY bin/* /usr/bin/ix/
RUN mkdir -p $APP
RUN apt update -y && apt install -y curl postgresql-client make

# Pass Django secret key as an environment variable at runtime
# ENV DJANGO_SECRET_KEY=your-secret-key

# NVM / NPM Setup
ENV NVM_DIR=/usr/local/nvm
ENV NPM_DIR=$APP
ENV NODE_VERSION=18.15.0
ENV NODE_MODULES=$NPM_DIR/node_modules

RUN mkdir -p $NVM_DIR
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh | bash && \
    . $NVM_DIR/nvm.sh && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION && \
    nvm use default

ENV NODE_PATH $NVM_DIR/v$NODE_VERSION/lib/node_modules
ENV PATH $NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH
ENV NODE_MODULES_BIN=$NPM_DIR/node_modules/.bin
ENV PATH $PATH:$NODE_MODULES_BIN

# NPM package installs
RUN echo "[$NPM_DIR]"
COPY package.json $NPM_DIR

ENV WEBPACK_OUTPUT=/var/compiled-static

# Set the working directory
WORKDIR $APP

# Copy requirements.txt to the working directory
COPY requirements.txt .

# Install Python requirements
RUN pip install -r requirements.txt

# Copy the rest of the application code to the working directory
COPY . .

# Copy start.sh script to the working directory
COPY start.sh .

# Set the environment variable for selecting between ASGI and Celery
ENV APP_MODE=asgi

# Make start.sh script executable
RUN chmod +x start.sh

# Expose port 8000 for ASGI, or leave it unexposed for Celery
EXPOSE 8000

# Start the application using the start.sh script
CMD ["./start.sh"]
