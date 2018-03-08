FROM abradle/fragalysis_backend:latest
# Add in the frontend code
RUN git clone https://github.com/xchem/fragalysis-frontend /code/assets
# Now install NPM

# Now build the code
RUN cd /code/assets && npm