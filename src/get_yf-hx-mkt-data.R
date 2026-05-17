#!/usr/bin/env Rscript

# ============================================================
# get_yf_hx-mkt-data.R
#
# PURPOSE
# -------
# Downloads Yahoo Finance historical DAILY market data
#
# IMPORTANT
# ---------
# Yahoo Finance is appropriate here for daily context data.
# It is NOT sufficient for true intraday reconstruction
#
# OUTPUT
# ------
# Writes files to ./yahoo_data/
#
# SYMBOLS
# -------
# ^GSPC  = S&P 500 Index
# SPY    = SPDR S&P 500 ETF
# ^VIX   = CBOE Volatility Index
# ES=F   = E-mini S&P 500 futures (daily only from Yahoo if available)
# ^DJI   = Dow Jones Industrial Average
#
# RUN
# ---
# Rscript get_yf_hx-mkt-data.R
# ============================================================

suppressPackageStartupMessages({
  library(quantmod)
  library(data.table)
  library(xts)
})

# ------------------------------------------------------------
# User settings
# ------------------------------------------------------------
start_date <- as.Date("2010-04-01")
end_date   <- as.Date("2010-05-31")

out_dir <- "yahoo_data"
dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)

symbols <- c("^GSPC", "SPY", "^VIX", "ES=F", "^DJI")

# ------------------------------------------------------------
# Helper: safe symbol -> object name conversion
# ------------------------------------------------------------
safe_object_name <- function(symbol) {
  # quantmod often converts:
  # ^GSPC -> GSPC
  # ES=F  -> ES.F
  nm <- gsub("\\^", "", symbol)
  nm <- gsub("=", ".", nm)
  nm
}

# ------------------------------------------------------------
# Helper: xts -> clean data.table
# ------------------------------------------------------------
xts_to_dt <- function(x, symbol) {
  dt <- data.table(
    date = as.Date(index(x)),
    coredata(x)
  )

  old_names <- names(dt)

  # Standardize Yahoo/quantmod column names
  names(dt) <- gsub(".*\\.Open$", "open", names(dt))
  names(dt) <- gsub(".*\\.High$", "high", names(dt))
  names(dt) <- gsub(".*\\.Low$", "low", names(dt))
  names(dt) <- gsub(".*\\.Close$", "close", names(dt))
  names(dt) <- gsub(".*\\.Volume$", "volume", names(dt))
  names(dt) <- gsub(".*\\.Adjusted$", "adjusted", names(dt))

  dt[, symbol := symbol]
  setcolorder(dt, c("symbol", "date",
                    intersect(c("open","high","low","close","volume","adjusted"), names(dt))))

  dt[]
}

# ------------------------------------------------------------
# Download Yahoo data
# ------------------------------------------------------------
downloaded <- list()
download_log <- data.table(
  symbol = character(),
  status = character(),
  rows = integer(),
  note = character()
)

for (sym in symbols) {
  message(sprintf("Downloading %s from Yahoo Finance...", sym))

  obj_name <- safe_object_name(sym)

  ok <- tryCatch({
    getSymbols(
      Symbols      = sym,
      src          = "yahoo",
      from         = start_date,
      to           = end_date,
      auto.assign  = TRUE,
      warnings     = FALSE
    )
    TRUE
  }, error = function(e) {
    download_log <<- rbind(
      download_log,
      data.table(
        symbol = sym,
        status = "ERROR",
        rows = 0L,
        note = conditionMessage(e)
      ),
      fill = TRUE
    )
    FALSE
  })

  if (!ok) next

  if (!exists(obj_name, inherits = FALSE)) {
    download_log <- rbind(
      download_log,
      data.table(
        symbol = sym,
        status = "ERROR",
        rows = 0L,
        note = sprintf("Object %s was not created by getSymbols()", obj_name)
      ),
      fill = TRUE
    )
    next
  }

  x <- get(obj_name, inherits = FALSE)

  # Remove missing middle values if necessary, but preserve raw first
  raw_file <- file.path(out_dir, paste0(gsub("[^A-Za-z0-9]+", "_", sym), "_raw.csv"))
  fwrite(xts_to_dt(x, sym), raw_file)

  # Clean rows with missing OHLC close
  dt <- xts_to_dt(x, sym)
  if ("close" %in% names(dt)) {
    dt <- dt[!is.na(close)]
  }

  out_file <- file.path(out_dir, paste0(gsub("[^A-Za-z0-9]+", "_", sym), "_daily.csv"))
  fwrite(dt, out_file)

  downloaded[[sym]] <- dt

  download_log <- rbind(
    download_log,
    data.table(
      symbol = sym,
      status = "OK",
      rows = nrow(dt),
      note = out_file
    ),
    fill = TRUE
  )
}

# ------------------------------------------------------------
# Build a merged event-study panel
# ------------------------------------------------------------
merge_symbol_close <- function(dt, label) {
  if (is.null(dt) || !"close" %in% names(dt)) return(NULL)
  out <- dt[, .(date, close)]
  setnames(out, "close", label)
  out
}

panel_list <- list(
  merge_symbol_close(downloaded[["^GSPC"]], "spx_close"),
  merge_symbol_close(downloaded[["SPY"]],   "spy_close"),
  merge_symbol_close(downloaded[["^VIX"]],  "vix_close"),
  merge_symbol_close(downloaded[["ES=F"]],  "es_close"),
  merge_symbol_close(downloaded[["^DJI"]],  "dji_close")
)

panel_list <- Filter(Negate(is.null), panel_list)

if (length(panel_list) > 0L) {
  panel_dt <- Reduce(function(x, y) merge(x, y, by = "date", all = TRUE), panel_list)

  # Add simple returns where available
  return_cols <- setdiff(names(panel_dt), "date")
  for (col in return_cols) {
    ret_name <- sub("_close$", "_logret", col)
    panel_dt[, (ret_name) := c(NA_real_, diff(log(get(col))))]
  }

  fwrite(panel_dt, file.path(out_dir, "yf_context_panel.csv"))
}

# ------------------------------------------------------------
# Write a short report
# ------------------------------------------------------------
report_file <- file.path(out_dir, "README.txt")
lines <- c(
  "Flash Crash Yahoo Data Extract",
  "==============================",
  "",
  sprintf("Date range: %s to %s", start_date, end_date),
  "",
  "Downloaded symbols:",
  paste0("  - ", download_log$symbol, " : ", download_log$status),
  "",
  "Files created:",
  paste0("  - ", list.files(out_dir, full.names = FALSE)),
  "",
  "Notes:",
  "1. Yahoo Finance is suitable here for daily context series.",
  "2. This does NOT provide the full intraday May 6, 2010 event tape needed for a true Flash Crash microstructure reconstruction.",
  "3. Use a dedicated intraday source for ES minute/tick data if you want the rolling Student-t COR reconstruction at event frequency."
)
writeLines(lines, report_file)

# ------------------------------------------------------------
# Write log
# ------------------------------------------------------------
fwrite(download_log, file.path(out_dir, "download_log.csv"))

message("Done.")
message(sprintf("Output directory: %s", normalizePath(out_dir, winslash = "/")))


