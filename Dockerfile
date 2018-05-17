FROM xchem/fragalysis-backend:latest

ENV APP_ROOT /code
ENV APP_USER_ID 2000
RUN useradd -c 'Conatiner user' --user-group --uid ${APP_USER_ID} --home-dir ${APP_ROOT} -s /bin/bash frag

RUN apt-get install -y wget gnupg
# Add in the frontend code
RUN git clone https://github.com/xchem/fragalysis-frontend ${APP_ROOT}/frontend
# Now add npm
RUN curl -sL https://deb.nodesource.com/setup_8.x | bash -
RUN apt-get install -y nodejs
# Now build the code
RUN cd ${APP_ROOT}/frontend && npm install
ADD docker-entrypoint.sh ${APP_ROOT}/docker-entrypoint.sh

# Symlink these
RUN mkdir ${APP_ROOT}/frontend/bundles/
RUN mkdir ${APP_ROOT}/static
RUN ln -s ${APP_ROOT}/frontend/bundles/ ${APP_ROOT}/static/bundles

RUN chmod 755 ${APP_ROOT}/docker-entrypoint.sh
RUN chown -R 2000 ${APP_ROOT} /run /etc /var

WORKDIR ${APP_ROOT}
CMD ["./docker-entrypoint.sh"]