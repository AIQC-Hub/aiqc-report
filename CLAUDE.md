# aiqc-report

**Quarto** website for the **AIQC portal**: it links the three regional in situ summary reports
and carries the exploratory data analysis behind them. Built to GitHub Pages at
<https://aiqc-hub.github.io/aiqc-report/>. One page, `content/index.qmd`, on the knitr engine.

**Rendering this site reads no data.** Every number on a page is a literal in a `_func/*.Rmd`
child and every figure is a committed PNG in `content/images/`; there is no `data` symlink and no
`config.yml`. The QC figures are not hand-made, though: `scripts/build_figures.R` regenerates all
18 of them from the profile summaries in `/scratch/data/aiqc/merged`, the same files the regional
sites read. Run it when the data changes, then commit the PNGs.

**The shared machinery lives in the [`reportlib`](https://github.com/AIQC-Hub/reportlib)
package**, the same one `arc-report` / `bal-report` / `med-report` use. This repo keeps only its
page, its four sections and `_quarto.yml`.

## Layout

```
content/            # Quarto project root
  _quarto.yml       # project type, navbar, output-dir: docs, freeze
  index.qmd         # the whole site
  _func/            # knitr children, one per section, pulled in with child=
    eda_netcdf.Rmd        eda_parquet.Rmd
    eda_qc4_fraction.Rmd  eda_qc_over_time.Rmd
  images/           # the logo and 18 pre-rendered analysis figures
  docs/             # BUILD OUTPUT — generated, git-ignored, do not hand-edit
scripts/            # build_figures.R (the 18 QC figures)
```

`_func` is underscore-prefixed, so Quarto's project scan ignores it — which is what we want, those
are children rather than pages.

## Build & deploy

```bash
./build.sh                        # what RStudio's Build pane runs
Rscript scripts/build_figures.R   # regenerate content/images/p_qc*.png from the summaries
quarto render content             # whole site -> content/docs
quarto preview content            # live preview
```

**The QC figures.** `scripts/build_figures.R` writes `p_qc4_fraction_*` and `p_qc_over_time_*`
for the nine region-product pairs, filtering exactly as the regional pages do: profile-level QC,
then each region's bounding box (`exclude_locations()` is the identity in all three sites, so
that is the whole chain). `AIQC_DATA_DIR` overrides the summary directory. `nrt_bo_gl` has no
summary — Copernicus publishes no GL product for the Baltic — so its two figures are drawn as a
single "No data available to display." panel and will fill in when that dataset returns.

**Freeze.** `_quarto.yml` sets `execute: freeze: auto`, so the page is re-run only when
`index.qmd` changes. Quarto hashes the `.qmd` alone and nothing that decides what the page shows
lives there, so `build.sh` stamps the installed `reportlib`, `content/_func/` and
`content/images/`, and clears `content/_freeze/` when any of them moves. Delete that directory to
force a full re-render; `quarto render` on its own will not, so prefer `./build.sh`.

**RStudio's Build pane.** `.Rproj` uses `BuildType: Custom` pointing at `build.sh`, for the same
reason as the regional repos: RStudio only recognises a Quarto project when `_quarto.yml` sits
beside the `.Rproj`, and ours is in `content/`.

### Dependencies

Two declared: `reportlib` and `rmarkdown` (`DESCRIPTION`). Everything else — tidyverse, DT,
kableExtra and the rest — belongs to `reportlib`.

```r
install.packages("rmarkdown")
remotes::install_github("AIQC-Hub/reportlib@v0.1.11")
```

CI (`.github/workflows/build-and-deploy.yml`) runs on push to `main`: `setup-r-dependencies` reads
`DESCRIPTION`, Quarto renders, `content/docs` is published to Pages. Unlike the regional sites
there is no release-asset download step, because there is no data to fetch.

## Repo conventions

- **git-flow**: work on `develop`; `feature/*` → `develop`; `release/*` → `main`. Never commit
  straight to `main`.
- Update `CHANGELOG.md` (Keep a Changelog) and the `Version:` in `DESCRIPTION` for each release.
- Never commit `content/docs/`, `content/_freeze/` or `.Rproj.user/`.
- The navbar's logo links to this portal and its title links to the index — two separate links, as
  Distill had them. Quarto folds the two into one `navbar-brand`, so the title is suppressed
  (`title: false`) and added back as an ordinary left-hand nav item.
