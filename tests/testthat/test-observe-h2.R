# Create a small backup with the real packaged tables and two separate trip hierarchies.
observe_test_backup <- function(driver, backup_file, gear) {
  resources <- system.file("10.0", gear, package = "ros.form.observe", mustWork = TRUE)
  model <- form.model::read_form_model(file.path(resources, "form.yaml"))
  definitions <- form.model::form_sheets(model)
  connection <- DBI::dbConnect(driver, paste0("jdbc:h2:mem:", basename(tempfile("observe-backup-"))), "sa", "")
  on.exit(DBI::dbDisconnect(connection))
  for (schema in unique(sub("[.].*$", "", names(definitions))))
    RJDBC::dbSendUpdate(connection, paste("CREATE SCHEMA", schema))
  for (sheet in names(definitions)) {
    columns <- paste0('"', toupper(names(definitions[[sheet]]$fields)), '" VARCHAR')
    RJDBC::dbSendUpdate(connection, paste0("CREATE TABLE ", sheet, " (", paste(columns, collapse = ", "), ")"))
  }
  for (number in 1:2) {
    trip <- paste0("trip#", number)
    activity <- paste0("activity#", number)
    RJDBC::dbSendUpdate(connection, paste0("INSERT INTO ", gear, "_common.trip (topiaId) VALUES (?)"), trip)
    if (gear == "ll") {
      RJDBC::dbSendUpdate(connection,
        "UPDATE ll_common.trip SET ersId = ?, generalComment = ?, logbookComment = ? WHERE topiaId = ?",
        "001", "", "caf\u00e9 \"quote\"\nnext", trip)
      RJDBC::dbSendUpdate(connection, "INSERT INTO ll_observation.activity (topiaId, trip) VALUES (?, ?)",
        activity, trip)
    } else {
      route <- paste0("route#", number)
      RJDBC::dbSendUpdate(connection, "INSERT INTO ps_observation.route (topiaId, trip) VALUES (?, ?)", route, trip)
      RJDBC::dbSendUpdate(connection, "INSERT INTO ps_observation.activity (topiaId, route) VALUES (?, ?)", activity, route)
    }
    RJDBC::dbSendUpdate(connection, paste0("INSERT INTO ", gear,
      "_observation.fishingSet (topiaId, activity) VALUES (?, ?)"), paste0("set#", number), activity)
  }
  invisible(db.tools::db_query(connection, paste0("SCRIPT NOPASSWORDS NOSETTINGS TO ",
    DBI::dbQuoteString(connection, backup_file), " COMPRESSION GZIP")))
  definitions
}

test_that("H2 backups produce a separate CSV dataset for each LL and PS trip", {
  skip_if_not_installed("RJDBC")
  jar <- Sys.getenv("H2_JAR")
  skip_if(!nzchar(jar) || !file.exists(jar), "Set H2_JAR to the ObServe H2 driver jar")
  driver <- RJDBC::JDBC("org.h2.Driver", jar, identifier.quote = '"')
  directory <- withr::local_tempdir()
  for (gear in c(OBSERVE_GEAR_LL, OBSERVE_GEAR_PS)) {
    backup <- file.path(directory, paste0(gear, ".sql.gz"))
    definitions <- observe_test_backup(driver, backup, gear)
    destination <- if (gear == "ll") NA_character_ else file.path(directory, "persistent-ps")
    provider <- create_observe_h2_backup_connection_provider(backup, directory = destination, h2_jar = jar)
    restored_directory <- attr(provider, "directory")
    observed_connection <- NULL
    tryCatch({
      for (number in 1:2) {
        paths <- db.tools::with_db_connection(provider, function(connection) {
          observed_connection <<- connection
          observe_sql_extract_trip_csv(paste0("trip#", number), connection,
            file.path(directory, paste(gear, number, sep = "-")), gear = gear,
            observe_version = OBSERVE_VERSION_10_0)
        })
        expect_identical(names(paths), names(definitions))
        tables <- lapply(paths, utils::read.csv, check.names = FALSE, colClasses = "character")
        expect_identical(tables[[paste0(gear, "_common.trip")]]$topiaId, paste0("trip#", number))
        expect_identical(tables[[paste0(gear, "_observation.activity")]]$topiaId, paste0("activity#", number))
        expect_identical(tables[[paste0(gear, "_observation.fishingSet")]]$topiaId, paste0("set#", number))
        expect_false(DBI::dbIsValid(observed_connection))
        expect_true(dir.exists(restored_directory))
        for (sheet in names(definitions))
          expect_identical(names(tables[[sheet]]), names(definitions[[sheet]]$fields), info = sheet)
        if (gear == "ll") {
          trip_csv <- paths[["ll_common.trip"]]
          fields <- names(definitions[["ll_common.trip"]]$fields)
          quoted_header <- paste0('"', paste(fields, collapse = '","'), '"\r\n')
          quoted_values <- rep("", length(fields))
          quoted_values[match(c("topiaId", "ersId", "generalComment", "logbookComment"), fields)] <-
            c(paste0('"trip#', number, '"'), '"001"', '""', '"caf\u00e9 ""quote""\nnext"')
          expected <- paste0(quoted_header, paste(quoted_values, collapse = ","), "\r\n")
          expect_identical(readBin(trip_csv, "raw", n = file.size(trip_csv)), charToRaw(enc2utf8(expected)))
        }
        # Reopening must use the restored database even when the backup is no longer available.
        if (number == 1L) unlink(backup)
      }
      empty <- db.tools::with_db_connection(provider, function(connection) {
        observe_sql_extract_trip_csv("trip#missing", connection, file.path(directory, paste0(gear, "-empty")),
          gear = gear)
      })
      for (sheet in names(definitions)) {
        header <- paste0('"', paste(names(definitions[[sheet]]$fields), collapse = '","'), '"\r\n')
        expect_identical(readBin(empty[[sheet]], "raw", n = file.size(empty[[sheet]])), charToRaw(header))
      }
    }, finally = unlink(restored_directory, recursive = TRUE))
  }
})

test_that("unsupported source selections fail before invoking the backend", {
  directory <- file.path(withr::local_tempdir(), "trip")
  for (extract_csv in list(observe_sql_extract_trip_csv, observe_public_api_extract_trip_csv)) {
    expect_error(extract_csv("trip#1", NULL, directory, gear = c(OBSERVE_GEAR_LL, OBSERVE_GEAR_PS)),
      "gear must be a non-empty string")
    expect_error(extract_csv("trip#1", NULL, directory, gear = "trawl"), "gear must be 'll' or 'ps'")
    expect_error(extract_csv("trip#1", NULL, directory, gear = "l"), "gear must be 'll' or 'ps'")
  }
  expect_error(observe_sql_extract_trip_csv("trip#1", NULL, directory, observe_version = "99.0"),
    "No packaged source model")
  expect_error(observe_sql_extract_trip_csv("trip#1", NULL, directory, observe_version = "../10.0"),
    "packaged numeric version")
  expect_false(file.exists(directory))
})
