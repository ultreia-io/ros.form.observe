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
