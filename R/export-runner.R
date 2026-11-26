# Public operations ---------------------------------------------------------

#' Prepare a batch from its export runner file
#' @param runner_path Path to export-runner.yaml in the batch directory.
#' @return An [export_context][load_export_context] with the shared inputs and
#'   references, trip source and filters, and typed META values.
#' @details The parent of the batch directory is the workspace. Set
#'   `observe_trip_source` to the stem of a workspace connection file ending in
#'   `.postgresql.yaml` or `.public-api.yaml`. The reader opens the file when
#'   extracting trips.
#' @export
prepare_export <- function(runner_path = "export-runner.yaml") {
  form.tools::require_nonempty_string(runner_path, "runner_path")
  if (basename(runner_path) != "export-runner.yaml")
    stop("Use a batch file named export-runner.yaml.", call. = FALSE)
  runner_path <- normalizePath(path.expand(runner_path), winslash = "/", mustWork = TRUE)
  runner <- yaml::read_yaml(runner_path, eval.expr = FALSE)
  keys <- c("observe_version", "ros_form_version", "gear", "observe_trip_source", "trips", "meta")
  check_runner_mapping(runner, keys, keys, "export-runner.yaml")
  settings <- export_settings(runner$observe_version, runner$ros_form_version,
                              runner$gear, dirname(runner_path))
  workspace_directory <- export_paths(settings)$workspace$directory
  trip_source <- resolve_export_trip_source(runner$observe_trip_source, workspace_directory)
  trip_filters <- prepare_export_trip_filters(runner$trips)
  prepare_export_inputs(settings)
  context <- prepare_export_references(load_export_context(settings))
  context$observe_trip_source <- trip_source
  context$trip_filters <- trip_filters
  context$meta <- prepare_export_metadata(runner$meta, context)
  context
}

#' Select and extract the ObServe trips for a batch
#' @param export_context Context returned by [prepare_export()].
#' @return The absolute path to the completed batch sources directory.
#' @details Saves the selected trip IDs, the original CSV files and the typed
#'   tables for each trip. A failed extraction leaves no partial sources directory.
#' @export
extract_export_sources <- function(export_context) {
  if (!inherits(export_context, "export_context") || is.null(export_context$observe_trip_source))
    stop("Prepare the batch with prepare_export().", call. = FALSE)
  paths <- export_context$paths$batch
  if (file.exists(paths$sources_directory))
    stop("Batch sources already exist: ", paths$sources_directory, call. = FALSE)
  staging <- tempfile(".sources-", tmpdir = paths$directory)
  if (!dir.create(staging, mode = "0700"))
    stop("Cannot stage batch sources in: ", paths$directory, call. = FALSE)
  on.exit(unlink(staging, recursive = TRUE), add = TRUE)
  trips_directory <- file.path(staging, basename(paths$trips_directory))
  if (!dir.create(trips_directory))
    stop("Cannot create the trips directory.", call. = FALSE)

  source <- export_context$observe_trip_source
  if (source$type == "public-api") {
    observe_public_api_with_connection(
      function() observe_public_api_connect_from_yaml(source$path),
      function(connection) save_export_trip_sources(export_context, connection, staging,
        trips_directory, observe_public_api_select_trip_ids, observe_public_api_extract_trip_csv)
    )
  } else {
    if (!requireNamespace("RPostgres", quietly = TRUE))
      stop("Install RPostgres to extract from PostgreSQL.", call. = FALSE)
    db.tools::with_db_connection(
      function() db.tools::db_connect_from_yaml(RPostgres::Postgres(), source$path),
      function(connection) save_export_trip_sources(export_context, connection, staging,
        trips_directory, observe_sql_select_trip_ids, observe_sql_extract_trip_csv)
    )
  }
  if (file.exists(paths$sources_directory) || !file.rename(staging, paths$sources_directory))
    stop("Cannot save batch sources: ", paths$sources_directory, call. = FALSE)
  paths$sources_directory
}

#' Transform one extracted ObServe trip into ROS tables
#' @param export_plan Plan from [form.tools::prepare_form_export()] built with
#'   the form models, configuration and rules in `export_context`.
#' @param observe_trip_tables Named list of extracted ObServe tables for the trip.
#' @param export_context Prepared batch context from [prepare_export()].
#' @return The ROS tables and diagnostics after [finalize_ros_trip()].
#' @export
export_ros_trip <- function(export_plan, observe_trip_tables, export_context) {
  form.tools::run_form_export(export_plan, observe_trip_tables,
    inputs = list(meta = export_context$meta),
    resources = export_context,
    finalize = finalize_ros_trip)
}

# Internal helpers ----------------------------------------------------------

#' Check the names of an export runner mapping
#' @param value Parsed YAML mapping.
#' @param allowed,required Allowed and required keys.
#' @param label Location used in diagnostics.
#' @return No value. Invalid mappings raise an error.
#' @keywords internal
check_runner_mapping <- function(value, allowed, required, label) {
  keys <- names(value)
  if (!is.list(value) || anyDuplicated(keys) || length(keys) != length(value) ||
      any(!keys %in% allowed))
    stop(label, " must be a mapping with recognised, unique keys.", call. = FALSE)
  missing <- setdiff(required, keys)
  if (length(missing))
    stop(label, " is missing: ", paste(missing, collapse = ", "), call. = FALSE)
}

#' Resolve the workspace file for a named trip connection
#' @param source Connection filename without `.yaml`.
#' @param workspace_directory Directory containing the connection file.
#' @return The backend type and path to the connection file.
#' @keywords internal
resolve_export_trip_source <- function(source, workspace_directory) {
  form.tools::require_nonempty_string(source, "observe_trip_source")
  if (!grepl("^[A-Za-z0-9][A-Za-z0-9._-]*[.](postgresql|public-api)$", source))
    stop("observe_trip_source must be a workspace connection name ending in .postgresql or .public-api.",
         call. = FALSE)
  path <- file.path(workspace_directory, paste0(source, ".yaml"))
  if (!file.exists(path) || dir.exists(path))
    stop("Missing workspace connection file: ", path, call. = FALSE)
  list(type = sub("^.*[.]", "", source), path = path)
}

#' Prepare the batch trip filters
#' @param filters Parsed trips mapping.
#' @return Named filters for the trip selectors.
#' @keywords internal
prepare_export_trip_filters <- function(filters) {
  date_keys <- c("start_date", "end_date")
  check_runner_mapping(filters, c(date_keys, "programme_ids"), date_keys, "trips")
  for (name in date_keys) {
    if (!form.model::form_value_matches_type(filters[[name]], "date"))
      stop("trips.", name, " must be a date in YYYY-MM-DD format.", call. = FALSE)
    filters[[name]] <- as.Date(filters[[name]])
  }
  if (is.null(filters$programme_ids) || identical(filters$programme_ids, list()))
    filters$programme_ids <- character()
  prepare_observe_trip_selection(filters$start_date, filters$end_date, filters$programme_ids)
  filters
}

#' Validate and type the writable META fields for all trips
#' @param meta Parsed meta mapping.
#' @param context Prepared models, references and export configuration.
#' @return The META values keyed by ROS form model field name.
#' @keywords internal
prepare_export_metadata <- function(meta, context) {
  fields <- form.model::form_sheets(context$ros_form_model)$META$fields
  preserved <- unlist(context$export_configuration$sheets$META$preserve_fields, use.names = FALSE)
  fields <- fields[setdiff(names(fields), preserved)]
  mandatory <- vapply(fields, function(field) isTRUE(field$mandatory), logical(1))
  check_runner_mapping(meta, names(fields), names(fields)[mandatory], "meta")
  values <- lapply(names(fields), function(name) {
    field <- fields[[name]]
    value <- meta[[name]]
    if (is.null(value) && !isTRUE(field$mandatory)) return(NA_character_)
    if (!form.model::form_value_matches_type(value, field$type) ||
        (is.character(value) && !nzchar(trimws(value))))
      stop("meta.", name, " must be a nonempty ", field$type, " value.", call. = FALSE)
    if ((!is.null(field$minimum) && value < field$minimum) ||
        (!is.null(field$maximum) && value > field$maximum))
      stop("meta.", name, " is outside the allowed range.", call. = FALSE)
    if (!is.null(field$enum) && !value %in% field$enum)
      stop("meta.", name, " is outside the allowed values.", call. = FALSE)
    binding <- field$reference
    if (!is.null(binding)) {
      key <- paste(binding$catalogue, binding$table, binding$lookup, sep = "/")
      matches <- form.references::reference_match_rows(context$ros_references[[key]], value)
      if (!length(matches[[1L]]))
        stop("meta.", name, " has no match in ", key, ".", call. = FALSE)
    }
    if (field$type == "date") return(as.Date(value))
    if (field$type == "integer") return(as.integer(value))
    value
  })
  stats::setNames(values, names(fields))
}

#' Save trip selection and extract each selected trip
#' @param context Prepared batch context.
#' @param connection Open ObServe connection.
#' @param staging,trips_directory Directories for the staged batch sources and trip files.
#' @param select_trip_ids,extract_trip_csv Operations for the chosen backend.
#' @return No value. Writes trip IDs, CSV files and typed tables.
#' @keywords internal
save_export_trip_sources <- function(context, connection, staging, trips_directory,
                                     select_trip_ids, extract_trip_csv) {
  trip_ids <- do.call(select_trip_ids, c(list(connection = connection), context$trip_filters))
  utils::write.csv(data.frame(trip_id = trip_ids), row.names = FALSE,
                   file.path(staging, basename(context$paths$batch$trip_ids_path)))
  for (trip_id in trip_ids) {
    csv_directory <- extract_trip_csv(trip_id, connection, trips_directory, export_context = context)
    trip_tables <- form.tools::read_form_csv_tables(context$observe_form_model, csv_directory)
    saveRDS(trip_tables, file.path(trips_directory, paste0(trip_id, ".Rds")))
  }
}
