# swift-tagged-artifacts

Build-and-release automation for `swift-tagged` XCFramework artifacts.

Upstream package:
`https://github.com/pointfreeco/swift-tagged`

Artifacts produced by this repository are consumed by:
`https://github.com/spm-binary/swift-tagged.git`

## Release Flow

Run the `Build release` workflow with:

- `upstream_ref`: upstream tag or branch to build, such as `0.10.0`
- `release_tag`: release tag to create in this repository, usually the same
  semantic version

The workflow builds `Tagged`, `TaggedMoney`, and `TaggedTime` as XCFramework zip
assets and uploads a `checksums.txt` file containing SwiftPM checksums.
