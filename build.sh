#!/bin/bash -e

echo "Build postgresql-server-dev-${PG_MAJOR}=${PG_VERSION} for arch $(uname -m)"

export DEBIAN_FRONTEND=noninteractive
nproc="$(nproc)"
export DEB_BUILD_OPTIONS="nocheck parallel=$nproc"
PG_REPO_BASE="http://apt.postgresql.org/pub/repos/apt"
MY_OWN_APT="https://apt.fury.io/abcfy2"

SELF_DIR="$(dirname "$(realpath "${0}")")"
source /etc/os-release
if [ x"${USE_CHINA_MIRROR}" = x1 ]; then
  APT_MIRROR='mirror.sjtu.edu.cn'
  sed -i "s/deb.debian.org/${APT_MIRROR}/;s/security.debian.org/${APT_MIRROR}/" /etc/apt/sources.list
  PG_REPO_BASE="http://repo.huaweicloud.com/postgresql/repos/apt"
fi

apt-get update
apt-get install -y apt-transport-https ca-certificates

echo "deb [trusted=yes] ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg.list
echo "deb-src [trusted=yes] ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg-src.list
echo "deb [trusted=yes] ${MY_OWN_APT} /" >/etc/apt/sources.list.d/fury.list

apt-get update

tempDir="$(mktemp -d)"
cd "$tempDir"
apt-get build-dep -y postgresql-${PG_MAJOR}=${PG_VERSION}
apt-get source --compile postgresql-${PG_MAJOR}=${PG_VERSION}
cp -fv "$tempDir"/*.deb "${SELF_DIR}"
