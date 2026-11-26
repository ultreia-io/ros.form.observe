# Public operations ---------------------------------------------------------

#' Finalize the ROS fields for one trip
#' @param export_result Assembled result passed by [form.tools::run_form_export()].
#' @param export_context Prepared context from [prepare_export()].
#' @return The export result with the IOTC observer ID filled in or an
#'   unresolved diagnostic. The trip ID remains provisional.
#' @details [export_ros_trip()] supplies this function to the export engine.
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
  export_result$tables[[sheet]][[id_field]] <- resolution$value
  diagnostics <- export_result$diagnostics
  rule <- "resolve_iotc_observer_id"
  previous <- which(diagnostics$sheet == sheet & diagnostics$field == id_field &
    diagnostics$rule == rule)
  if (length(previous)) diagnostics <- diagnostics[-previous, , drop = FALSE]
  if (is.na(resolution$value)) {
    diagnostics <- rbind(diagnostics, data.frame(sheet = sheet, field = id_field, row = 1L,
      rule = rule, status = "unresolved", message = resolution$message,
      source_keys = I(list(export_result$source_rows[[sheet]][[1L]])),
      details = I(list(resolution$details))))
  }
  export_result$diagnostics <- diagnostics
  export_result$ready_to_write <- !nrow(diagnostics) && setequal(
    names(export_result$tables), names(form.model::form_sheets(export_context$ros_form_model)))
  export_result
}

# Internal helpers ----------------------------------------------------------

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
