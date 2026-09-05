# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## [Unreleased]
### Added
- A **Source on GitHub** link in the navbar, pointing at this repo.
- `build.sh`, what RStudio's Build pane now runs, with the same freeze stamp the regional sites
  use: `content/_quarto.yml` sets `freeze: auto`, and the stamp clears `content/_freeze/` when
  the installed `reportlib`, `content/_func/` or `content/images/` moves.

### Changed
- The site is built with **Quarto** instead of Distill. `index.Rmd` became `index.qmd`,
  `_site.yml` became `content/_quarto.yml`, the six sections moved from `content/_template/` to
  `content/_func/` as ordinary knitr children, and xaringanExtra panelsets became Quarto
  `::: {.panel-tabset}`. Verified against the Distill build: all 189 table cells identical, the
  same 21 images, 11 tabsets for 11 panelsets, and every heading that is no longer a heading is
  now a tab label.
- The shared functions come from **`reportlib`**. `_func/common.Rmd` and `_func/libraries.Rmd`
  are gone: `kbl_table()` and `create_dt_summary_tab()` were character-identical copies of the
  package's, and `rsc_dir`/`rsc_dir2` pointed at data this site never reads.
- The navbar title links to this site's home page rather than to the portal URL, and the logo
  gains `AIQC` alt text. Quarto folds logo and title into a single brand link, which `logo-href`
  would otherwise claim in full.
- The **Exported Parquet Datasets** tables now describe the files `ctddump` + `seastamp`
  produce, not the retired R pipeline's. Names lose the `netcdf_` prefix and the `_2` suffix
  (`nrt_ar_ar.parquet`, `cora_ar.parquet`, ...), and every size, platform, profile and
  observation count was remeasured off the files on disk. The Baltic GL row is gone: Copernicus
  publishes no GL product for the Baltic, so there are eight files now rather than nine. Profile
  and platform counts cross-check exactly against the per-dataset summary parquet.

### Removed
- Every Zenodo reference from **Exported Parquet Datasets** -- the DOI badge and the sentence
  that introduced it. The Zenodo deposit still holds the parquet files the retired R pipeline
  exported, so both pointed readers at superseded data.


## [0.3.4] - 2025-11-17
### Added
- Side contents menu to EDA page

## [0.3.3] - 2025-11-17
### Added
- NRT vs CORA section to EDA page

## [0.3.2] - 2025-11-16
### Added
- Analysis summary sections to EDA page

## [0.3.1] - 2025-11-16
### Changed
- DOI link for the Parquet datasets

## [0.3.0] - 2025-11-15
### Changed
- All the page structure to make it a portal site

## [0.2.1] - 2025-11-15
### Changed
- GL pages for AR

## [0.2.0] - 2025-11-06
### Added
- All pages for AR
- Auto caching of filtered data

## [0.1.11] - 2025-11-06
### Added
- All pages for BO (GL)

## [0.1.10] - 2025-11-05
### Changed
- Format of the menu bar

### Added
- `content` directory to store all Rmd files
- Time distribuion section to QC flag pages

## [0.1.9] - 2025-11-05
### Fixed
- Base font sizes for all plots

## [0.1.8] - 2025-11-05
### Added
- `hexbin` as package dependency

## [0.1.7] - 2025-11-04
### Fixed
- Resource path in bo common

## [0.1.6] - 2025-11-04
### Added
- `xaringanExtra` as package dependency again

## [0.1.5] - 2025-11-04
### Added
- Common templates and functions for refactoring

## [0.1.4] - 2025-11-04
### Added
- `maps` as package dependency

## [0.1.3] - 2025-11-04
### Fixed
- Resource path in bo common

## [0.1.2] - 2025-11-04
### Removed
- `xaringanExtra` as package dependency

## [0.1.1] - 2025-11-04
### Added
- Template pages for main summary report

## [0.1.0] - 2025-11-03
### Added
- Initial Baltic Sea (BO) pages
