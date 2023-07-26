[![build main](https://github.com/alanbchristie/fragalysis-stack/actions/workflows/build-main.yaml/badge.svg)](https://github.com/alanbchristie/fragalysis-stack/actions/workflows/build-main.yaml)

![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/xchem/fragalysis-stack)
[![License](http://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat)](https://github.com/xchem/fragalysis-stack/blob/master/LICENSE.txt)

# Fragalysis stack
Docker setup for building a Django, RDKit and Postgres stack with neo4j.
There is no application code in the repository, it is a repository where the
stack application is *assembled* using environment variables that define the
origin of the [Backend] (container image) and [Frontend] (code).

The "official" stack is built and deployed using GitHub Actions and is deployed
to production when tagged (with a production-grade tag).

When an official release is made you MUST make sure the default
backend and frontend variables are updated so the application is based on
the correct stable (tagged) backend and frontend code. Specifically: -

- `BE_IMAGE_TAG`
- `FE_BRANCH` (called "branch" but should be a frontend tag)

## Local development
A docker-compose file provides a convenient way of launching the stack locally.
The suitability of the various docker-compose files is the responsibility of
the developer.

Check the compose file, adjust accordingly then: -

    docker-compose up

---

[backend]: https://github.com/xchem/fragalysis-stack
[frontend]: https://github.com/xchem/fragalysis-frontend
