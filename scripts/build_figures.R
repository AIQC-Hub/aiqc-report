#!/usr/bin/env Rscript

# Regenerates the QC figures in content/images/ from the profile summaries that
# scripts/build_summaries.R writes in the regional repos. The page shows these
# as committed PNGs -- this script is how they are made, not something the site
# runs at render time.
#
#   Rscript scripts/build_figures.R            # all 18 figures
#   AIQC_DATA_DIR=/path/to/summaries Rscript scripts/build_figures.R
#
# Copernicus publishes no GL product for the Baltic, so nrt_bo_gl has no
# summary. Its two figures are drawn as empty panels and replaced once the
# dataset exists again.

# reportlib Depends on arrow, tidyverse, ggpubr and cowplot, so attaching it
# attaches everything below as well.
suppressMessages(library(reportlib))

repo <- normalizePath(file.path(dirname(sub("^--file=", "",
  grep("^--file=", commandArgs(FALSE), value = TRUE)[1])), ".."))
data_path   <- Sys.getenv("AIQC_DATA_DIR", unset = "/scratch/data/aiqc/merged")
output_path <- file.path(repo, "content", "images")

# The bounding boxes are the ones the regional sites filter with, copied from
# their _func/common_{ar,bo,mo}.Rmd. Each site's exclude_locations() is the
# identity, so profile-level QC plus the box is the whole chain.
filer_locations_func <- list(
  ar = function(df) filer_locations_common(df, -180, 180, 60, 90),
  bo = function(df) df,
  mo = function(df) filer_locations_common(df, -5.61, 35.567, 28.378, 45.755))

summary_files <- list(
  rg   = list(ar = "netcdf_nrt_ar_summary.parquet",
              bo = "netcdf_nrt_bo_summary.parquet",
              mo = "netcdf_nrt_mo_summary.parquet"),
  gl   = list(ar = "netcdf_nrt_ar_gl_summary.parquet",
              bo = NA_character_,                     # no Baltic GL product
              mo = "netcdf_nrt_mo_gl_summary.parquet"),
  cora = list(ar = "netcdf_cora_ar_summary.parquet",
              bo = "netcdf_cora_bo_summary.parquet",
              mo = "netcdf_cora_mo_summary.parquet"))

vars        <- c("pres", "temp", "psal")
var_titles  <- c(pres = "Pressure", temp = "Temperature", psal = "Salinity")

blank_panel <- function() {
  ggplot() +
    annotate("text", x = 0.5, y = 0.5, label = "No data available to display.", size = 3) +
    theme_void()
}

# --- fraction of QC 4 flags per profile ------------------------------------

qc4_proportion <- function(df, var_x) {
  df %>%
    select(platform_code, profile_timestamp, profile_no,
           n = !!sym(paste0(var_x, "_count")),
           qc4_x = !!sym(paste0(var_x, "_qc_4"))) %>%
    mutate(qc4_prop = qc4_x / n) %>%
    filter(qc4_prop > 0)
}

create_qc4_density <- function(df, main_title) {
  if (nrow(df) == 0) return(blank_panel())
  ggplot(df, aes(x = qc4_prop)) +
    geom_density(alpha = 0.25, linewidth = 0.25) +
    labs(x = "proportion of QC 4", y = "density") +
    theme_pubr(base_size = 10) +
    ggtitle(main_title) +
    xlim(0, 1) +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# --- QC 1 and QC 4 counts over time ----------------------------------------

qc_summary_time <- function(df, var_x) {
  df_summary <- df %>%
    select(platform_code, profile_no, x, starts_with(paste0(var_x, "_qc_"))) %>%
    pivot_longer(cols = starts_with(paste0(var_x, "_qc_")),
                 names_to = "Code", names_prefix = paste0(var_x, "_"),
                 values_to = "profile_n") %>%
    group_by(x, Code) %>%
    summarise(n = sum(profile_n), .groups = "drop") %>%
    complete(x, Code, fill = list(n = 0)) %>%
    mutate(n = ifelse(is.na(n), 0, n)) %>%
    pivot_wider(names_from = Code, values_from = n)

  for (col in c("qc_1", "qc_4")) {
    if (!(col %in% colnames(df_summary))) df_summary[[col]] <- 0
  }
  df_summary
}

create_bar_over_time <- function(df, title) {
  if (nrow(df) == 0) return(blank_panel())
  df_qc <- df %>% select(x, y = qc_1) %>% mutate(qc = "QC=1") %>%
    bind_rows(df %>% select(x, y = qc_4) %>% mutate(qc = "QC=4"))

  ggplot(df_qc, aes(x = x, y = y)) +
    geom_bar(stat = "identity") +
    labs(title = title, x = NULL, y = NULL) +
    theme_pubr(base_size = 10) +
    facet_grid(vars(qc), scales = "free") +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
}

# --- driver -----------------------------------------------------------------

create_plots <- function(region, region_code) {
  fname <- summary_files[[region_code]][[region]]
  df_filtered <- NULL
  if (!is.na(fname) && file.exists(file.path(data_path, fname))) {
    df_filtered <- read_parquet(file.path(data_path, fname)) %>%
      filter_profile_level_qc() %>%
      filer_locations_func[[region]]()
  } else {
    message("  no summary for ", region, "/", region_code, " -- drawing empty panels")
  }

  # A dataset that does not exist gets one note across the whole figure rather
  # than the same sentence repeated in every panel.
  if (is.null(df_filtered)) {
    for (stem in c("p_qc4_fraction_", "p_qc_over_time_")) {
      ggsave2(file.path(output_path, paste0(stem, region, "_", region_code, ".png")),
              blank_panel(), width = 180,
              height = if (stem == "p_qc4_fraction_") 50 else 140, units = "mm")
    }
    return(invisible(NULL))
  }

  p_qc4 <- list()
  p_time <- list()
  for (v in vars) {
    p_qc4[[v]] <- create_qc4_density(qc4_proportion(df_filtered, v),
                                     paste(var_titles[[v]], "QC 4"))
    df_year <- df_filtered %>% mutate(x = format(profile_timestamp, "%Y"))
    p_time[[v]] <- create_bar_over_time(
      qc_summary_time(df_year, v) %>% filter(x >= "2000"),
      paste0(var_titles[[v]], ": QC Counts Over Time (From 2000)"))
  }

  ggsave2(file.path(output_path, paste0("p_qc4_fraction_", region, "_", region_code, ".png")),
          plot_grid(p_qc4[["pres"]], NULL, p_qc4[["temp"]], NULL, p_qc4[["psal"]],
                    nrow = 1, rel_widths = c(1, 0.05, 1, 0.05, 1)),
          width = 180, height = 50, units = "mm")

  ggsave2(file.path(output_path, paste0("p_qc_over_time_", region, "_", region_code, ".png")),
          plot_grid(p_time[["pres"]], NULL, p_time[["temp"]], NULL, p_time[["psal"]],
                    ncol = 1, rel_heights = c(1, 0.05, 1, 0.05, 1)),
          width = 180, height = 140, units = "mm")
}

for (region in c("ar", "bo", "mo")) {
  for (region_code in c("rg", "gl", "cora")) {
    message("region: ", region, ", region_code: ", region_code)
    create_plots(region, region_code)
  }
}
