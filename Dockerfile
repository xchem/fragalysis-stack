FROM abradle/fragalysis_backend:latest
# Add in the frontend code
RUN git clone https://github.com/xchem/fragalysis-frontend /code/frontend
# Now add npm
RUN curl -sL https://deb.nodesource.com/setup_6.x | bash -
RUN apt-get install -y nodejs
# Now build the code
RUN cd /code/frontend && npm install
ADD docker-entrypoint.sh /code/docker-entrypoint.sh
# Symlink these
RUN mkdir /code/frontend/bundles/
RUN ln -s /code/frontend/bundles/ /code/static/bundles