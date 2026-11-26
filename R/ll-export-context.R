# Internal helpers ----------------------------------------------------------

#' Get the field rules for longline exports
#' @return A named list of longline export callbacks.
#' @keywords internal
get_ll_export_rules <- function() {
  list(
    observer_identification_full_name = resolve_observe_observer_name,
    observed_trip_summary_number_fishing_sets_conducted = count_conducted_sets,
    observed_trip_summary_number_fishing_sets_observed = reuse_conducted_set_count,
    licensed_target_species = resolve_licensed_targets
  )
}

#' Prepare the reference resources used by longline rules
#' @param export_context Context with prepared ObServe and ROS references.
#' @return The context with licensed target groups when the rule uses them.
#' @keywords internal
prepare_ll_export_references <- function(export_context) {
  licensed_targets <- export_context$export_configuration$sheets[["V-INFO"]]$fields[["licensed_target_species"]]
  if (identical(licensed_targets$rule, "licensed_target_species") &&
      identical(licensed_targets$status, "specified")) {
    paths <- export_context$paths$workspace
    target_codes <- export_context$reference_tables$ros$code_lists$data[["refs_fishery_config.target_species"]]$code
    export_context$licensed_target_groups <- read_licensed_target_groups(paths$licensed_targets_path, target_codes)
  }
  export_context
}

#' Read the permitted FAO species for each ROS Target Species code
#' @param path Path to the licensed-target correspondence table.
#' @param target_codes Codes in the selected ROS Target Species catalogue.
#' @return A data frame containing each ROS code, its match mode and its species.
#' @keywords internal
read_licensed_target_groups <- function(path, target_codes) {
  groups <- utils::read.csv(path, colClasses = "character", check.names = FALSE, row.names = NULL)
  if (!identical(names(groups), c("code", "match", "species")) || !nrow(groups) ||
      anyDuplicated(groups$code) || any(!groups$code %in% target_codes) ||
      any(!groups$match %in% c("exact", "subset")) || anyNA(groups$species))
    stop("Invalid licensed-target correspondence table: ", path, call. = FALSE)
  groups$species <- lapply(strsplit(trimws(groups$species), "[[:space:]]+"), unique)
  if (any(lengths(groups$species) == 0L))
    stop("Each licensed-target group must list its FAO species: ", path, call. = FALSE)
  groups
}
