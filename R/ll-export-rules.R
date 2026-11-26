# Internal helpers ----------------------------------------------------------

#' Count distinct sets linked to a fishing operation
#' @param inputs Extracted sets and activities for one trip.
#' @param context Rule context containing the prepared ObServe references.
#' @param parameters Arguments supplied by the export engine.
#' @return The count of conducted sets.
#' @keywords internal
count_conducted_sets <- function(inputs, context, parameters) {
  activity_types <- context$resources$observe_references[["code_lists/ll_common.vesselactivity/topiaid"]]$data
  if (is.null(activity_types))
    stop("Prepare the ObServe activity catalogue before counting the conducted sets.", call. = FALSE)
  fishing_type_ids <- activity_types$topiaid[activity_types$code %in% "FO"]
  activities <- inputs$activities
  fishing_activity_ids <- activities$topiaId[activities$vesselActivity %in% fishing_type_ids]
  sets <- inputs$sets
  length(unique(sets$topiaId[sets$activity %in% fishing_activity_ids]))
}

#' Reuse the conducted-set count for the observed-set total
#' @param inputs,parameters Arguments supplied by the export engine.
#' @param context Rule context containing the earlier values of the current row.
#' @return The conducted-set count, or an omitted result when the count is missing.
#' @keywords internal
reuse_conducted_set_count <- function(inputs, context, parameters) {
  count <- context$target_row[["observed_trip_summary_number_fishing_sets_conducted"]]
  if (is.null(count))
    stop("Evaluate the conducted-set count before the observed-set count.", call. = FALSE)
  if (is.na(count)) return(list(status = "omitted"))
  count
}

#' Map the recorded ObServe vessel flag to a ROS country code
#' @param inputs ObServe vessel identifier supplied as `value`.
#' @param context Rule context containing the vessel lookup and country mapping.
#' @param parameters Arguments supplied by the export engine.
#' @return The ROS country code or a diagnostic when the flag is unresolved.
#' @keywords internal
resolve_vessel_flag <- function(inputs, context, parameters) {
  vessel <- find_observe_vessel(inputs$value, context$resources$observe_references)
  mapped <- form.references::map_reference_values(context$resources$mapping_references,
    "refs_admin.countries", list(vessel$flagcountry))
  if (identical(mapped$status, "resolved")) return(mapped$target_value)
  list(status = "unresolved", message = "Could not map the ObServe vessel flag to a ROS country code.",
    details = list(mapping_status = mapped$status))
}

#' Choose one ROS Target Species code for the whole trip
#' @param inputs Species identifiers from the ObServe trip.
#' @param context Rule context with prepared export references and groups in its resources.
#' @param parameters Arguments supplied by the export engine.
#' @return One ROS code or a diagnostic for an unresolved species list.
#' @keywords internal
resolve_licensed_targets <- function(inputs, context, parameters) {
  ids <- unique(inputs$species)
  if (!length(ids)) return(list(status = "omitted"))
  groups <- context$resources$licensed_target_groups
  species <- context$resources$observe_references[["code_lists/common.species/topiaid"]]
  if (is.null(groups) || is.null(species))
    stop("Prepare the ObServe species lookup and licensed target groups before exporting licensed target species.",
      call. = FALSE)
  rows <- form.references::reference_match_rows(species, ids)
  unique_match <- lengths(rows) == 1L
  fao_codes <- rep(NA_character_, length(ids))
  fao_codes[unique_match] <- trimws(species$data$faocode[unlist(rows[unique_match], use.names = FALSE)])
  missing <- is.na(fao_codes) | !nzchar(fao_codes)
  codes <- sort(unique(fao_codes[!missing]))
  if (any(missing))
    return(list(status = "unresolved", message = "Some trip species lack a unique FAO code.",
      details = list(fao_codes = codes, unresolved_species = ids[missing])))

  group_size <- lengths(groups$species)
  covers <- vapply(groups$species, function(members) all(codes %in% members), logical(1))
  candidates <- which(covers & group_size == length(codes))
  if (!length(candidates)) {
    allowed <- which(covers & groups$match == "subset")
    if (length(allowed)) candidates <- allowed[group_size[allowed] == min(group_size[allowed])]
  }
  if (length(candidates) == 1L) return(groups$code[[candidates]])
  reason <- if (length(candidates)) "Several ROS Target Species codes match " else "No ROS Target Species code covers "
  list(status = "unresolved", message = paste0(reason, paste(codes, collapse = ", "), "."),
    details = list(fao_codes = codes, candidate_codes = groups$code[candidates]))
}
