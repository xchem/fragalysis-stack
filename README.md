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

[More information on pushing to production](README.md#pushing-a-release-to-production)

## Local development
A docker-compose file provides a convenient way of launching the stack locally.
The suitability of the various docker-compose files is the responsibility of
the developer.

Check the compose file, adjust accordingly then: -

    docker-compose up

## Pushing a release to production

1. Create new releases for the [Frontend] and [Backend].

    * [Create a new release for the frontend](https://github.com/xchem/fragalysis-frontend/releases/new)
        * Create a new tag with the format: `YYYY.MM.#` where:
            * `YYYY` is the current year
            * `MM` is the current month
            * `#` is the patch number (positive integer)
        * Choose a target: `staging` or `production`
        * Title the release
        * Describe the release
    * [Create a new release for the backend](https://github.com/xchem/fragalysis-backend/releases/new)
        * Same as the frontend

 2. Update [build-main.yaml](.github/workflows/build-main.yaml) with the new tags
    * Change `FE_BRANCH` to the desired Frontend tag
    * Change `BE_IMAGE_TAG` to the desired Backend tag
    * Commit the changes to a new branch and start a pull request
    * Wait for review and approval
    * Wait for the [GitHub action](https://github.com/xchem/fragalysis-stack/actions) to complete (~10-20mins)

> N.B. you can get the current Frontend, Backend, and Stack tags from the bottom of the Fragalysis menu

3. Create a new release for [fragalysis-stack](https://github.com/xchem/fragalysis-stack/releases/new)
   * Use the same tag convention as for the Frontend and Backend.
   * Tags do not need to agree across the three repositories!

---

[backend]: https://github.com/xchem/fragalysis-backend
[frontend]: https://github.com/xchem/fragalysis-frontend
