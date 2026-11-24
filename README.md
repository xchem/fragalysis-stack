[![build main](https://github.com/xchem/fragalysis-stack/actions/workflows/build-main.yaml/badge.svg)](https://github.com/xchem/fragalysis-stack/actions/workflows/build-main.yaml)

![GitHub tag (latest SemVer pre-release)](https://img.shields.io/github/v/tag/xchem/fragalysis-stack)
[![License](http://img.shields.io/badge/license-Apache%202.0-blue.svg?style=flat)](https://github.com/xchem/fragalysis-stack/blob/master/LICENSE.txt)

# Fragalysis stack

Docker setup for building a Django, RDKit and Postgres stack with neo4j.

>   There is no application code in this repository, it is a repository where the
    stack application is *assembled* using environment variables that define the
    origin of the [Backend] and [Frontend] container images.

The stack is built and orchestrated using GitHub Actions and is deployed
to *staging* and *production* installations (**Namespaces** in a designated
Kubernetes cluster).

The build variables `DOCKERHUB_USERNAME` and `TRIGGER_AWX` must be defined
for orchestration to take place. Staging deployments take place on every downstream
build (frontend and backend) and tag, and production deployments take place on every tag.

You **MUST** make sure the Action variables that select the backend and frontend
container images are updated prior to every production release so the stack
uses the appropriate backend and frontend code. You will find these variables
in the `.github/workflows/build-main.yaml` action file: -

- `BE_IMAGE_TAG`
- `FE_IMAGE_TAG`

[More information on pushing to production](README.md#pushing-a-release-to-production)

## Local development

A docker-compose file provides a convenient way of launching the stack locally.
The suitability of the various docker-compose files is the responsibility of
the developer.

Check the compose file, adjust accordingly, then: -

    docker-compose up -d

>   Containers in the docker-compose generally store persistent data in
    the `./data` directory of this repository. These directories
    are created automatically if they do not exist.

When you're done you can tear everything down with: -

    docker-compose down

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
    * Change `FE_IMAGE_TAG` to the desired Frontend tag
    * Change `BE_IMAGE_TAG` to the desired Backend tag
    * Commit the changes to a new branch and start a pull request
    * Wait for review and approval
    * Wait for the [GitHub action](https://github.com/xchem/fragalysis-stack/actions) to complete (~10-20mins)

> N.B. you can get the current Frontend, Backend, and Stack tags from the bottom of the Fragalysis menu

3. Create a new release for [fragalysis-stack](https://github.com/xchem/fragalysis-stack/releases/new)
   * Use the same tag convention as for the Frontend and Backend.
   * Tags do not need to agree across the three repositories!

## Security builds

The security build lets users test security patches before we release them
to production (issue #139).

### The pipeline

1. In the [Backend] and the [Frontend], Dependabot sends dependency updates
   to the `security` branch. The `security` branch is a patch branch of `production`.
2. An auto-merge workflow merges the updates that fix an alert
   at or above a minimum severity.
3. Each day, the Backend and the Frontend build their `security` branch.
   Each build pushes a `security` image to Docker Hub.
4. Each day at 07:30 (UTC), the [build security](.github/workflows/build-security.yaml)
   workflow in this repository builds a stack from the two `security` images.
5. The workflow pushes the stack image with two tags: `security-YYYYMMDD`
   (the UTC date of the build) and `security`.
6. The workflow runs the **Security Fragalysis Stack** AWX Job Template
   on the developer AWX server. The job deploys the dated image to the
   `security-stack` Namespace of the developer cluster.

The workflow never deploys to staging or production.

You can also start the workflow manually from the
[Actions](https://github.com/xchem/fragalysis-stack/actions/workflows/build-security.yaml) tab.
A second build on the same day replaces the image for that date.

### Configuration

The workflow needs these repository secrets: -

- `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN`, to push the images
- `TRIGGER_SECURITY_AWX`, set to `yes`, to deploy the images

It also needs the repository environment `awx/fragalysis-security`,
with the secrets `AWX_HOST`, `AWX_USER` and `AWX_USER_PASSWORD`
for the developer AWX server.

### Releasing a tested security build

When users approve the security build, release the patches to production: -

1. Release the `security` branch of the [Backend] to production.
   Follow the "Security patches" section of the Backend README.
2. Do the same for the [Frontend], if its `security` branch has patches.
3. Release this repository as described in
   [Pushing a release to production](#pushing-a-release-to-production).
   Change only the image tags of the repositories that you released.

Steps 1 and 2 also merge the patches back into `staging` and update `security`.

---

[backend]: https://github.com/xchem/fragalysis-backend
[frontend]: https://github.com/xchem/fragalysis-frontend
