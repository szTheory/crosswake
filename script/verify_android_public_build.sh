#!/usr/bin/env bash
set -euo pipefail
project_root="${1:?generated Android project required}"
version="${2:?exact published version required}"
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Invalid exact Maven version' >&2; exit 1; }
[[ -f "$project_root/gradlew" ]] || { echo 'Generated Gradle wrapper missing' >&2; exit 1; }
coordinate="https://repo.maven.apache.org/maven2/io/github/sztheory/crosswake-shell-core-android/$version/crosswake-shell-core-android-$version"
max_attempts="${CROSSWAKE_MAVEN_POLL_ATTEMPTS:-40}"
delay="${CROSSWAKE_MAVEN_POLL_DELAY:-45}"
[[ "$max_attempts" =~ ^[1-9][0-9]*$ && "$max_attempts" -le 40 ]] || exit 1
[[ "$delay" =~ ^[0-9]+$ && "$delay" -le 45 ]] || exit 1
available=false
for ((attempt = 1; attempt <= max_attempts; attempt++)); do
  available=true
  for extension in pom aar; do
    if ! status=$(curl --silent --show-error --location --max-time 30 --output /dev/null --write-out '%{http_code}' "$coordinate.$extension"); then
      available=false
      break
    fi
    case "$status" in
      200) ;;
      404|429|5??) available=false ;;
      *) echo "Maven $extension returned unexpected HTTP $status; refusing build" >&2; exit 1 ;;
    esac
  done
  if [[ "$available" == true ]]; then break; fi
  echo "Maven coordinate not available yet ($attempt/$max_attempts)"
  if ((attempt < max_attempts)); then sleep "$delay"; fi
 done
[[ "$available" == true ]] || { echo 'Exact Maven coordinate propagation timed out' >&2; exit 1; }
cd "$project_root"
chmod +x gradlew
echo 'Exact Maven POM and AAR available; running full Gradle build once'
./gradlew build --no-daemon --refresh-dependencies
