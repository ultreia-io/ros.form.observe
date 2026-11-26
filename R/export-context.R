# Public operations ---------------------------------------------------------

#' Load the inputs shared by trips in an export
#' @param export_settings Export settings from [export_settings()].
#' @return An S3 `export_context` containing the settings, paths, both form
#'   models, the mapping definition, the export configuration and the shared
#'   and gear-specific rules.
#' @details Run [prepare_export_inputs()] first. Use [prepare_export_references()]
#'   to add the catalogue data, lookup indexes and prepared mapping.
#' @export
load_export_context <- function(export_settings) {
  paths <- export_paths(export_settings)
  inputs <- paths$workspace
  export_rules <- get_shared_export_rules()
  if (identical(export_settings$gear, ros.form.model::ROS_FORM_LL))
    export_rules <- c(export_rules, get_ll_export_rules())

  structure(list(
    settings = export_settings,
    paths = paths,
    observe_form_model = form.model::read_form_model(inputs$observe_form_path),
    ros_form_model = form.model::read_form_model(inputs$ros_form_path),
    mapping_definition = form.references::read_mapping_configuration(inputs$mapping_path),
    export_configuration = form.tools::read_form_export(inputs$export_configuration_path),
    export_rules = export_rules
  ), class = "export_context")
}

#' Prepare the references shared by trips in an export
#' @param export_context Context from [load_export_context()].
#' @return The context with the reference configurations, tables, indexes and
#'   prepared mapping added, along with the reference resources for the selected
#'   gear. Pass this context as `resources` to export rules that use the prepared
#'   catalogues or correspondences.
#' @details Uses saved catalogue snapshots when available. Otherwise it retrieves
#'   the required tables and saves them before preparing lookups. Form and mapping
#'   lookups use the same tables in memory. A prepared context can be reused.
#' @export
prepare_export_references <- function(export_context) {
  if (!inherits(export_context, "export_context")) {
    stop("Load the context with load_export_context().", call. = FALSE)
  }
  if (!is.null(export_context$mapping_references)) return(export_context)
  paths <- export_context$paths$workspace
  mapping <- export_context$mapping_definition
  observe_catalogue <- prepare_export_catalogue(export_context$observe_form_model,
    system.file(export_context$settings$observe_version, export_context$settings$gear,
      "references.yaml", package = "ros.form.observe", mustWork = TRUE),
    paths$observe_catalogue_directory, observe_mapping_tables(mapping),
    sources_path = paths$observe_references_path)
  ros_catalogue <- prepare_export_catalogue(export_context$ros_form_model,
    system.file("references.yaml", package = "ros.form.references", mustWork = TRUE),
    paths$ros_catalogue_directory, ros_mapping_tables(mapping),
    sources_path = paths$ros_references_path, optional_sources = TRUE)

  configurations <- list(observe = observe_catalogue$configuration, ros = ros_catalogue$configuration)
  tables <- list(observe = observe_catalogue$tables, ros = ros_catalogue$tables)
  export_context$reference_configurations <- configurations
  export_context$reference_tables <- tables
  export_context$observe_references <- form.references::prepare_model_references(
    export_context$observe_form_model, configurations$observe, catalogues = tables$observe
  )$references
  export_context$ros_references <- form.references::prepare_model_references(
    export_context$ros_form_model, configurations$ros, catalogues = tables$ros
  )$references
  export_context$mapping_references <- form.references::prepare_mapping_references(
    mapping, configurations, catalogues = tables
  )
  if (identical(export_context$settings$gear, ros.form.model::ROS_FORM_LL))
    export_context <- prepare_ll_export_references(export_context)
  export_context
}

# Internal helpers ----------------------------------------------------------

#' Get the rules shared by all export gears
#' @return A named list of shared export callbacks.
#' @keywords internal
get_shared_export_rules <- function() {
  list(
    one_row = select_one_row,
    input = read_export_input,
    copy = copy_source_value,
    identity = resolve_source_identity,
    identity_to_cache = cache_export_identity,
    identity_from_cache = read_cached_identity,
    person_full_name = read_observe_person_name,
    personnel_fishing_master_nationality = resolve_fishing_master_nationality,
    vessel_identity = read_vessel_identity
  )
}
