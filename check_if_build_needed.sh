#!/bin/bash -e

ARCH="$(dpkg --print-architecture)"
export DEBIAN_FRONTEND=noninteractive
nproc="$(nproc)"
export DEB_BUILD_OPTIONS="nocheck parallel=$nproc"
PG_REPO_BASE="http://apt.postgresql.org/pub/repos/apt"
MY_OWN_APT="https://apt.fury.io/abcfy2"

SELF_DIR="$(dirname "$(realpath "${0}")")"
source /etc/os-release
if [ x"${USE_CHINA_MIRROR}" = x1 ]; then
  APT_MIRROR='mirror.sjtu.edu.cn'
  for f in /etc/apt/sources.list /etc/apt/sources.list.d/debian.sources; do
    if [ -f ${f} ]; then
      sed -i "s/deb.debian.org/${APT_MIRROR}/;s/security.debian.org/${APT_MIRROR}/" "${f}"
    fi
  done
  PG_REPO_BASE="http://mirrors.tencent.com/postgresql/repos/apt"
fi

apt-get update
apt-get install -y apt-transport-https ca-certificates

echo "deb [trusted=yes] ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg.list
echo "deb-src [trusted=yes] ${PG_REPO_BASE} ${VERSION_CODENAME}-pgdg main" >/etc/apt/sources.list.d/pgdg-src.list
echo "deb [trusted=yes] ${MY_OWN_APT} /" >/etc/apt/sources.list.d/fury.list

apt-get update
pg_madison="$(apt-cache madison postgresql-${PG_MAJOR})"
if ! echo "${pg_madison}" | grep "${PG_REPO_BASE}" | grep -v 'Sources'; then
  echo "Official postgresql repository not found binary packages for postgresql-${PG_MAJOR}."
  pg_src_ver=($(echo "${pg_madison}" | grep "${PG_REPO_BASE}" | grep Sources | awk -F '|' '{print $2}' | tr -d ' '))
  echo "Find avaliable version in official source repository: ${pg_src_ver[@]}"
  fury_built_ver=($(echo "${pg_madison}" | grep "${MY_OWN_APT}" | awk -F '|' '{print $2}' | tr -d ' '))

  echo -n >"${SELF_DIR}/should_build_ver"
  for ver in "${pg_src_ver[@]}"; do
    if ! printf '%s\n' "${fury_built_ver[@]}" | grep -qF -x "${ver}"; then
      echo "We should build postgresql-${PG_MAJOR}=${ver} for arch ${ARCH}"
      echo "${ver}" >>"${SELF_DIR}/should_build_ver"
    else
      echo "We've already built postgresql-${PG_MAJOR}=${ver} for arch ${ARCH}"
    fi
  done

  pg_common_madison="$(apt-cache madison postgresql-common)"
  pg_common_src_ver=($(echo "${pg_common_madison}" | grep "${PG_REPO_BASE}" | grep Sources | awk -F '|' '{print $2}' | tr -d ' '))
  echo "Find avaliable postgresql-common version in official src repo: ${pg_common_src_ver[@]}"
  fury_pg_common_built_ver=($(echo "${pg_common_madison}" | grep "${MY_OWN_APT}" | awk -F '|' '{print $2}' | tr -d ' '))

  for ver in "${pg_common_src_ver[@]}"; do
    if ! printf '%s\n' "${fury_pg_common_built_ver[@]}" | grep -qF -x "${ver}"; then
      echo "We should build postgresql-common=${ver} for arch ${ARCH}"
      tempDir="$(mktemp -d)"
      cd "$tempDir"
      apt-get build-dep -y postgresql-common=${ver} pgdg-keyring
      apt-get source --compile postgresql-common=${ver} pgdg-keyring
      cp -fv "$tempDir"/*.deb "${SELF_DIR}"
    else
      echo "We've already built postgresql-common=${ver} for arch ${ARCH}"
    fi
  done
fi
