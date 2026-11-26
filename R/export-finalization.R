# Public operations ---------------------------------------------------------

#' Finalize the ROS fields for one trip
#' @param export_result Assembled result passed by [form.tools::run_form_export()].
#' @param export_context Prepared context from [prepare_export()].
#' @return The export result with the IOTC observer and vessel IDs filled in
#'   or unresolved diagnostics. The trip ID remains provisional.
#' @details [export_ros_trip()] supplies this function to the export engine.
#'   The finalizer also copies the fishing master's name and nationality to the skipper.
#' @export
finalize_ros_trip <- function(export_result, export_context) {
  sheet <- "O-INFO"
  id_field <- "observer_identification_iotc_id"
  name_field <- "observer_identification_full_name"
  observer_information <- export_result$tables[[sheet]]
  if (!is.data.frame(observer_information) ||
      !all(c(id_field, name_field) %in% names(observer_information)) ||
      nrow(observer_information) > 1L)
    stop("Expected a first-pass export result for one trip with O-INFO observer fields.", call. = FALSE)
  if (!nrow(observer_information)) return(export_result)

  observers <- export_context$ros_references[["registries/ros_meta.observer/full_name"]]
  if (is.null(observers))
    stop("Prepare the ROS observer registry lookup before finalizing a trip.", call. = FALSE)

  resolution <- resolve_iotc_observer_id(observer_information[[name_field]][[1L]], observers)
  export_result <- record_trip_identity(export_result, sheet, id_field, "resolve_iotc_observer_id", resolution)
  export_result <- finalize_vessel_identity(export_result, export_context$ros_references)
  export_result <- copy_fishing_master_to_skipper(export_result)
  export_result$ready_to_write <- !nrow(export_result$diagnostics) && setequal(
    names(export_result$tables), names(form.model::form_sheets(export_context$ros_form_model)))
  export_result
}

# Internal helpers ----------------------------------------------------------

#' Fill one identity field and record its diagnostic
#' @param export_result Export result with the target row.
#' @param sheet,field,rule Target location and rule name.
#' @param resolution Resolved value or an unresolved message and evidence.
#' @return The updated export result.
#' @keywords internal
record_trip_identity <- function(export_result, sheet, field, rule, resolution) {
  export_result$tables[[sheet]][[field]] <- resolution$value
  diagnostics <- export_result$diagnostics
  previous <- which(diagnostics$sheet == sheet & diagnostics$field == field &
    diagnostics$rule == rule)
  if (length(previous)) diagnostics <- diagnostics[-previous, , drop = FALSE]
  if (is.na(resolution$value)) {
    diagnostics <- rbind(diagnostics, data.frame(sheet = sheet, field = field, row = 1L,
      rule = rule, status = "unresolved", message = resolution$message,
      source_keys = I(list(export_result$source_rows[[sheet]][[1L]])),
      details = I(list(resolution$details))))
  }
  export_result$diagnostics <- diagnostics
  export_result
}

#' Resolve the assembled observer name in the ROS registry
#' @param observer_name Name assembled in the first pass.
#' @param observers Prepared ROS observer name lookup.
#' @return A list with the IOTC observer ID or an unresolved message and evidence.
#' @keywords internal
resolve_iotc_observer_id <- function(observer_name, observers) {
  if (is.na(observer_name) || !nzchar(observer_name))
    return(list(value = NA_character_, message = "The observer name is missing for the ROS registry lookup."))
  rows <- form.references::reference_match_rows(observers, observer_name)[[1L]]
  if (length(rows) != 1L)
    return(list(value = NA_character_, message = "Expected one ROS observer registry match for the full name.",
      details = list(matches = length(rows))))
  identifier <- observers$data$iotc_observer_identifier[[rows]]
  if (is.na(identifier) || !nzchar(trimws(identifier)))
    return(list(value = NA_character_, message = "The matching ROS registry record has no IOTC observer ID."))
  list(value = identifier)
}

#' Resolve a missing IOTC vessel number from IMO or IRCS
#' @param export_result Export result with any first-pass vessel information.
#' @param ros_references Prepared ROS reference lookups.
#' @return The export result with the recovered IOTC number or a diagnostic.
#' @keywords internal
finalize_vessel_identity <- function(export_result, ros_references) {
  sheet <- "V-INFO"
  field <- "identification_iotc_number"
  vessel <- export_result$tables[[sheet]]
  if (is.null(vessel) || !nrow(vessel)) return(export_result)
  iotc_id <- vessel[[field]][[1L]]
  if (!is.na(iotc_id) && nzchar(trimws(iotc_id))) return(export_result)

  identifiers <- c(imo_identifier = vessel$identification_imo_number,
    ircs_identifier = vessel$identification_ircs)
  resolution <- list(value = find_iotc_vessel_id(identifiers, ros_references))
  if (is.na(resolution$value))
    resolution$message <- "Could not resolve one IOTC vessel number from IMO or IRCS."
  record_trip_identity(export_result, sheet, field, "finalize_vessel_identity", resolution)
}

#' Find the IOTC vessel number associated with IMO or IRCS
#' @param identifiers Available values named by their ROS lookup columns.
#' @param ros_references Prepared ROS reference lookups.
#' @return The IOTC number if the matches agree, or `NA_character_`.
#' @keywords internal
find_iotc_vessel_id <- function(identifiers, ros_references) {
  identifiers <- identifiers[!is.na(identifiers) & nzchar(trimws(identifiers))]
  candidates <- lapply(names(identifiers), function(column) {
    vessels <- ros_references[[paste0("registries/ros_meta.vessel/", column)]]
    rows <- form.references::reference_match_rows(vessels, identifiers[[column]])[[1L]]
    vessels$data$iotc_vessel_identifier[rows]
  })
  candidates <- candidates[lengths(candidates) > 0L]
  if (!length(candidates)) return(NA_character_)
  agreed <- Reduce(intersect, candidates)
  if (length(agreed) != 1L || is.na(agreed) || !nzchar(trimws(agreed))) return(NA_character_)
  agreed[[1L]]
}

#' Copy the fishing master details to the skipper fields
#' @param export_result Export result with any first-pass V-INFO rows.
#' @return The export result with the skipper name and nationality filled in.
#' @keywords internal
copy_fishing_master_to_skipper <- function(export_result) {
  vessel <- export_result$tables[["V-INFO"]]
  if (is.null(vessel)) return(export_result)
  vessel$personnel_skipper_captain_full_name <- vessel$personnel_fishing_master_full_name
  vessel$personnel_skipper_captain_nationality <- vessel$personnel_fishing_master_nationality
  export_result$tables[["V-INFO"]] <- vessel
  export_result
}
