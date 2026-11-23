api_config <- function(directory) {
  path <- file.path(directory, "observe-api.yaml")
  writeLines(c("url: https://observe.example.org/api/public", "login: test-user",
    "database: test-database", "password: !env TEST_OBSERVE_PASSWORD"), path)
  path
}

api_response <- function(body, status = 200L, content_type = "application/json") {
  httr2::response(status_code = status, headers = list("Content-Type" = content_type),
    body = charToRaw(enc2utf8(body)))
}

test_that("public API extraction saves each CSV response byte for byte", {
  directory <- withr::local_tempdir()
  config <- api_config(directory)
  withr::local_envvar(TEST_OBSERVE_PASSWORD = "test-password")
  resources <- system.file("10.0", "ll", package = "ros.form.observe", mustWork = TRUE)
  definitions <- form.model::form_sheets(form.model::read_form_model(file.path(resources, "form.yaml")))
  csv_response <- '"id","note","count"\r\n"001","","0"\r\n"002",,\r\n"003","caf\u00e9 ""test""\nnext",\r\n'
  requests <- list()
  httr2::local_mocked_responses(function(req) {
    requests[[length(requests) + 1L]] <<- req
    if (grepl("/init/open?", req$url, fixed = TRUE)) api_response('{"authenticationToken":"test-token"}')
    else if (endsWith(req$url, "/sql/csv")) api_response(csv_response, content_type = "text/csv; charset=UTF-8")
    else api_response("{}")
  })
  connection <- observe_public_api_connect_from_yaml(config)
  trip_directory <- file.path(directory, "trip")
  paths <- observe_public_api_extract_trip_csv("trip#001", connection, trip_directory)
  expect_identical(names(paths), names(definitions))
  expect_identical(basename(paths), paste0(names(definitions), ".csv") |> unname())
  expect_setequal(list.files(trip_directory), basename(paths))
  for (path in paths)
    expect_identical(readBin(path, "raw", n = file.size(path)), charToRaw(enc2utf8(csv_response)))
  expect_match(rawToChar(requests[[2]]$body$data), "= 'trip#001'::text", fixed = TRUE)
  expect_true("authenticationToken" %in% names(requests[[2]]$headers))
  expect_false(connection$closed)
  observe_public_api_disconnect(connection)
  expect_true(connection$closed)
  expect_null(connection$token)
  expect_error(observe_public_api_extract_trip_csv("trip#001", connection, file.path(directory, "closed")), "closed")
  expect_length(requests, length(definitions) + 2L)
})

test_that("public API CSV extraction retains headers when queries return no rows", {
  directory <- withr::local_tempdir()
  config <- api_config(directory)
  withr::local_envvar(TEST_OBSERVE_PASSWORD = "test-password")
  resources <- system.file("10.0", "ll", package = "ros.form.observe", mustWork = TRUE)
  definitions <- form.model::form_sheets(form.model::read_form_model(file.path(resources, "form.yaml")))
  headers <- lapply(definitions, function(sheet) paste0('"', paste(names(sheet$fields), collapse = '","'), '"\r\n'))
  responses <- c(list(api_response('{"authenticationToken":"test-token"}')),
    lapply(headers, api_response, content_type = "text/csv"), list(api_response("{}")))
  httr2::local_mocked_responses(unname(responses))
  connection <- observe_public_api_connect_from_yaml(config)
  on.exit(observe_public_api_disconnect(connection))
  paths <- observe_public_api_extract_trip_csv("trip#missing", connection, file.path(directory, "empty"))
  expect_identical(names(paths), names(definitions))
  for (sheet in names(paths))
    expect_identical(readBin(paths[[sheet]], "raw", n = file.size(paths[[sheet]])),
      charToRaw(headers[[sheet]]))
  expect_false(connection$closed)
})

test_that("public API query preparation rejects unsupported values before sending SQL", {
  directory <- withr::local_tempdir()
  config <- api_config(directory)
  withr::local_envvar(TEST_OBSERVE_PASSWORD = "test-password")
  requests <- 0L
  httr2::local_mocked_responses(function(req) {
    requests <<- requests + 1L
    api_response(if (requests == 1L) '{"authenticationToken":"test-token"}' else '{}')
  })
  connection <- observe_public_api_connect_from_yaml(config)
  on.exit(observe_public_api_disconnect(connection))
  sql <- "SELECT topiaId FROM ll_common.trip WHERE topiaId = $1::text"
  expect_error(observe_public_api_extract_trip_csv("invalid identifier", connection, file.path(directory, "invalid")),
    "Invalid ObServe technical ID")
  expect_error(observe_public_api_prepare_query(sql, list(NA_character_)), "Invalid ObServe technical ID")
  expect_error(observe_public_api_prepare_query(sql, list(trip = "id")), "unnamed trip")
  expect_error(observe_public_api_prepare_query(sub("$1", "$2", sql, fixed = TRUE), list("id")), "placeholder")
  expect_error(observe_public_api_prepare_query("SELECT '$1::text' AS literal", list("id")), "SQL literals")
  expect_error(observe_public_api_prepare_query('SELECT topiaId AS "$1::text" FROM ll_common.trip', list("id")),
    "placeholder")
  expect_identical(requests, 1L)
})

test_that("failed public API extraction removes partial CSVs and closes the owned session", {
  directory <- withr::local_tempdir()
  config <- api_config(directory)
  withr::local_envvar(TEST_OBSERVE_PASSWORD = "test-password")
  endpoints <- character()
  csv_calls <- 0L
  httr2::local_mocked_responses(function(req) {
    endpoints <<- c(endpoints, req$url)
    if (grepl("/init/open?", req$url, fixed = TRUE)) return(api_response('{"authenticationToken":"test-token"}'))
    if (endsWith(req$url, "/sql/csv")) {
      csv_calls <<- csv_calls + 1L
      if (csv_calls == 1L) return(api_response('"id"\r\n', content_type = "text/csv"))
      return(api_response('{"message":"server diagnostic"}', 500L))
    }
    api_response("{}")
  })
  connection <- NULL
  trip_directory <- file.path(directory, "failed")
  expect_error(observe_public_api_with_connection(function() {
    connection <<- observe_public_api_connect_from_yaml(config)
    connection
  }, function(connection) observe_public_api_extract_trip_csv("trip#001", connection, trip_directory)),
    "returned HTTP 500")
  expect_identical(csv_calls, 2L)
  expect_false(file.exists(trip_directory))
  expect_true(connection$closed)
  expect_match(tail(endpoints, 1L), "init/close$")
})
