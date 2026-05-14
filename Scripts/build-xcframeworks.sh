#!/usr/bin/env bash
set -euo pipefail

upstream_ref="${1:?usage: build-xcframeworks.sh <upstream-ref> <release-tag>}"
release_tag="${2:-$upstream_ref}"
upstream_url="${UPSTREAM_URL:-https://github.com/pointfreeco/swift-tagged.git}"

products=(Tagged TaggedMoney TaggedTime)
platforms=(
  "ios|generic/platform=iOS"
  "ios-simulator|generic/platform=iOS Simulator"
  "macos|generic/platform=macOS"
  "tvos|generic/platform=tvOS"
  "tvos-simulator|generic/platform=tvOS Simulator"
  "watchos|generic/platform=watchOS"
  "watchos-simulator|generic/platform=watchOS Simulator"
)

work_dir="${RUNNER_TEMP:-/tmp}/swift-tagged-${release_tag}"
source_dir="${work_dir}/source"
archive_dir="${work_dir}/archives"
dist_dir="${PWD}/dist"

rm -rf "$work_dir" "$dist_dir"
mkdir -p "$archive_dir" "$dist_dir"

git clone --depth 1 --branch "$upstream_ref" "$upstream_url" "$source_dir"

checksums_file="${dist_dir}/checksums.txt"
: > "$checksums_file"

pushd "$source_dir" >/dev/null

for product in "${products[@]}"; do
  frameworks=()

  for platform in "${platforms[@]}"; do
    IFS="|" read -r slug destination <<< "$platform"
    archive_path="${archive_dir}/${product}-${slug}.xcarchive"

    xcodebuild archive \
      -scheme "$product" \
      -destination "$destination" \
      -archivePath "$archive_path" \
      SKIP_INSTALL=NO \
      BUILD_LIBRARY_FOR_DISTRIBUTION=NO \
      ONLY_ACTIVE_ARCH=NO

    frameworks+=("-framework" "${archive_path}/Products/Library/Frameworks/${product}.framework")
  done

  xcframework_path="${dist_dir}/${product}.xcframework"
  zip_path="${dist_dir}/${product}.xcframework.zip"

  xcodebuild -create-xcframework "${frameworks[@]}" -output "$xcframework_path"
  ditto -c -k --sequesterRsrc --keepParent "$xcframework_path" "$zip_path"
  rm -rf "$xcframework_path"

  checksum="$(swift package compute-checksum "$zip_path")"
  printf "%s  %s\n" "$checksum" "$(basename "$zip_path")" >> "$checksums_file"
done

popd >/dev/null
