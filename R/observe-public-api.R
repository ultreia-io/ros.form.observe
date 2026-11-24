#' ObServe public API connections
#'
#' An `observe_public_api_connection` is an environment holding an API URL, timeout,
#' authentication token and closed flag. Create it with [observe_public_api_connect_from_yaml()]
#' and close it with [observe_public_api_disconnect()]. The caller owns its lifecycle.
#'
#' Copies share the same session state. The print method omits authentication
#' details. The password is not retained in the connection. Do not serialize the
#' connection: it contains a live session token. Session renewal is not automatic.
#' @name observe_public_api_connection-class
#' @seealso [observe_public_api_with_connection()], [observe_public_api_extract_trip_csv()]
NULL

#' Identify the session password variable
#' @param config_file Path to an ObServe API YAML configuration.
#' @return The environment-variable name declared by `password: !env NAME`.
#' @export
observe_public_api_get_password_variable <- function(config_file) {
  observe_public_api_read_configuration(config_file)$password$env
}

#' Set the ObServe password for the current R session
#' @param config_file Path to an ObServe API YAML configuration.
#' @param prompt Function accepting a prompt label and returning a password.
#'   NULL uses askpass::askpass(). A function calling keyring::key_get() can
#'   retrieve an existing keyring entry instead.
#' @return TRUE invisibly. An empty or cancelled entry raises an error and leaves
#'   the current variable unchanged.
#' @details Follows the ros.db.atlas session convention: the secret stays in
#'   the process variable named by `!env`, until it is unset or R terminates.
#'   No password is written to YAML or a persistent keyring by this function.
#' @export
observe_public_api_set_password <- function(config_file, prompt = NULL) {
  variable <- observe_public_api_get_password_variable(config_file)
  if (is.null(prompt)) {
    if (!requireNamespace("askpass", quietly = TRUE)) stop("Install askpass for the password prompt.", call. = FALSE)
    prompt <- askpass::askpass
  }
  if (!is.function(prompt)) stop("prompt must be a function", call. = FALSE)
  password <- prompt("ObServe API password")
  form.tools::require_nonempty_string(password, "Password entry")
  do.call(Sys.setenv, stats::setNames(list(password), variable))
  invisible(TRUE)
}

#' Open an ObServe API session from YAML
#' @param config_file Path to YAML with `url`, `login`, `database` and
#'   `password: !env NAME`. Optional `locale`, `zone_offset` and `timeout` default
#'   to `en_GB`, `+00:00` and 240 seconds. The URL ends at `/api/public`.
#' @return An [observe_public_api_connection-class] owned by the caller.
#' @details Resolves the password only when opening the session. Uses the public
#'   `init/open` endpoint; redirects are refused and errors omit credentials and
#'   response bodies. The configuration must use HTTPS and cannot contain a
#'   username, password, query string or fragment in its URL.
#' @export
observe_public_api_connect_from_yaml <- function(config_file) {
  configuration <- observe_public_api_read_configuration(config_file)
  password <- Sys.getenv(configuration$password$env, unset = NA_character_)
  if (is.na(password) || !nzchar(password)) stop("ObServe password variable is unset or empty", call. = FALSE)
  response <- observe_public_api_send_request(configuration$url, "init/open", configuration$timeout,
    query = list("config.login" = configuration$login, "config.password" = password,
      "config.databaseName" = configuration$database,
      "config.clientZoneOffset" = configuration$zone_offset, "config.locale" = configuration$locale))
  content <- observe_public_api_decode_json(response)
  token <- if (is.list(content)) content$authenticationToken else NULL
  form.tools::require_nonempty_string(token, "ObServe authentication token")
  connection <- new.env(parent = emptyenv())
  connection$url <- configuration$url
  connection$timeout <- configuration$timeout
  connection$token <- token
  connection$closed <- FALSE
  class(connection) <- "observe_public_api_connection"
  connection
}

#' Close an ObServe API session
#' @param connection A connection from [observe_public_api_connect_from_yaml()].
#' @return TRUE invisibly after closing; FALSE if already closed.
#' @details A failed close raises an error and retains the token so the caller can
#'   retry. A successful close clears the local token and disables all its loaders.
#' @export
observe_public_api_disconnect <- function(connection) {
  observe_public_api_check_connection(connection, allow_closed = TRUE)
  if (connection$closed) return(invisible(FALSE))
  observe_public_api_send_request(connection$url, "init/close", connection$timeout, token = connection$token)
  connection$token <- NULL
  connection$closed <- TRUE
  invisible(TRUE)
}

#' Use and automatically close an ObServe API session
#' @param connection_provider Zero-argument function opening a new API connection.
#' @param code Function receiving that connection.
#' @return The value returned by `code`.
#' @details Owns the supplied connection and closes it on success or error, like
#'   db.tools::with_db_connection(). Do not supply an externally shared session.
#'   Failure to close emits a sanitized warning without replacing the callback error.
#' @export
observe_public_api_with_connection <- function(connection_provider, code) {
  if (!is.function(connection_provider) || !is.function(code))
    stop("connection_provider and code must be functions", call. = FALSE)
  connection <- connection_provider()
  observe_public_api_check_connection(connection)
  on.exit(tryCatch(observe_public_api_disconnect(connection), error = function(error)
    warning("Could not close the ObServe API session", call. = FALSE)), add = TRUE)
  code(connection)
}

#' @rdname observe_public_api_connection-class
#' @param x An ObServe API connection.
#' @param ... Unused arguments.
#' @return The print method returns `x` invisibly after displaying the open or
#'   closed state, without the URL, password or token.
#' @export
print.observe_public_api_connection <- function(x, ...) {
  cat("<observe_public_api_connection>", if (isTRUE(x$closed)) "closed" else "open", "\n")
  invisible(x)
}

# Internal helpers ----------------------------------------------------------

#' Read and validate an ObServe public API configuration
#' @param config_file Path to a YAML configuration containing an HTTPS API URL,
#'   login, database and a password environment-variable reference.
#' @return A configuration list with a normalized URL and defaults for locale,
#'   zone offset and timeout. `password$env` contains the variable name, not its
#'   value. No secret is resolved and no request is sent.
#' @details Rejects unknown or duplicate configuration keys, unsafe URL forms,
#'   literal passwords and invalid timeout values. YAML expressions are disabled.
#' @keywords internal
observe_public_api_read_configuration <- function(config_file) {
  form.tools::require_nonempty_string(config_file, "config_file")
  configuration <- yaml::read_yaml(config_file, eval.expr = FALSE,
    handlers = list(env = function(value) list(env = value)))
  allowed <- c("url", "login", "database", "password", "locale", "zone_offset", "timeout")
  if (!is.list(configuration) || is.null(names(configuration)) || anyDuplicated(names(configuration)) ||
      any(!names(configuration) %in% allowed) || !all(allowed[1:4] %in% names(configuration)))
    stop("Expected an ObServe API configuration with url, login, database and password", call. = FALSE)
  for (name in allowed[1:3]) form.tools::require_nonempty_string(configuration[[name]], name)
  if (!grepl("^https://[^/@?#]+(/[^?#]*)?$", configuration$url))
    stop("url must be an HTTPS API base URL without credentials, query or fragment", call. = FALSE)
  configuration$url <- sub("/+$", "", configuration$url)
  password <- configuration$password
  if (!is.list(password) || !identical(names(password), "env") ||
      !is.character(password$env) || length(password$env) != 1L || is.na(password$env) ||
      !grepl("^[A-Za-z_][A-Za-z0-9_]*$", password$env))
    stop("Configure password as !env followed by an environment variable name", call. = FALSE)
  if (is.null(configuration$locale)) configuration$locale <- "en_GB"
  if (is.null(configuration$zone_offset)) configuration$zone_offset <- "+00:00"
  if (is.null(configuration$timeout)) configuration$timeout <- 240
  form.tools::require_nonempty_string(configuration$locale, "locale")
  form.tools::require_nonempty_string(configuration$zone_offset, "zone_offset")
  if (!is.numeric(configuration$timeout) || length(configuration$timeout) != 1L ||
      !is.finite(configuration$timeout) || configuration$timeout <= 0)
    stop("timeout must be positive seconds", call. = FALSE)
  configuration
}

#' Validate an ObServe API connection handle
#' @param connection An environment of class `observe_public_api_connection`.
#' @param allow_closed Whether a closed handle is acceptable, as required by
#'   the idempotent disconnect operation.
#' @return The connection invisibly. Invalid handles and, unless permitted,
#'   closed sessions raise an error before a request is constructed.
#' @keywords internal
observe_public_api_check_connection <- function(connection, allow_closed = FALSE) {
  if (!inherits(connection, "observe_public_api_connection") || !is.environment(connection))
    stop("Expected an ObServe API connection", call. = FALSE)
  if (!allow_closed && isTRUE(connection$closed)) stop("ObServe API connection is closed", call. = FALSE)
  invisible(connection)
}

#' Send a request to an ObServe public API endpoint
#' @param url Validated HTTPS API base URL, without a trailing slash.
#' @param endpoint Relative endpoint path, such as `init/open` or `sql/csv`.
#' @param timeout Positive request timeout in seconds.
#' @param token Optional session token, sent in a redacted authentication header.
#' @param query Optional named list of query parameters, used to open a session.
#' @param sql Optional SQL text; supplying it sends a UTF-8 plain-text POST body.
#' @return An httr2 response with a successful HTTP status. Transport and HTTP
#'   failures raise errors containing the endpoint and, where available, status.
#' @details Redirects are disabled. Error messages omit query parameters, SQL,
#'   credentials and response bodies.
#' @keywords internal
observe_public_api_send_request <- function(url, endpoint, timeout, token = NULL, query = NULL, sql = NULL) {
  response <- tryCatch({
    request <- httr2::request(paste0(url, "/", endpoint))
    request <- httr2::req_timeout(request, timeout)
    request <- httr2::req_options(request, followlocation = FALSE)
    request <- httr2::req_error(request, is_error = function(response) FALSE)
    if (!is.null(query)) request <- do.call(httr2::req_url_query, c(list(request), query))
    if (!is.null(token)) request <- httr2::req_headers(request, authenticationToken = token,
      .redact = "authenticationToken")
    if (!is.null(sql)) request <- httr2::req_body_raw(request, charToRaw(enc2utf8(sql)),
      type = "text/plain; charset=UTF-8")
    httr2::req_perform(request)
  }, error = function(error) stop("ObServe API transport failed at ", endpoint, call. = FALSE))
  status <- httr2::resp_status(response)
  if (status < 200L || status >= 300L)
    stop("ObServe API ", endpoint, " returned HTTP ", status, call. = FALSE)
  response
}

#' Decode an ObServe API JSON response
#' @param response Successful httr2 response returned by [observe_public_api_send_request()].
#' @return Parsed JSON with arrays retained as lists and large integers retained
#'   as text. Invalid JSON raises a sanitized error without the response body.
#' @keywords internal
observe_public_api_decode_json <- function(response) {
  tryCatch(httr2::resp_body_json(response, simplifyVector = FALSE, bigint_as_char = TRUE),
    error = function(error) stop("Invalid ObServe API JSON response", call. = FALSE))
}

#' Check an ObServe trip ID before using it in SQL or a directory name
#' @param trip_id Candidate ObServe trip `topiaId`.
#' @return The validated trip ID invisibly.
#' @keywords internal
observe_public_api_check_trip_id <- function(trip_id) {
  if (!is.character(trip_id) || length(trip_id) != 1L || is.na(trip_id) ||
      !grepl("^[A-Za-z0-9_.:#-]+$", trip_id) || trip_id %in% c(".", ".."))
    stop("Invalid ObServe technical ID", call. = FALSE)
  invisible(trip_id)
}

#' Prepare a restricted trip query for the ObServe SQL service
#' @param sql Consumer-supplied SELECT statement, optionally containing one
#'   `$1::text` placeholder. Full-line SQL comments are removed.
#' @param params NULL or an empty list for a query without parameters; otherwise
#'   one unnamed character technical ID using the supported safe alphabet.
#' @return A SELECT statement with the validated technical ID substituted for
#'   its placeholder. Invalid syntax, values or placeholder counts raise errors.
#' @details This is restricted interpolation for a service without binding, not
#'   a general SQL parser. String literals, backslashes, inline/block comments and
#'   unsupported placeholders are rejected before any network request.
#' @keywords internal
observe_public_api_prepare_query <- function(sql, params) {
  form.tools::require_nonempty_string(sql, "sql")
  lines <- strsplit(sql, "\n", fixed = TRUE)[[1L]]
  statement <- trimws(paste(lines[!grepl("^\\s*--", lines)], collapse = "\n"))
  if (!grepl("^SELECT\\b", statement, ignore.case = TRUE) ||
      grepl("['\\\\]|/\\*|\\*/|--", statement))
    stop("Expected a trip SELECT without SQL literals or inline/block comments", call. = FALSE)
  if (is.null(params) || identical(params, list())) {
    if (grepl("$", statement, fixed = TRUE)) stop("Query parameters are required", call. = FALSE)
    return(statement)
  }
  if (!is.list(params) || length(params) != 1L || !is.null(names(params)))
    stop("ObServe SQL requires one unnamed trip parameter", call. = FALSE)
  value <- params[[1L]]
  observe_public_api_check_trip_id(value)
  unquoted <- gsub('"([^\"]|\"\")*"', '""', statement)
  matches <- gregexpr("$1::text", unquoted, fixed = TRUE)[[1L]]
  if (identical(matches[[1L]], -1L) || length(matches) != 1L ||
      grepl("$", sub("$1::text", "", statement, fixed = TRUE), fixed = TRUE))
    stop("Expected exactly one $1::text trip placeholder", call. = FALSE)
  sub("$1::text", paste0("'", value, "'::text"), statement, fixed = TRUE)
}

#' Save one public API CSV response without parsing it
#' @param connection Open ObServe public API session.
#' @param sql Prepared SQL query for one source table.
#' @param csv_path Destination CSV file for the source table.
#' @return Invisible `NULL`.
#' @keywords internal
observe_public_api_save_csv <- function(connection, sql, csv_path) {
  observe_public_api_check_connection(connection)
  response <- observe_public_api_send_request(connection$url, "sql/csv", connection$timeout,
    token = connection$token, sql = sql)
  table_name <- sub("[.]csv$", "", basename(csv_path))
  if (!identical(httr2::resp_content_type(response), "text/csv"))
    stop("Expected a CSV response for ", table_name, call. = FALSE)
  body <- httr2::resp_body_raw(response)
  if (!length(body)) stop("Empty CSV response for ", table_name, call. = FALSE)
  writeBin(body, csv_path)
  invisible(NULL)
}
