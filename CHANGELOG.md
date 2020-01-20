# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.7.2] 2020-01-20
### Fixed
- Fix the postgrex automatic reconnection

### Added
- Option to disable event cleanup error (`:log_cleanup_errors`)

## [0.7.1] 2019-12-16
### Added
- Enable postgrex's automatic reconnection for notification connections (see
[:auto_reconnect in start_link/1](https://hexdocs.pm/postgrex/Postgrex.Notifications.html#start_link/1))

## [0.7.0] - 2019-09-06
### Changed
- Updated for Dawdle v0.7.0.

## [0.6.0] - 2019-08-05
### Added
- Telemetry events are now fired during event handling.
- The singleton watcher is now managed by Swarm.

### Changed
- Minor updates to README.md.

## [0.5.0] - 2019-04-17
Initial release.

[Unreleased]: https://github.com/hippware/dawdle_db/compare/v0.6.0...HEAD
[0.6.0]: https://github.com/hippware/dawdle_db/compare/v0.5.0...0.6.0
[0.5.0]: https://github.com/hippware/dawdle_db/releases/tag/v0.5.0
