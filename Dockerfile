ARG BE_NAMESPACE=xchem
ARG BE_IMAGE_TAG=latest
FROM ${BE_NAMESPACE}/fragalysis-backend:${BE_IMAGE_TAG}

ENV APP_ROOT /code

# Install yarn
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get update -y && \
    apt-get install -y \
        yarn && \
    apt-get clean

# Install nodejs
RUN wget -q https://nodejs.org/download/release/v12.22.11/node-v12.22.11-linux-x64.tar.gz && \
    mkdir -p /usr/local/lib/nodejs && \
    tar -xf node-v12.22.11-linux-x64.tar.gz -C /usr/local/lib/nodejs && \
    rm node-v12.22.11-linux-x64.tar.gz
ENV PATH /usr/local/lib/nodejs/node-v12.22.11-linux-x64/bin:$PATH

ADD docker-entrypoint.sh ${APP_ROOT}/docker-entrypoint.sh
ADD LICENSE /LICENSE
ADD README.md /README.md
RUN chmod 755 ${APP_ROOT}/docker-entrypoint.sh

# Add in the frontend code
# By default this is hosted on the xchem project's master branch
# but it can be redirected with a couple of build-args.
# And then continue to build it.
WORKDIR ${APP_ROOT}/static
ARG FE_NAMESPACE=xchem
ARG FE_BRANCH=master
RUN git clone https://github.com/${FE_NAMESPACE}/fragalysis-frontend ${APP_ROOT}/frontend && \
    cd ${APP_ROOT}/frontend && git checkout ${FE_BRANCH} && \
    cd ${APP_ROOT}/frontend && yarn install && \
    cd ${APP_ROOT}/frontend && yarn run build && \
    ln -s ${APP_ROOT}/frontend/bundles/ ${APP_ROOT}/static/bundles

WORKDIR ${APP_ROOT}
CMD ["./docker-entrypoint.sh"]
