#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive
PG_REPO_BASE="http://apt.postgresql.org/pub/repos/apt"
echo "deb [trusted=yes] http://apt.fury.io/abcfy2/ /" >/etc/apt/sources.list.d/fury.list

_update_repo() {
  dpkg-scanpackages . >Packages
  apt-get -o Acquire::GzipIndexes=false update
}

if [ x"${USE_CHINA_MIRROR}" = x1 ]; then
  source /etc/os-release
  cat >/etc/apt/sources.list <<EOF
deb http://mirror.sjtu.edu.cn/${ID} ${VERSION_CODENAME} main
deb http://mirror.sjtu.edu.cn/${ID}-security ${VERSION_CODENAME}/updates main
deb http://mirror.sjtu.edu.cn/${ID} ${VERSION_CODENAME}-updates main
EOF

  PG_REPO_BASE="http://repo.huaweicloud.com/postgresql/repos/apt/"
fi

apt-get update
apt-get install -y curl ca-certificates gnupg

curl -Ls --compressed https://www.postgresql.org/media/keys/ACCC4CF8.asc |
  gpg --dearmor |
  tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null

echo "deb ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg.list
echo "deb-src ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg-src.list

apt-get update

nproc="$(nproc)"
export DEB_BUILD_OPTIONS="nocheck parallel=$nproc"

tempDir="$(mktemp -d)"
echo "deb [ trusted=yes ] file://$tempDir ./" >/etc/apt/sources.list.d/temp.list

pg_madison="$(apt-cache madison postgresql-14)"
if ! echo "${pg_madison}" | grep "${PG_REPO_BASE}" | grep -v 'Sources'; then
  echo "Not found postgresql-14 binary package, so consider we should build packages for this environment."

  pg_common_madison="$(apt-cache madison postgresql-common)"
  if ! echo "${pg_common_madison}" | grep "${PG_REPO_BASE}" | grep -v 'Sources'; then
    echo "Not found postgresql-common binary package, so consider we should build it first."
    cd "$tempDir"
    apt-get build-dep -y postgresql-common pgdg-keyring
    apt-get source --compile postgresql-common pgdg-keyring
    _update_repo
  fi

  apt-get build-dep -y postgresql-server-dev-14
  apt-get source --compile postgresql-server-dev-14
fi
