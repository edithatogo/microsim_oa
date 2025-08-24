# Changelog

## v2.0.0-dev (2025-08-24)

### Added
- New unit tests for interventions, policy levers, KL initialization, graph functions, comorbidities, and stats helpers.
- Snapshot for regression testing.
- VS Code MCP config (`.vscode/mcp.json`) and `.env.example` with placeholders.

### Changed
- `ggsave` calls now use `ragg::agg_png` for consistent PNG output.
- Minor code hygiene in scripts and functions; updated `renv/settings.json` to `snapshot.type: implicit`.

### Fixed
- Documentation links and badges in README now point to `edithatogo/microsim_oa`.

## v2.0-beta (2025-07-31)

This is the first beta release of AUS-OA Model v2. This version represents a complete architectural relaunch, transforming the model into a modern, robust, and scalable R package.

### Major Achievements

- **Software Engineering:**
    - Refactored the entire project into a formal R package.
    - Implemented `renv` for rigorous dependency management.
    - Established a CI/CD pipeline with GitHub Actions for automated testing.
    - Containerized the model environment using Docker for full reproducibility.
- **Configuration:**
    - Externalized all model parameters into human-readable YAML files.
    - Implemented a flexible policy lever system for modeling interventions.
- **Performance:**
    - Refactored core data manipulation logic to use the high-performance `data.table` package.
    - Profiled the simulation engine to identify performance characteristics.
- **Clinical Engine:**
    - Implemented a flexible intervention module for a wide range of treatments.
    - Enhanced the surgical module with more detailed revision and survivorship logic.
    - Initial versions of the Patient-Reported Outcomes (PROs) and granular costing modules have been developed.

### Future Work
All future development, including the completion of the core clinical engine and the expansion of the model's scope, is outlined in `planning/ROADMAP_v3.md`.

---

## 2025-07-14

### Added
- Initial `ROADMAP.md` outlining future development phases and key tasks.
- Initial `TODO.md` detailing specific development tasks.
- Initial `CHANGELOG.md` for tracking project changes.
- Initial `SESSION_LOG.md` for logging current session activities.
