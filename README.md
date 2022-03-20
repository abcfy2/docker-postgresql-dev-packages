# docker-postgresql-dev-packages

![CI](https://github.com/abcfy2/docker-postgresql-dev-packages/actions/workflows/ci.yml/badge.svg)

Add the missing postgresql-dev packages for postgres docker images.

## Why this project

Official [postgres docker image](https://hub.docker.com/_/postgres) supports multi-arch images. But postgresql official repository only contains `amd64`, `arm64`, and `ppc64el` until now.

If you want to build your own docker images based on official postgres docker image, you may have to build the missing `-dev` packages yourself, this will waste a lot of time.

In fact you can find official postgres docker image also build the missing packages in its [Dockerfile](https://github.com/docker-library/postgres/blob/e8ebf74e50128123a8d0220b85e357ef2d73a7ec/14/bullseye/Dockerfile#L138).

But they does not provide the missing postgresql-dev packages in docker images.

In order to save time I created this project to build the missing package for multi-arch images.

The built packages hosted on [Gemfury](https://gemfury.com/).

## How to use

Add my apt repository to `/etc/apt/sources.list.d/fury.list`:

```txt
deb [trusted=yes] https://apt.fury.io/abcfy2/ /
```

Note you should install `apt-transport-https` before.

A full example usage script run in docker:

```sh
echo "deb [trusted=yes] https://apt.fury.io/abcfy2/ /" >/etc/apt/sources.list.d/fury.list
apt-get update
# PG_MAJOR and PG_VERSION provide by postgres image
apt-get install -y postgresql-server-dev-${PG_MAJOR}=${PG_VERSION}
```

Also an example for Dockerfile can be found in: https://github.com/abcfy2/docker_zhparser/blob/main/Dockerfile.debian
