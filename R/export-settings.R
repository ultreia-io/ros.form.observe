# Public operations ---------------------------------------------------------

#' Create the settings for an ObServe export run
#' @param observe_version One of [OBSERVE_VERSIONS].
#' @param ros_form_version One of [ros.form.model::ROS_FORM_VERSIONS].
#' @param gear One of [ros.form.model::ROS_FORMS].
#' @param batch_directory Batch directory containing export-runner.yaml.
#' @return An `export_settings` object for use across the export steps.
#' @export
export_settings <- function(observe_version, ros_form_version, gear, batch_directory) {
  form.tools::require_nonempty_string(observe_version, "observe_version")
  form.tools::require_nonempty_string(ros_form_version, "ros_form_version")
  form.tools::require_nonempty_string(gear, "gear")
  form.tools::require_nonempty_string(batch_directory, "batch_directory")
  if (!observe_version %in% OBSERVE_VERSIONS) {
    stop("observe_version must be one of: ", paste(OBSERVE_VERSIONS, collapse = ", "), call. = FALSE)
  }
  if (!ros_form_version %in% ros.form.model::ROS_FORM_VERSIONS) {
    stop("ros_form_version must be one of: ",
         paste(ros.form.model::ROS_FORM_VERSIONS, collapse = ", "), call. = FALSE)
  }
  if (!gear %in% ros.form.model::ROS_FORMS) {
    stop("gear must be one of: ", paste(ros.form.model::ROS_FORMS, collapse = ", "), call. = FALSE)
  }
  batch_directory <- normalizePath(path.expand(batch_directory), winslash = "/", mustWork = TRUE)
  if (!dir.exists(batch_directory)) stop("batch_directory must be a directory.", call. = FALSE)
  structure(list(observe_version = observe_version, ros_form_version = ros_form_version,
                 gear = gear, batch_directory = batch_directory), class = "export_settings")
}

#' Locate the files and directories shared by exports using these settings
#' @param export_settings Export settings from [export_settings()].
#' @return Named `workspace` and `batch` lists of paths.
#' @export
export_paths <- function(export_settings) {
  if (!inherits(export_settings, "export_settings")) {
    stop("Create the settings with export_settings().", call. = FALSE)
  }
  batch_directory <- export_settings$batch_directory
  workspace_directory <- dirname(batch_directory)
  observe_version <- paste0("observe-", export_settings$observe_version)
  ros_version <- paste0("ros-", export_settings$ros_form_version)
  gear_inputs <- file.path(workspace_directory, "inputs", export_settings$gear)
  observe_inputs <- file.path(gear_inputs, observe_version)
  ros_inputs <- file.path(gear_inputs, ros_version)
  export_inputs <- file.path(observe_inputs, ros_version)
  sources_directory <- file.path(batch_directory, "sources")
  list(
    workspace = list(
      directory = workspace_directory,
      observe_inputs_directory = observe_inputs,
      ros_inputs_directory = ros_inputs,
      export_inputs_directory = export_inputs,
      observe_catalogue_directory = file.path(observe_inputs, "catalogues"),
      ros_catalogue_directory = file.path(ros_inputs, "catalogues"),
      observe_form_path = file.path(observe_inputs, "observe-form.yaml"),
      observe_sql_directory = file.path(observe_inputs, "sql"),
      observe_references_path = file.path(workspace_directory, "observe-references.yaml"),
      ros_references_path = file.path(workspace_directory, "ros-references.yaml"),
      ros_form_path = file.path(ros_inputs, "ros-form.yaml"),
      ros_template_path = file.path(ros_inputs, "ros-form-empty.xlsx"),
      mapping_path = file.path(export_inputs, "mapping.yaml"),
      licensed_targets_path = file.path(export_inputs, "correspondences", "licensed-targets.csv"),
      export_configuration_path = file.path(export_inputs, "export.yaml")
    ),
    batch = list(
      directory = batch_directory,
      runner_path = file.path(batch_directory, "export-runner.yaml"),
      sources_directory = sources_directory,
      trip_ids_path = file.path(sources_directory, "selected-trip-ids.csv"),
      trips_directory = file.path(sources_directory, "trips"),
      output_directory = file.path(batch_directory, "output")
    )
  )
}

#' Prepare the input files for an ObServe export
#' @param export_settings Run settings from [export_settings()].
#' @return The absolute path to the inputs for the selected version pair.
#' @details Shares the ObServe form model and SQL across ROS targets, and the ROS
#'   form model and template across ObServe versions. The mapping, correspondences
#'   and export configuration belong to the selected pair.
#' @export
prepare_export_inputs <- function(export_settings) {
  paths <- export_paths(export_settings)$workspace
  directory <- paths$export_inputs_directory
  if (dir.exists(directory) && dir.exists(paths$ros_inputs_directory)) return(directory)
  if (file.exists(directory) && !dir.exists(directory))
    stop("Input path already exists: ", directory, call. = FALSE)
  observe_version <- export_settings$observe_version
  gear <- export_settings$gear
  ros_form_version <- export_settings$ros_form_version

  export_directory <- system.file(observe_version, gear, ros_form_version,
                                  package = "ros.form.observe")
  if (!nzchar(export_directory) || !file.exists(file.path(export_directory, "export.yaml"))) {
    stop("No export configuration for ObServe ", observe_version, ", gear ", gear,
         " and ROS ", ros_form_version, ".", call. = FALSE)
  }
  observe_directory <- dirname(export_directory)
  if (!dir.exists(paths$observe_inputs_directory)) {
    sql_directory <- file.path(observe_directory, "sql")
    observe_sql <- list.files(sql_directory, pattern = "[.]sql$")
    if (!length(observe_sql)) stop("No queries in ", sql_directory, call. = FALSE)
    observe_files <- c(
      stats::setNames(file.path(observe_directory, "form.yaml"), basename(paths$observe_form_path)),
      stats::setNames(file.path(sql_directory, observe_sql),
                      file.path(basename(paths$observe_sql_directory), observe_sql))
    )
    copy_export_inputs(observe_files, paths$observe_inputs_directory)
  }
  if (!dir.exists(paths$ros_inputs_directory)) {
    ros_model_resource <- file.path("models", ros_form_version, paste0(gear, "-form.yaml"))
    ros_model_path <- form.model::form_resource(ros_model_resource, "ros.form.model")
    ros_template_path <- system.file("templates", ros_form_version, gear, "form-empty.xlsx",
                                     package = "ros.form.observe", mustWork = TRUE)
    ros_files <- stats::setNames(c(ros_model_path, ros_template_path),
      basename(c(paths$ros_form_path, paths$ros_template_path)))
    copy_export_inputs(ros_files, paths$ros_inputs_directory)
  }
  if (dir.exists(directory)) return(directory)

  export_files <- file.path(export_directory, basename(c(paths$export_configuration_path, paths$mapping_path)))
  mapping <- form.references::read_mapping_configuration(file.path(export_directory, "mapping.yaml"))
  correspondence_files <- unique(unlist(lapply(mapping$mappings, function(alternatives) {
    lapply(alternatives, function(alternative) alternative$file)
  }), use.names = FALSE))
  licensed_targets <- file.path(export_directory, "correspondences", basename(paths$licensed_targets_path))
  if (file.exists(licensed_targets)) correspondence_files <- c(correspondence_files, licensed_targets)
  correspondence_paths <- normalizePath(as.character(correspondence_files),
                                        winslash = "/", mustWork = TRUE)
  export_prefix <- paste0(normalizePath(export_directory, winslash = "/", mustWork = TRUE), "/")
  if (any(!startsWith(correspondence_paths, export_prefix))) {
    stop("Correspondence files must be inside the selected export directory.", call. = FALSE)
  }
  active_correspondences <- substring(correspondence_paths, nchar(export_prefix) + 1L)
  copy_export_inputs(c(
    stats::setNames(export_files, basename(export_files)),
    stats::setNames(correspondence_paths, active_correspondences)
  ), directory)
  directory
}

# Internal helpers ----------------------------------------------------------

#' Copy packaged input files into a shared directory
#' @param input_paths Source paths named by their relative destinations.
#' @param directory Destination directory.
#' @return The destination path invisibly.
#' @keywords internal
copy_export_inputs <- function(input_paths, directory) {
  missing_paths <- input_paths[!file.exists(input_paths)]
  if (length(missing_paths)) {
    stop("Missing export input files:\n", paste(missing_paths, collapse = "\n"), call. = FALSE)
  }

  parent_directory <- dirname(directory)
  dir.create(parent_directory, recursive = TRUE, mode = "0700", showWarnings = FALSE)
  staging_directory <- tempfile("export-inputs-", tmpdir = parent_directory)
  if (!dir.create(staging_directory, mode = "0700")) {
    stop("Cannot stage export inputs in: ", parent_directory, call. = FALSE)
  }
  on.exit(unlink(staging_directory, recursive = TRUE))
  targets <- file.path(staging_directory, names(input_paths))
  for (target_directory in unique(dirname(targets))) {
    dir.create(target_directory, recursive = TRUE, showWarnings = FALSE)
  }
  if (!all(file.copy(input_paths, targets))) {
    stop("Cannot copy export inputs to: ", staging_directory, call. = FALSE)
  }
  if (file.exists(directory) || !file.rename(staging_directory, directory)) {
    stop("Cannot save export inputs to: ", directory, call. = FALSE)
  }
  invisible(directory)
}
