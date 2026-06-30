#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TOOLCHAIN_ROOT="${HOME}/.crosswake/android-toolchain"
SDK_ROOT="${ANDROID_SDK_ROOT:-${HOME}/.crosswake/android-sdk}"
JDK_ROOT="${JAVA_HOME:-${TOOLCHAIN_ROOT}/temurin-17}"
PROJECT_ROOT_INPUT="${CROSSWAKE_ANDROID_PROJECT_ROOT:-}"
RUN_CONNECTED_TESTS="${CROSSWAKE_ANDROID_CONNECTED_TESTS:-1}"
CMDLINE_TOOLS_ZIP="commandlinetools-mac-14742923_latest.zip"
CMDLINE_TOOLS_URL="https://dl.google.com/android/repository/${CMDLINE_TOOLS_ZIP}"
AVD_NAME="crosswakeApi34Verify"
AVD_SERIAL="emulator-5560"
AVD_PORT="5560"

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
  local packages=(
    "platform-tools" \
    "platforms;android-34" \
    "build-tools;34.0.0"
  )

  if [[ "${RUN_CONNECTED_TESTS}" != "0" ]]; then
    packages+=(
      "emulator"
      "system-images;android-34;aosp_atd;arm64-v8a"
    )
  fi

  # Retry sdkmanager — package downloads are an occasional CI flake (e.g. a corrupt
  # build-tools zip: "Error on ZipFile unknown archive"). Without this, a transient
  # network/download failure reddens the merge-blocking native-behavioral-proof lane
  # and blocks an otherwise-mergeable PR. Re-download on failure (usually succeeds).
  local attempt
  for attempt in 1 2 3; do
    if sdkmanager "${packages[@]}"; then
      return 0
    fi
    if [[ "${attempt}" -eq 3 ]]; then
      echo "[verify-android] sdkmanager failed after 3 attempts" >&2
      return 1
    fi
    echo "[verify-android] sdkmanager attempt ${attempt} failed (transient SDK download?); retrying..." >&2
    sleep $((attempt * 5))
  done
}

create_avd_if_needed() {
  local avd_dir="${HOME}/.android/avd/${AVD_NAME}.avd"
  local avd_ini="${HOME}/.android/avd/${AVD_NAME}.ini"

  if [[ -f "${avd_ini}" && -d "${avd_dir}" ]]; then
    return
  fi

  avdmanager delete avd -n "${AVD_NAME}" >/dev/null 2>&1 || true
  printf 'no\n' | avdmanager create avd \
    -n "${AVD_NAME}" \
    -k "system-images;android-34;aosp_atd;arm64-v8a" \
    -d pixel_6 >/dev/null
}

wait_for_boot() {
  local serial="$1"
  local attempts=120
  local boot_completed=""

  adb -s "${serial}" wait-for-device >/dev/null

  while (( attempts > 0 )); do
    boot_completed="$(adb -s "${serial}" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')"

    if [[ "${boot_completed}" == "1" ]]; then
      return 0
    fi

    sleep 2
    attempts=$((attempts - 1))
  done

  echo "error: emulator ${serial} did not finish booting" >&2
  return 1
}

start_emulator() {
  local log_file="$1"

  adb kill-server >/dev/null 2>&1 || true
  rm -f "${log_file}"

  emulator @"${AVD_NAME}" \
    -port "${AVD_PORT}" \
    -no-window \
    -no-boot-anim \
    -no-audio \
    -gpu swiftshader_indirect \
    -no-snapshot-load \
    -no-snapshot-save \
    -wipe-data \
    >"${log_file}" 2>&1 &

  EMULATOR_PID=$!
  wait_for_boot "${AVD_SERIAL}"
}

stop_emulator() {
  if [[ -n "${EMULATOR_PID:-}" ]] && kill -0 "${EMULATOR_PID}" >/dev/null 2>&1; then
    adb -s "${AVD_SERIAL}" emu kill >/dev/null 2>&1 || true
    wait "${EMULATOR_PID}" >/dev/null 2>&1 || true
  fi
}

main() {
  echo "Android verification mode: connected_tests=${RUN_CONNECTED_TESTS}"

  install_jdk_if_needed
  install_android_tools_if_needed

  local tmpdir=""
  local project_root=""
  tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/crosswake-android-shell.XXXXXX")"
  local emulator_log="${TMPDIR:-/tmp}/crosswake-android-emulator.log"
  trap 'stop_emulator; [[ -n "${tmpdir:-}" ]] && rm -rf "${tmpdir}"' EXIT

  if [[ -n "${PROJECT_ROOT_INPUT}" ]]; then
    project_root="$(cd "${ROOT_DIR}" && cd "${PROJECT_ROOT_INPUT}" && pwd)"
  else
    cd "${ROOT_DIR}"
    mix crosswake.gen.shell android --target "${tmpdir}" >/dev/null
    project_root="${tmpdir}/native/android/crosswake_shell"
  fi

  printf 'sdk.dir=%s\n' "${ANDROID_SDK_ROOT//:/\\:}" > "${project_root}/local.properties"

  cd "${project_root}"

  # Pick the Gradle task names by detecting whether the project ACTUALLY declares
  # product flavors, not by whether a project root was passed in. The
  # examples/android_shell_host path declares prod/dev flavors (-> testProdDebugUnitTest);
  # the generated-from-template path has none (-> testDebugUnitTest). Both paths can set
  # PROJECT_ROOT_INPUT (phase18/phase79 generate a flavorless shell and point at it), so
  # keying off the env var alone selects a non-existent prod task and the build fails.
  if grep -q "productFlavors" app/build.gradle 2>/dev/null; then
    UNIT_TEST_TASK="testProdDebugUnitTest"
    CONNECTED_TEST_TASK="connectedProdDebugAndroidTest"
  else
    UNIT_TEST_TASK="testDebugUnitTest"
    CONNECTED_TEST_TASK="connectedDebugAndroidTest"
  fi

  if [[ "${RUN_CONNECTED_TESTS}" == "0" ]]; then
    ./gradlew --no-daemon --stacktrace "${UNIT_TEST_TASK}"
    return
  fi

  create_avd_if_needed
  start_emulator "${emulator_log}"
  ANDROID_SERIAL="${AVD_SERIAL}" ./gradlew --no-daemon --stacktrace "${UNIT_TEST_TASK}" "${CONNECTED_TEST_TASK}"
}

main "$@"
