# Public operations ---------------------------------------------------------

#' Extract one ObServe trip to CSV through a database connection
#'
#' Run one query per source table on an open DBI connection and write the rows to CSV.
#' @param trip_id One source trip `topiaId`, passed to every query.
#' @param connection An open DBI connection owned by the caller.
#' @param directory Existing root directory for the trips. A new subdirectory
#'   named after `trip_id` is created inside it.
#' @param gear One source gear, [ros.form.model::ROS_FORM_LL] or [ros.form.model::ROS_FORM_PS].
#' @param observe_version Packaged ObServe source-model version. Defaults to [OBSERVE_VERSION_10_0].
#' @param export_context Optional context from [load_export_context()]. Its
#'   ObServe form model and prepared SQL determine the extraction when supplied.
#' @return The absolute path to the created trip directory.
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
                                         gear = ros.form.model::ROS_FORM_LL,
                                         observe_version = OBSERVE_VERSION_10_0,
                                         export_context = NULL) {
  extract_observe_trip_csv(trip_id, directory, gear, observe_version,
                           extract_table = create_sql_csv_writer(connection, trip_id),
                           export_context = export_context)
}

#' Extract one ObServe trip to CSV through the public API
#'
#' Submit one query per source table to `sql/csv` and save each response byte for byte.
#' @param trip_id One source trip `topiaId`, passed to every query.
#' @param connection An open session from [observe_public_api_connect_from_yaml()].
#' @param directory Existing root directory for the trips. A new subdirectory
#'   named after `trip_id` is created inside it.
#' @param gear One source gear, [ros.form.model::ROS_FORM_LL] or [ros.form.model::ROS_FORM_PS].
#' @param observe_version Packaged ObServe source-model version. Defaults to [OBSERVE_VERSION_10_0].
#' @param export_context Optional context from [load_export_context()]. Its
#'   ObServe form model and prepared SQL determine the extraction when supplied.
#' @return The absolute path to the created trip directory.
#'   Empty results have a header and no data rows.
#' @details Each file is named `<qualified-table>.csv`. Each request uses its own
#'   database snapshot. If extraction fails, the new directory and its partial
#'   files are removed.
#' @seealso [observe_public_api_with_connection()]
#' @export
observe_public_api_extract_trip_csv <- function(trip_id,
                                                connection,
                                                directory,
                                                gear = ros.form.model::ROS_FORM_LL,
                                                observe_version = OBSERVE_VERSION_10_0,
                                                export_context = NULL) {
  observe_public_api_check_trip_id(trip_id)
  extract_observe_trip_csv(trip_id, directory, gear, observe_version,
    extract_table = function(sql, csv_path, fields) observe_public_api_save_csv(connection, sql, csv_path),
    prepare_query = function(sql) observe_public_api_prepare_query(sql, list(trip_id)),
    export_context = export_context
  )
}

# Internal helpers ----------------------------------------------------------

#' Run the model's table extraction through an explicit CSV writer
#' @param trip_id Requested source trip identifier.
#' @param directory Existing root directory for trip outputs.
#' @param gear One supported source gear.
#' @param observe_version Packaged ObServe schema version.
#' @param extract_table Callback accepting SQL, CSV path and model field names.
#' @param prepare_query Callback preparing each query before extraction starts.
#' @param export_context Optional context supplying the loaded model and SQL directory.
#' @return The absolute path to the created trip directory.
#' @keywords internal
extract_observe_trip_csv <- function(trip_id,
                                     directory,
                                     gear,
                                     observe_version,
                                     extract_table,
                                     prepare_query = identity,
                                     export_context = NULL) {
  form.tools::require_nonempty_string(trip_id, "trip_id")
  if (grepl("[/\\\\]", trip_id) || trip_id %in% c(".", ".."))
    stop("trip_id must be a directory name", call. = FALSE)
  form.tools::require_nonempty_string(directory, "directory")
  if (is.null(export_context)) {
    form.tools::require_nonempty_string(observe_version, "observe_version")
    if (!grepl("^[0-9]+([.][0-9]+)*$", observe_version))
      stop("observe_version must identify a packaged numeric version", call. = FALSE)
    form.tools::require_nonempty_string(gear, "gear")
    if (!gear %in% c(ros.form.model::ROS_FORM_LL, ros.form.model::ROS_FORM_PS))
      stop("gear must be 'll' or 'ps'", call. = FALSE)
    resources_directory <- system.file(observe_version, gear, package = "ros.form.observe")
    if (!nzchar(resources_directory))
      stop("No packaged source model for ObServe ", observe_version, " / ", gear, call. = FALSE)
    source_model <- form.model::read_form_model(file.path(resources_directory, "form.yaml"))
    queries_directory <- file.path(resources_directory, "sql")
  } else {
    if (!inherits(export_context, "export_context"))
      stop("Load the context with load_export_context().", call. = FALSE)
    source_model <- export_context$observe_form_model
    queries_directory <- export_context$paths$observe_sql_directory
  }
  sheets <- form.model::form_sheets(source_model)

  root_directory <- normalizePath(path.expand(directory), winslash = "/", mustWork = TRUE)
  if (!dir.exists(root_directory))
    stop("Expected a root directory for the trips: ", root_directory, call. = FALSE)
  trip_directory <- file.path(root_directory, trip_id)
  if (!dir.create(trip_directory, mode = "0700", showWarnings = FALSE))
    stop("Could not create a new trip directory: ", trip_directory, call. = FALSE)
  completed <- FALSE
  on.exit(if (!completed) unlink(trip_directory, recursive = TRUE), add = TRUE)

  paths <- file.path(trip_directory, paste0(names(sheets), ".csv"))
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
  trip_directory
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
