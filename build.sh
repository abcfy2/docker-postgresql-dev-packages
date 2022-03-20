#!/bin/bash -e

echo "Build postgresql-server-dev-${PG_MAJOR}=${PG_VERSION} for arch $(uname -m)"

export DEBIAN_FRONTEND=noninteractive
nproc="$(nproc)"
export DEB_BUILD_OPTIONS="nocheck parallel=$nproc"
PG_REPO_BASE="http://apt.postgresql.org/pub/repos/apt"

echo 'Acquire::https::Verify-Peer "false";
Acquire::https::Verify-Host "false";' >/etc/apt/apt.conf.d/99-disable-verify.conf

SELF_DIR="$(dirname "$(realpath "${0}")")"
source /etc/os-release
if [ x"${USE_CHINA_MIRROR}" = x1 ]; then
  APT_MIRROR='mirror.sjtu.edu.cn'
  sed -i "s/deb.debian.org/${APT_MIRROR}/;s/security.debian.org/${APT_MIRROR}/" /etc/apt/sources.list
  PG_REPO_BASE="http://repo.huaweicloud.com/postgresql/repos/apt"
fi

echo "deb [trusted=yes] ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg.list
echo "deb-src [trusted=yes] ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg-src.list
echo "deb [trusted=yes] http://apt.fury.io/abcfy2/ /" >/etc/apt/sources.list.d/fury.list

_update_repo() {
  dpkg-scanpackages . >Packages
  apt-get -o Acquire::GzipIndexes=false update
}

apt-get update

tempDir="$(mktemp -d)"
cd "$tempDir"
apt-get build-dep -y postgresql-server-dev-${PG_MAJOR}=${PG_VERSION}
apt-get source --compile postgresql-server-dev-${PG_MAJOR}=${PG_VERSION}
_update_repo
cp -fv "$tempDir"/*.deb "${SELF_DIR}"
