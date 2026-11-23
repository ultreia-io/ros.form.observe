#' Create an ObServe connection provider from an H2 SQL backup
#'
#' Load the caller-selected H2 driver and delegate restoration to
#' [db.tools::h2_backup_connection_provider()]. Use the returned provider with
#' [db.tools::with_db_connection()] and [observe_sql_extract_trip_csv()].
#' @param backup_file Path to an ObServe H2 SQL backup, plain SQL or gzip compressed.
#' @param directory New directory for the restored database. NA uses a unique
#'   session-temporary path. An explicit directory persists; its parent must exist.
#' @param h2_jar Path to the H2 JDBC jar compatible with the backup. Defaults to
#'   the current `H2_JAR` environment variable. The jar is never downloaded.
#' @return A zero-argument function opening a fresh read-only JDBC connection.
#'   Its `directory` and `url` attributes identify the restored database and its
#'   credential-free reopening URL, as documented by db.tools.
#' @details The first call restores the backup; later calls reuse the database.
#'   Existing destinations are rejected and failed restores remove their new
#'   directory. Closing a connection leaves the database available for reuse.
#'   Remove temporary files after closing all connections, or leave their cleanup
#'   to normal R-session termination. Explicit directories are never auto-deleted
#'   after successful restoration.
#'
#'   ObServe backups omit database passwords and settings. This adapter creates
#'   the database with H2's default identifier handling, administrator `sa` and an
#'   empty password. Application login accounts are separate from this database
#'   account. For other H2 settings or credentials, use the neutral db.tools
#'   provider directly.
#'
#'   The caller selects the matching H2 jar and ObServe source-model version.
#'   No database schema migration or backup-version detection is performed.
#' @seealso [observe_sql_extract_trip_csv()]
#' @export
create_observe_h2_backup_connection_provider <- function(backup_file, directory = NA_character_,
                                                         h2_jar = Sys.getenv("H2_JAR")) {
  form.tools::require_nonempty_string(h2_jar, "h2_jar (or H2_JAR)")
  if (!file.exists(h2_jar) || dir.exists(h2_jar) || file.access(h2_jar, 4L) != 0L)
    stop("h2_jar must identify an existing readable H2 JDBC jar", call. = FALSE)
  if (!requireNamespace("RJDBC", quietly = TRUE) || !requireNamespace("db.tools", quietly = TRUE))
    stop("Install RJDBC and db.tools to read ObServe H2 backups", call. = FALSE)
  driver <- RJDBC::JDBC("org.h2.Driver", normalizePath(h2_jar, winslash = "/", mustWork = TRUE),
    identifier.quote = '"')
  db.tools::h2_backup_connection_provider(backup_file, driver, directory = directory,
    user = "sa", password = "", read_only = TRUE)
}
