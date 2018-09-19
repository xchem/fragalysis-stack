FROM xchem/fragalysis-backend:latest

ENV APP_ROOT /code
ENV APP_USER_ID 2000
RUN useradd -c 'Container user' --user-group --uid ${APP_USER_ID} --home-dir ${APP_ROOT} -s /bin/bash frag

RUN apt-get install -y wget gnupg bzip2
# Add in the frontend code
RUN git clone https://github.com/xchem/fragalysis-frontend ${APP_ROOT}/frontend
# Now add npm
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
# Now build the code
RUN npm install -g npm@5.6.0
RUN cd ${APP_ROOT}/frontend && npm install
RUN cd ${APP_ROOT}/frontend && npm run build
ADD docker-entrypoint.sh ${APP_ROOT}/docker-entrypoint.sh

# Symlink these
RUN mkdir ${APP_ROOT}/static
RUN ln -s ${APP_ROOT}/frontend/bundles/ ${APP_ROOT}/static/bundles

RUN chmod 755 ${APP_ROOT}/docker-entrypoint.sh
RUN chmod 755 ${APP_ROOT}/makemigrations.sh
RUN chmod 755 ${APP_ROOT}/launch-stack.sh

RUN chown -R ${APP_USER_ID} ${APP_ROOT} /run /var

WORKDIR ${APP_ROOT}
CMD ["./docker-entrypoint.sh"]
