test_that("LL and PS query results match their model columns on H2", {
  skip_if_not_installed("RJDBC")
  jar <- Sys.getenv("H2_JAR")
  skip_if(!nzchar(jar) || !file.exists(jar), "Set H2_JAR to the ObServe H2 driver jar")
  driver <- RJDBC::JDBC("org.h2.Driver", jar, identifier.quote = '"')
  for (gear in c("ll", "ps")) {
    connection <- DBI::dbConnect(driver, paste0("jdbc:h2:mem:", basename(tempfile("observe-")),
      ";DATABASE_TO_LOWER=TRUE"), "sa", "")
    tryCatch({
      resources <- system.file("10.0", gear, package = "ros.form.observe", mustWork = TRUE)
      model <- form.model::read_form_model(file.path(resources, "form.yaml"))
      definitions <- form.model::form_sheets(model)
      schemas <- unique(sub("[.].*$", "", names(definitions)))
      for (schema in schemas) RJDBC::dbSendUpdate(connection, paste("CREATE SCHEMA", schema))
      for (sheet in names(definitions)) {
        columns <- paste0('"', tolower(names(definitions[[sheet]]$fields)), '" VARCHAR')
        RJDBC::dbSendUpdate(connection, paste0("CREATE TABLE ", sheet, " (", paste(columns, collapse = ", "), ")"))
      }
      root <- paste0(gear, "_common.trip")
      RJDBC::dbSendUpdate(connection, paste0("INSERT INTO ", root, " (topiaId) VALUES (?)"), "trip#test")
      tables <- form.tools::read_form_tables(model, file.path(resources, "sql"),
        form.tools::sql_table_loader(connection), list("trip#test"))
      expect_identical(names(tables), names(definitions))
      expect_identical(tables[[root]]$topiaId, "trip#test")
      expect_true(all(vapply(tables[setdiff(names(tables), root)], nrow, integer(1)) == 0L))
      for (sheet in names(definitions)) {
        expect_identical(names(tables[[sheet]]), names(definitions[[sheet]]$fields), info = sheet)
      }
    }, finally = DBI::dbDisconnect(connection))
  }
})
