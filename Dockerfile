ARG BE_NAMESPACE=xchem
ARG BE_IMAGE_TAG=latest
ARG FE_NAMESPACE=xchem
ARG FE_IMAGE_TAG=master
ARG STACK_NAMESPACE=xchem
ARG STACK_VERSION=0.0.0
# Start with the frontend container image AS 'frontend'.
# As part of the build we will copy the contents of its '/frontend' directory
# into the backend image that we also pull in.
FROM ${FE_NAMESPACE}/fragalysis-frontend:${FE_IMAGE_TAG} AS frontend

# We have to repeat the ARG assignments...
# ARGs are reset during the FROM action
# See https://docs.docker.com/engine/reference/builder/#understand-how-arg-and-from-interact

# Us
ARG STACK_NAMESPACE
ARG STACK_VERSION
# Backend image identity
ARG BE_NAMESPACE
ARG BE_IMAGE_TAG
# Frontend image identity
ARG FE_NAMESPACE
ARG FE_IMAGE_TAG

# Get the backend image
# (we'll copy the pre-compiled forntend into it)
FROM ${BE_NAMESPACE}/fragalysis-backend:${BE_IMAGE_TAG}

# We have to repeat the ARG assignments...
ARG STACK_NAMESPACE
ARG STACK_VERSION
ARG BE_NAMESPACE
ARG BE_IMAGE_TAG
ARG FE_NAMESPACE
ARG FE_IMAGE_TAG

# Set the container ENV to record the origin of the b/e and f/e
# (for diagnostic purposes)
ENV BE_NAMESPACE ${BE_NAMESPACE}
ENV BE_IMAGE_TAG ${BE_IMAGE_TAG}
ENV FE_NAMESPACE ${FE_NAMESPACE}
ENV FE_IMAGE_TAG ${FE_IMAGE_TAG}
ENV STACK_NAMESPACE ${STACK_NAMESPACE}
ENV STACK_VERSION ${STACK_VERSION}

ENV APP_ROOT /code

# Copy the frontend code from the frontend container
WORKDIR ${APP_ROOT}/frontend
WORKDIR ${APP_ROOT}/static

COPY --from=frontend /frontend ${APP_ROOT}/frontend
RUN ln -s ${APP_ROOT}/frontend/bundles/ ${APP_ROOT}/static/bundles

WORKDIR ${APP_ROOT}
# The entrypoint is a responsibility of the backend image
CMD ["./docker-entrypoint.sh"]
