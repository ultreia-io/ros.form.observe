# Internal helpers ----------------------------------------------------------

#' Select the only source record for one output row
#' @param inputs,context,parameters Arguments supplied by the export engine.
#' @return One group containing the only source row.
#' @keywords internal
select_one_row <- function(inputs, context, parameters) {
  if (!is.data.frame(inputs$records) || nrow(inputs$records) != 1L)
    stop("one_row requires exactly one source record.", call. = FALSE)
  list(1L)
}

#' Read a value supplied in the batch YAML
#' @param inputs,context,parameters Arguments supplied by the export engine.
#' @return The input value or an omitted result for a blank optional field.
#' @keywords internal
read_export_input <- function(inputs, context, parameters) {
  value <- inputs$value
  if (is.null(value) || is.na(value)) return(list(status = "omitted"))
  value
}

#' Copy a source value into the target field
#' @param inputs Source value supplied as `value`.
#' @param context,parameters Arguments supplied by the export engine.
#' @return The source value as supplied.
#' @keywords internal
copy_source_value <- function(inputs, context, parameters) {
  inputs$value
}

#' Resolve the provisional identity for the first export pass
#' @param inputs Source identifier supplied by the export engine.
#' @param context Current export rule context.
#' @param parameters Identity key supplied by the declaration.
#' @return The source trip identifier or an unresolved diagnostic for other keys.
#' @keywords internal
resolve_source_identity <- function(inputs, context, parameters) {
  if (identical(parameters[["key"]], "trip")) return(inputs$value)
  list(status = "unresolved", message = "This identity still needs an agreed export rule.")
}

#' Cache an identity under the current target field name
#' @param inputs Source identifier supplied as `value`.
#' @param context Target field and identity cache for the current export run.
#' @param parameters Arguments supplied by the export engine.
#' @return The identifier stored for the target field.
#' @keywords internal
cache_export_identity <- function(inputs, context, parameters) {
  value <- form.tools::require_nonempty_string(inputs$value, context$field)
  cache <- context$identity_cache
  if (!is.environment(cache)) stop("The export run must provide an identity cache.", call. = FALSE)
  existing <- cache[[context$field]]
  if (!is.null(existing) && !identical(existing, value))
    stop("Conflicting cached identity for ", context$field, ".", call. = FALSE)
  cache[[context$field]] <- value
  value
}

#' Read the identity cached for the current target field
#' @param inputs,parameters Arguments supplied by the export engine.
#' @param context Target field and identity cache for the current export run.
#' @return The cached identifier or an unresolved diagnostic.
#' @keywords internal
read_cached_identity <- function(inputs, context, parameters) {
  value <- context$identity_cache[[context$field]]
  if (is.null(value))
    return(list(status = "unresolved", message = paste0("No cached identity for ", context$field, ".")))
  value
}

#' Assemble a full name from the ObServe person record
#' @param inputs ObServe person identifier supplied as `value`.
#' @param context Rule context containing the prepared ObServe person lookup.
#' @param parameters Arguments supplied by the export engine.
#' @return The available name parts, an omitted result for a blank name,
#'   or an unresolved diagnostic when the person lookup fails.
#' @keywords internal
read_observe_person_name <- function(inputs, context, parameters) {
  person <- find_observe_person(inputs$value, context$resources$observe_references)
  if (is.null(person))
    return(list(status = "unresolved", message = "Expected one ObServe person for the trip."))
  name_parts <- trimws(c(person$firstname, person$lastname))
  name_parts <- name_parts[!is.na(name_parts) & nzchar(name_parts)]
  if (!length(name_parts)) return(list(status = "omitted"))
  paste(name_parts, collapse = " ")
}

#' Find an ObServe person by their technical identifier
#' @param person_id Technical identifier recorded on the trip.
#' @param observe_references Prepared ObServe reference lookups.
#' @return One person record or `NULL` when the lookup cannot resolve it.
#' @keywords internal
find_observe_person <- function(person_id, observe_references) {
  people <- observe_references[["registries/common.person/topiaid"]]
  if (is.null(people))
    stop("Prepare the ObServe person lookup before exporting a person.", call. = FALSE)
  rows <- form.references::reference_match_rows(people, person_id)[[1L]]
  if (length(rows) == 1L) people$data[rows, , drop = FALSE] else NULL
}

#' Map the ObServe captain's country for the ROS fishing master
#' @param inputs ObServe captain identifier supplied as `value`.
#' @param context Rule context containing the person lookup and country mapping.
#' @param parameters Arguments supplied by the export engine.
#' @return The ROS country code or a diagnostic when the country is unresolved.
#' @keywords internal
resolve_fishing_master_nationality <- function(inputs, context, parameters) {
  captain <- find_observe_person(inputs$value, context$resources$observe_references)
  mapped <- form.references::map_reference_values(context$resources$mapping_references,
    "refs_admin.countries", list(captain$country))
  if (identical(mapped$status, "resolved")) return(mapped$target_value)
  list(status = "unresolved", message = "Could not map the ObServe captain's country to a ROS country code.",
    details = list(mapping_status = mapped$status))
}

#' Copy a vessel identity field from ObServe
#' @param inputs ObServe vessel identifier supplied as `value`.
#' @param context Rule context containing the ObServe vessel lookup.
#' @param parameters The ObServe vessel property to copy.
#' @return The recorded value, or an omitted value if it cannot be filled.
#' @keywords internal
read_vessel_identity <- function(inputs, context, parameters) {
  vessel <- find_observe_vessel(inputs$value, context$resources$observe_references)
  value <- vessel[[parameters$property]]
  if (is.null(value) || is.na(value) || !nzchar(trimws(value))) return(list(status = "omitted"))
  value
}

#' Find an ObServe vessel by its technical identifier
#' @param vessel_id Technical identifier recorded on the trip.
#' @param observe_references Prepared ObServe reference lookups.
#' @return One vessel record or `NULL` when the lookup cannot resolve it.
#' @keywords internal
find_observe_vessel <- function(vessel_id, observe_references) {
  vessels <- observe_references[["registries/common.vessel/topiaid"]]
  rows <- form.references::reference_match_rows(vessels, vessel_id)[[1L]]
  if (length(rows) == 1L) vessels$data[rows, , drop = FALSE] else NULL
}
