#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLCHAIN_ROOT="${HOME}/.crosswake/android-toolchain"
SDK_ROOT="${ANDROID_SDK_ROOT:-${HOME}/.crosswake/android-sdk}"
JDK_ROOT="${JAVA_HOME:-${TOOLCHAIN_ROOT}/temurin-17}"
CMDLINE_TOOLS_ZIP="commandlinetools-mac-14742923_latest.zip"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}"

download() {
  local url="$1"
  local output="$2"
  curl --fail --location --retry 5 --retry-delay 2 --retry-all-errors --continue-at - \
    --speed-time 30 --speed-limit 1024 \
    "${url}" -o "${output}"
}

arch() {
  case "$(uname -m)" in
    arm64) echo "aarch64" ;;
    x86_64) echo "x64" ;;
    *)
      echo "error: unsupported macOS architecture $(uname -m) for Android verification" >&2
      exit 1
      ;;
  esac
}

jdk_works() {
  local java_home="$1"

  [[ -x "${java_home}/bin/java" ]] && "${java_home}/bin/java" -version >/dev/null 2>&1
}

homebrew_java_home() {
  local prefix="/opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk/Contents/Home"

  if jdk_works "${prefix}"; then
    printf '%s\n' "${prefix}"
  fi
}

install_homebrew_jdk_if_needed() {
  if ! command -v brew >/dev/null 2>&1; then
    return 1
  fi

  brew install openjdk@17 >/dev/null
  homebrew_java_home
}

install_jdk_if_needed() {
  if [[ -n "${JAVA_HOME:-}" ]] && jdk_works "${JAVA_HOME}"; then
    export PATH="${JAVA_HOME}/bin:${PATH}"
    return
  fi

  if jdk_works "${JDK_ROOT}/Contents/Home"; then
    export JAVA_HOME="${JDK_ROOT}/Contents/Home"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    return
  fi

  local brewed_home=""
  brewed_home="$(homebrew_java_home || true)"

  if [[ -z "${brewed_home}" ]]; then
    brewed_home="$(install_homebrew_jdk_if_needed || true)"
  fi

  if [[ -n "${brewed_home}" ]]; then
    export JAVA_HOME="${brewed_home}"
    export PATH="${JAVA_HOME}/bin:${PATH}"
    return
  fi

  mkdir -p "${TOOLCHAIN_ROOT}"
  local archive="${TOOLCHAIN_ROOT}/temurin-17.tar.gz"
  local url="https://api.adoptium.net/v3/binary/latest/17/ga/mac/$(arch)/jdk/hotspot/normal/eclipse"

  download "${url}" "${archive}"
  rm -rf "${JDK_ROOT}"
  mkdir -p "${JDK_ROOT}"
  tar -xzf "${archive}" -C "${JDK_ROOT}" --strip-components=1
  rm -f "${archive}"

  export JAVA_HOME="${JDK_ROOT}/Contents/Home"
  export PATH="${JAVA_HOME}/bin:${PATH}"

  if ! jdk_works "${JAVA_HOME}"; then
    echo "error: provisioned Temurin JDK at ${JAVA_HOME} is not runnable" >&2
    exit 1
  fi
}

install_android_tools_if_needed() {
  mkdir -p "${SDK_ROOT}/cmdline-tools"

  if [[ ! -x "${SDK_ROOT}/cmdline-tools/latest/bin/sdkmanager" ]]; then
    local archive="${TOOLCHAIN_ROOT}/${CMDLINE_TOOLS_ZIP}"
    local unpack_root="${SDK_ROOT}/cmdline-tools"

    download "${CMDLINE_TOOLS_URL}" "${archive}"
    rm -rf "${unpack_root}/latest" "${unpack_root}/cmdline-tools"
    unzip -q "${archive}" -d "${unpack_root}"
    rm -f "${archive}"
    mkdir -p "${unpack_root}/latest"
    mv "${unpack_root}/cmdline-tools/"* "${unpack_root}/latest/"
    rmdir "${unpack_root}/cmdline-tools"
  fi

  export ANDROID_SDK_ROOT="${SDK_ROOT}"
  export ANDROID_HOME="${SDK_ROOT}"
  export PATH="${SDK_ROOT}/cmdline-tools/latest/bin:${SDK_ROOT}/platform-tools:${SDK_ROOT}/emulator:${PATH}"

  set +o pipefail
  yes | sdkmanager --licenses >/dev/null
  set -o pipefail
  sdkmanager \
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0" \
    "emulator" \
    "system-images;android-34;aosp_atd;arm64-v8a"
}

main() {
  install_jdk_if_needed
  install_android_tools_if_needed

  local tmpdir=""
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-android-shell.XXXXXX")"
  trap '[[ -n "${tmpdir:-}" ]] && rm -rf "${tmpdir}"' EXIT

  cd "${ROOT_DIR}"
  mix crosswake.gen.shell android --target "${tmpdir}" >/dev/null

  local project_root="${tmpdir}/native/android/crosswake_shell"
  printf 'sdk.dir=%s\n' "${ANDROID_SDK_ROOT//:/\\:}" > "${project_root}/local.properties"

  cd "${project_root}"
  ./gradlew --stacktrace testDebugUnitTest crosswakeApi34DebugAndroidTest \
    -Pandroid.testoptions.manageddevices.emulator.gpu=swiftshader_indirect
}

main "$@"
