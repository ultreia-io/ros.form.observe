# Public operations ---------------------------------------------------------

#' Select longline trip IDs through the public API
#'
#' Select trips whose dates overlap the requested period, including both
#' boundaries. An empty programme filter includes every observation programme.
#' @param connection An open ObServe public API session.
#' @param start_date,end_date Inclusive boundaries, each a single R `Date`.
#' @param programme_ids Character vector of observation programme `topiaId`
#'   values from the ObServe catalogue. Defaults to `character()`.
#' @return Character vector of matching trip `topiaId` values ordered by ID.
#' @seealso [observe_public_api_with_connection()], [observe_public_api_extract_trip_csv()]
#' @export
observe_public_api_select_trip_ids <- function(connection, start_date, end_date,
                                               programme_ids = character()) {
  values <- prepare_observe_trip_selection(start_date, end_date, programme_ids)
  observe_public_api_check_connection(connection)
  # The date and ID checks restrict these values to safe SQL literals.
  sql <- build_observe_trip_selection_sql(paste0("'", values, "'"))
  response <- observe_public_api_send_request(connection$url, "sql/csv", connection$timeout,
    token = connection$token, sql = sql)
  if (!identical(httr2::resp_content_type(response), "text/csv"))
    stop("Expected a CSV response for trip selection.", call. = FALSE)

  trips <- tryCatch(
    utils::read.csv(text = httr2::resp_body_string(response), colClasses = "character",
      na.strings = character(), check.names = FALSE),
    error = function(error) stop("Could not read the trip selection CSV response.", call. = FALSE)
  )
  if (!identical(names(trips), "trip_id"))
    stop("Expected a trip_id column in the trip selection CSV response.", call. = FALSE)
  trips$trip_id
}

#' Select longline trip IDs through PostgreSQL
#'
#' Select trips whose dates overlap the requested period, including both
#' boundaries. An empty programme filter includes every observation programme.
#' @param connection An open PostgreSQL DBI connection.
#' @param start_date,end_date Inclusive boundaries, each a single R `Date`.
#' @param programme_ids Character vector of observation programme `topiaId`
#'   values from the ObServe catalogue. Defaults to `character()`.
#' @return Character vector of matching trip `topiaId` values ordered by ID.
#' @seealso [db.tools::with_db_connection()], [observe_sql_extract_trip_csv()]
#' @export
observe_sql_select_trip_ids <- function(connection, start_date, end_date,
                                        programme_ids = character()) {
  values <- prepare_observe_trip_selection(start_date, end_date, programme_ids)
  load_table <- form.tools::sql_table_loader(connection)
  sql <- build_observe_trip_selection_sql(paste0("$", seq_along(values)))
  load_table(sql, params = as.list(values))$trip_id
}

# Internal helpers ----------------------------------------------------------

#' Check and order the longline trip selection filters
#' @param start_date,end_date Requested inclusive date boundaries.
#' @param programme_ids Optional observation programme `topiaId` values.
#' @return Character vector in SQL argument order.
#' @keywords internal
prepare_observe_trip_selection <- function(start_date, end_date, programme_ids) {
  if (!inherits(start_date, "Date") || !inherits(end_date, "Date") ||
      length(start_date) != 1L || length(end_date) != 1L ||
      !is.finite(start_date) || !is.finite(end_date) || start_date > end_date)
    stop("Supply one start date and one end date in chronological order.", call. = FALSE)
  if (!is.character(programme_ids) || !all(grepl("^[A-Za-z0-9_.:#-]+$", programme_ids)))
    stop("Supply observation programme topiaIds.", call. = FALSE)
  c(as.character(end_date), as.character(start_date), programme_ids)
}

#' Build the query for longline trips overlapping the requested dates
#' @param sql_arguments SQL literals or placeholders for end date, start date
#'   and any programme IDs, in that order.
#' @return SQL selecting the ordered trip IDs.
#' @keywords internal
build_observe_trip_selection_sql <- function(sql_arguments) {
  programme_arguments <- sql_arguments[-c(1L, 2L)]
  programme_clause <- if (length(programme_arguments)) {
    paste0("\n  AND t.observationProgram IN (", paste(programme_arguments, collapse = ", "), ")")
  } else ""
  paste0(
    'SELECT t.topiaId AS "trip_id"\nFROM ll_common.trip AS t',
    "\nWHERE t.startDate <= ", sql_arguments[[1L]], "::date",
    "\n  AND t.endDate >= ", sql_arguments[[2L]], "::date",
    programme_clause,
    "\nORDER BY t.topiaId"
  )
}
