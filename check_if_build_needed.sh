#!/bin/bash -e

export DEBIAN_FRONTEND=noninteractive
PG_REPO_BASE="http://apt.postgresql.org/pub/repos/apt"
echo "deb [trusted=yes] http://apt.fury.io/abcfy2/ /" >/etc/apt/sources.list.d/fury.list

source /etc/os-release
if [ x"${USE_CHINA_MIRROR}" = x1 ]; then
  APT_MIRROR='mirror.sjtu.edu.cn'
  sed -i "s/deb.debian.org/${APT_MIRROR}/;s/security.debian.org/${APT_MIRROR}/" /etc/apt/sources.list
  PG_REPO_BASE="http://repo.huaweicloud.com/postgresql/repos/apt"
fi

apt-get update
apt-get install -y curl ca-certificates gnupg

curl -Ls --compressed https://www.postgresql.org/media/keys/ACCC4CF8.asc |
  gpg --dearmor |
  tee /etc/apt/trusted.gpg.d/apt.postgresql.org.gpg >/dev/null

echo "deb ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg.list
echo "deb-src ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg-src.list

apt-get update
pg_madison="$(apt-cache madison postgresql-${PG_MAJOR})"
if ! echo "${pg_madison}" | grep "${PG_REPO_BASE}" | grep -v 'Sources'; then
  echo "Official postgresql not found binary packages for postgresql-${PG_MAJOR}."
  pg_src_ver=($(echo "${pg_madison}" | grep "${PG_REPO_BASE}" | grep Sources | awk -F '|' '{print $2}' | tr -d ' '))
  echo "Find avaliable version in official src repo: ${pg_src_ver[@]}"
  fury_built_ver=($(echo "${pg_madison}" | grep "http://apt.fury.io/abcfy2" | awk -F '|' '{print $2}' | tr -d ' '))

  for ver in "${pg_src_ver[@]}"; do
    if ! printf '%s\n' "${fury_built_ver[@]}" | grep -qF -x '${ver}'; then
      echo "We should build postgresql-${PG_MAJOR}=${ver} for arch $(uname -m)"
    fi
  done

  pg_common_madison="$(apt-cache madison postgresql-common)"
  pg_common_src_ver=($(echo "${pg_common_madison}" | grep "${PG_REPO_BASE}" | grep Sources | awk -F '|' '{print $2}' | tr -d ' '))
  echo "Find avaliable postgresql-common version in official src repo: ${pg_common_src_ver[@]}"
  fury_pg_common_built_ver=($(echo "${pg_common_madison}" | grep "http://apt.fury.io/abcfy2" | awk -F '|' '{print $2}' | tr -d ' '))

  for ver in "${pg_common_src_ver[@]}"; do
    if ! printf '%s\n' "${fury_pg_common_built_ver[@]}" | grep -qF -x '${ver}'; then
      echo "We should build postgresql-common=${ver} for arch $(uname -m)"
    fi
  done
fi
