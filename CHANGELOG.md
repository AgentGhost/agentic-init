# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

## [0.1.0] - 2026-05-02

### Added
- Project structure (dev/, ops/, sec/, docs/)
- Plane integration with Docker Compose
- Zen-Swarm loop (Research → Write → Critic)
- Backup/restore scripts for Plane

### Changed
- Branch renamed from master to main
- Consolidated documentation (README, CHANGELOG, docs/PLANE.md, docs/TICKETS.md)

### Fixed
- Removed hardcoded AGI IDs from documentation
- Removed hardcoded module names from documentation

### Removed
- RabbitMQ (replaced with Redis)
- Zookeeper (using Kafka KRaft mode)