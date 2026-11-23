# Public operations ---------------------------------------------------------

#' Extract one ObServe trip to CSV through a database connection
#'
#' Run one query per source table on an open DBI connection and write the rows to CSV.
#' @param trip_id One source trip `topiaId`, passed to every query.
#' @param connection An open DBI connection owned by the caller.
#' @param directory New trip directory. Its parent must already exist.
#' @param gear One source gear, [OBSERVE_GEAR_LL] or [OBSERVE_GEAR_PS].
#' @param observe_version Packaged ObServe source-model version. Defaults to [OBSERVE_VERSION_10_0].
#' @return Absolute CSV paths named by qualified source table, in model order.
#'   Empty results have a header and no data rows.
#' @details Each file is named `<qualified-table>.csv` and uses the ObServe CSV
#'   format: UTF-8, comma separators, CRLF records, quoted headers and values,
#'   doubled embedded quotes, and bare empty fields for SQL NULL.
#'
#'   The caller controls the database transaction. If extraction fails, the
#'   new directory and its partial files are removed.
#' @seealso [create_observe_h2_backup_connection_provider()], [db.tools::with_db_connection()]
#' @export
observe_sql_extract_trip_csv <- function(trip_id,
                                         connection,
                                         directory,
                                         gear = OBSERVE_GEAR_LL,
                                         observe_version = OBSERVE_VERSION_10_0) {
  extract_observe_trip_csv(trip_id, directory, gear, observe_version,
                           extract_table = create_sql_csv_writer(connection, trip_id))
}

#' Extract one ObServe trip to CSV through the public API
#'
#' Submit one query per source table to `sql/csv` and save each response byte for byte.
#' @param trip_id One source trip `topiaId`, passed to every query.
#' @param connection An open session from [observe_public_api_connect_from_yaml()].
#' @param directory New trip directory. Its parent must already exist.
#' @param gear One source gear, [OBSERVE_GEAR_LL] or [OBSERVE_GEAR_PS].
#' @param observe_version Packaged ObServe source-model version. Defaults to [OBSERVE_VERSION_10_0].
#' @return Absolute CSV paths named by qualified source table, in model order.
#'   Empty results have a header and no data rows.
#' @details Each file is named `<qualified-table>.csv`. Each request uses its own
#'   database snapshot. If extraction fails, the new directory and its partial
#'   files are removed.
#' @seealso [observe_public_api_with_connection()]
#' @export
observe_public_api_extract_trip_csv <- function(trip_id,
                                                connection,
                                                directory,
                                                gear = OBSERVE_GEAR_LL,
                                                observe_version = OBSERVE_VERSION_10_0) {
  extract_observe_trip_csv(trip_id, directory, gear, observe_version,
                           extract_table = function(sql, csv_path, fields) observe_public_api_save_csv(connection, sql, csv_path),
                           prepare_query = function(sql) observe_public_api_prepare_query(sql, list(trip_id)))
}

# Internal helpers ----------------------------------------------------------

#' Run the model's table extraction through an explicit CSV writer
#' @param trip_id Requested source trip identifier.
#' @param directory New output directory.
#' @param gear One supported source gear.
#' @param observe_version Packaged ObServe schema version.
#' @param extract_table Callback accepting SQL, CSV path and model field names.
#' @param prepare_query Callback preparing each query before extraction starts.
#' @return Absolute CSV paths named by source table.
#' @keywords internal
extract_observe_trip_csv <- function(trip_id,
                                     directory,
                                     gear,
                                     observe_version,
                                     extract_table,
                                     prepare_query = identity) {
  form.tools::require_nonempty_string(trip_id, "trip_id")
  form.tools::require_nonempty_string(directory, "directory")
  form.tools::require_nonempty_string(observe_version, "observe_version")
  if (!grepl("^[0-9]+([.][0-9]+)*$", observe_version))
    stop("observe_version must identify a packaged numeric version", call. = FALSE)
  form.tools::require_nonempty_string(gear, "gear")
  if (!gear %in% c(OBSERVE_GEAR_LL, OBSERVE_GEAR_PS))
    stop("gear must be 'll' or 'ps'", call. = FALSE)
  resources_directory <- system.file(observe_version, gear, package = "ros.form.observe")
  if (!nzchar(resources_directory))
    stop("No packaged source model for ObServe ", observe_version, " / ", gear, call. = FALSE)
  source_model <- form.model::read_form_model(file.path(resources_directory, "form.yaml"))
  queries_directory <- file.path(resources_directory, "sql")
  sheets <- form.model::form_sheets(source_model)

  directory <- path.expand(directory)
  parent <- normalizePath(dirname(directory), winslash = "/", mustWork = TRUE)
  directory <- file.path(parent, basename(directory))
  if (!dir.create(directory, mode = "0700", showWarnings = FALSE))
    stop("Could not create a new trip directory: ", directory, call. = FALSE)
  completed <- FALSE
  on.exit(if (!completed) unlink(directory, recursive = TRUE), add = TRUE)

  paths <- file.path(directory, paste0(names(sheets), ".csv"))
  names(paths) <- names(sheets)
  queries <- lapply(names(sheets), function(sheet) {
    if (sheets[[sheet]]$layout$kind != "table")
      stop("SQL loading requires a table layout: ", sheet, call. = FALSE)
    if (grepl("[/\\\\]", sheet) || sheet %in% c(".", ".."))
      stop("Sheet name cannot identify a query filename: ", sheet, call. = FALSE)
    sql <- db.tools::read_sql_file(file.path(queries_directory, paste0(sheet, ".sql")))
    sql <- sub("^\ufeff", "", sql)
    if (!nzchar(trimws(sql))) stop("Empty SQL file for ", sheet, call. = FALSE)
    prepare_query(sql)
  })
  for (i in seq_along(paths)) {
    extract_table(queries[[i]], paths[[i]], names(sheets[[i]]$fields))
  }
  completed <- TRUE
  paths
}

#' Create a CSV writer for SQL queries on an open DBI connection
#' @param connection Open DBI connection.
#' @param trip_id Source trip identifier passed to every query.
#' @return A function that runs one query, checks its column names and writes its CSV.
#' @keywords internal
create_sql_csv_writer <- function(connection, trip_id) {
  table_loader <- form.tools::sql_table_loader(connection)
  function(sql, csv_path, fields) {
    table_name <- sub("[.]csv$", "", basename(csv_path))
    table <- tryCatch(table_loader(sql, params = list(trip_id)), error = function(error) {
      stop("Cannot load ", table_name, ": ", conditionMessage(error), call. = FALSE)
    })
    if (!identical(names(table), fields))
      stop("Query columns differ from model fields for ", table_name, call. = FALSE)
    write_sql_result_csv(table, csv_path)
  }
}

#' Write a database result in the default ObServe CSV format
#' @param table Query result with its SQL column names.
#' @param path File to create.
#' @return Invisible `NULL`.
#' @keywords internal
write_sql_result_csv <- function(table, path) {
  fields <- lapply(table, format_csv_column)
  names(fields) <- enc2utf8(names(table))
  output <- file(path, open = "wb")
  on.exit(close(output), add = TRUE)
  utils::write.table(as.data.frame(fields, check.names = FALSE), file = output,
                     sep = ",", eol = "\r\n", row.names = FALSE, na = "", qmethod = "double")
  invisible(NULL)
}

#' Format a direct database result column as CSV text
#' @param values One query result column.
#' @return UTF-8 text retaining missing values for the CSV writer.
#' @keywords internal
format_csv_column <- function(values) {
  if (inherits(values, "POSIXt")) {
    text <- sub("0{1,5}$", "", format(values, "%Y-%m-%d %H:%M:%OS6", tz = "UTC"))
  } else if (is.logical(values)) {
    text <- tolower(as.character(values))
  } else if (is.double(values) && !is.object(values)) {
    text <- sprintf("%.17g", values)
    text[which(values == Inf)] <- "Infinity"
    text[which(values == -Inf)] <- "-Infinity"
    text[is.na(values) & !is.nan(values)] <- NA_character_
  } else text <- as.character(values)
  enc2utf8(text)
}
