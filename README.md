[![build main](https://github.com/xchem/fragalysis-stack/actions/workflows/build-main.yaml/badge.svg)](https://github.com/xchem/fragalysis-stack/actions/workflows/build-main.yaml)

![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/xchem/fragalysis-stack)
[![License](http://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat)](https://github.com/xchem/fragalysis-stack/blob/master/LICENSE.txt)

# Fragalysis stack
Docker setup for building a Django, RDKit and Postgres stack with neo4j.

>   There is no application code in this repository, it is a repository where the
    stack application is *assembled* using environment variables that define the
    origin of the [Backend] and [Frontend] container images.

The stack is built and deployed using GitHub Actions and is deployed
to *staging* and *production* installations (**Namespaces** in a designated
Kubernetes cluster). If the build variables `DOCKERHUB_USERNAME` and
`TRIGGER_AWX` are defined staging deployments occur on every build
and production deployments occur on every *production-grade* tag.

You **MUST** make sure the Action variables that select the backend and frontend
container images are updated prior to every production release so the stack
uses the chosen backend and frontend code. You will find these variables
in the `.github/workflows/build-main.yaml` action file: -

- `BE_IMAGE_TAG`
- `FE_IMAGE_TAG`

## Local development
A docker-compose file provides a convenient way of launching the stack locally.
The suitability of the various docker-compose files is the responsibility of
the developer.

Check the compose file, adjust accordingly, then: -

    docker-compose up

---

[backend]: https://github.com/xchem/fragalysis-stack
[frontend]: https://github.com/xchem/fragalysis-frontend
