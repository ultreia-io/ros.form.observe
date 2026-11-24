# Public operations ---------------------------------------------------------

#' Prepare the catalogue snapshot for ObServe source data
#' @param export_settings Export settings from [export_settings()].
#' @return The absolute path to the ObServe catalogue snapshot.
#' @details Selects the tables required by the ObServe form model and the
#'   source lookups that read catalogue values for the selected mapping.
#'   The prepared reference YAML supplies the catalogue sources.
#'   Reuses an existing snapshot after checking that it has the required tables.
#' @export
prepare_observe_catalogue <- function(export_settings) {
  paths <- export_paths(export_settings)
  mapping <- form.references::read_mapping_configuration(paths$mapping_path)
  model <- form.model::read_form_model(paths$observe_form_path)
  prepare_export_catalogue(
    model,
    paths$observe_references_path,
    paths$observe_catalogue_directory,
    observe_mapping_tables(mapping)
  )$directory
}

#' Prepare the catalogue snapshot for the target ROS version
#' @inheritParams prepare_observe_catalogue
#' @return The absolute path to the ROS catalogue snapshot.
#' @details Selects the tables required by the ROS form model and the target
#'   mapping. The prepared reference YAML supplies the catalogue sources.
#'   Reuses an existing snapshot after verifying its required tables.
#' @export
prepare_ros_catalogue <- function(export_settings) {
  paths <- export_paths(export_settings)
  mapping <- form.references::read_mapping_configuration(paths$mapping_path)
  model <- form.model::read_form_model(paths$ros_form_path)
  prepare_export_catalogue(
    model,
    paths$ros_references_path,
    paths$ros_catalogue_directory,
    ros_mapping_tables(mapping)
  )$directory
}

# Internal helpers ----------------------------------------------------------

#' Find the ObServe tables read by property-based mappings
#' @param mapping Loaded mapping configuration.
#' @return Table IDs grouped by catalogue.
#' @keywords internal
observe_mapping_tables <- function(mapping) {
  tables <- unlist(lapply(mapping$mappings, function(alternatives) {
    lapply(alternatives, function(entry) {
      if (!is.null(entry$source$property)) entry$source$table
    })
  }), use.names = FALSE)
  stats::setNames(list(tables), mapping$catalogues$source$catalogue)
}

#' Find the target tables read by ROS mappings
#' @param mapping Loaded mapping configuration.
#' @return Table IDs grouped by catalogue.
#' @keywords internal
ros_mapping_tables <- function(mapping) {
  stats::setNames(list(names(mapping$mappings)), mapping$catalogues$target$catalogue)
}

#' Save the reference tables selected by a form model and mapping
#' @param model Loaded form model.
#' @param lookup_path Prepared YAML containing the catalogue sources and lookup settings.
#' @param directory Destination for the local catalogue snapshot.
#' @param mapping_tables Additional table IDs grouped by catalogue.
#' @return The snapshot path, its configuration and the verified tables in memory.
#' @keywords internal
prepare_export_catalogue <- function(model, lookup_path, directory, mapping_tables) {
  reuse_snapshot <- dir.exists(directory)
  if (reuse_snapshot) lookup_path <- file.path(directory, "references.yaml")
  configuration <- form.references::read_reference_configuration(lookup_path)
  resolved <- form.references::resolve_reference_lookups(model, configuration)
  lookups <- attr(resolved, "reference_lookups", exact = TRUE)
  model_tables <- vapply(lookups, `[[`, character(1), "table")
  groups <- vapply(lookups, `[[`, character(1), "catalogue")
  required_tables <- split(model_tables, groups)

  for (group in names(mapping_tables)) {
    required_tables[[group]] <- unique(c(required_tables[[group]], mapping_tables[[group]]))
  }

  catalogues <- lapply(names(required_tables), function(group) {
    form.references::get_reference_tables(unique(required_tables[[group]]),
      configuration$catalogues[[group]]$source)
  })
  names(catalogues) <- names(required_tables)
  if (!reuse_snapshot) {
    catalogues <- save_export_catalogues(directory, configuration, catalogues)
  }
  directory <- normalizePath(directory, winslash = "/", mustWork = TRUE)
  for (group in names(catalogues)) {
    group_directory <- file.path(directory, group)
    inventory <- catalogues[[group]]$catalogue
    catalogues[[group]]$paths <- stats::setNames(file.path(group_directory, inventory$csv_path), inventory$id)
    configuration$catalogues[[group]]$source <- form.references::reference_source(group_directory)
  }
  list(directory = directory, configuration = configuration, tables = catalogues)
}

#' Save the verified export catalogues as a portable snapshot
#' @param directory Destination for the local catalogue snapshot.
#' @param configuration Loaded reference configuration.
#' @param catalogues Named list of verified tables grouped by catalogue.
#' @return Verified tables with their saved inventory and publication metadata.
#' @keywords internal
save_export_catalogues <- function(directory, configuration, catalogues) {
  staging_directory <- tempfile("catalogue-", tmpdir = dirname(directory))
  if (!dir.create(staging_directory, mode = "0700")) {
    stop("Cannot stage catalogue: ", directory, call. = FALSE)
  }
  on.exit(unlink(staging_directory, recursive = TRUE), add = TRUE)
  configuration$catalogues <- configuration$catalogues[names(catalogues)]
  for (group in names(catalogues)) {
    catalogues[[group]] <- write_export_catalogue(file.path(staging_directory, group), catalogues[[group]])
    configuration$catalogues[[group]]$source <- list(url = group)
  }
  yaml::write_yaml(unclass(configuration), file.path(staging_directory, "references.yaml"))
  if (file.exists(directory) || !file.rename(staging_directory, directory)) {
    stop("Cannot save catalogue: ", directory, call. = FALSE)
  }
  catalogues
}

#' Write verified tables and their local catalogue inventory
#' @param directory Destination for the catalogue group.
#' @param catalogue Selected tables returned by form.references.
#' @return The catalogue with its saved inventory and publication metadata.
#' @keywords internal
write_export_catalogue <- function(directory, catalogue) {
  inventory <- catalogue$catalogue
  table_rows <- inventory$id != "_aliases_"
  table_paths <- file.path(directory, inventory$csv_path[table_rows])
  for (parent in unique(dirname(table_paths))) {
    dir.create(parent, recursive = TRUE, showWarnings = FALSE)
  }
  if (!all(file.copy(catalogue$paths[inventory$id[table_rows]], table_paths))) {
    stop("Cannot copy catalogue tables to: ", directory, call. = FALSE)
  }
  if (any(!table_rows)) {
    aliases <- utils::read.csv(catalogue$paths[["_aliases_"]], fileEncoding = "UTF-8-BOM",
      colClasses = "character", na.strings = NULL)
    selected_aliases <- aliases[aliases$table %in% inventory$id[table_rows], , drop = FALSE]
    if (nrow(selected_aliases)) {
      alias_path <- file.path(directory, inventory$csv_path[!table_rows])
      dir.create(dirname(alias_path), recursive = TRUE, showWarnings = FALSE)
      utils::write.csv(selected_aliases, alias_path, row.names = FALSE, fileEncoding = "UTF-8")
      inventory$sha256[!table_rows] <- digest::digest(file = alias_path, algo = "sha256")
    } else {
      inventory <- inventory[table_rows, , drop = FALSE]
    }
  }
  manifest <- file.path(directory, "catalogue.csv")
  utils::write.csv(inventory, manifest, row.names = FALSE, fileEncoding = "UTF-8")
  catalogue$catalogue <- inventory
  catalogue$publication$sha256 <- digest::digest(file = manifest, algo = "sha256")
  yaml::write_yaml(catalogue$publication, file.path(directory, "catalogue.yaml"))
  catalogue
}
