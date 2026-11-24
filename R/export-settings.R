# Public operations ---------------------------------------------------------

#' Create the settings for an ObServe export run
#' @param observe_version One of [OBSERVE_VERSIONS].
#' @param ros_form_version One of [ros.form.model::ROS_FORM_VERSIONS].
#' @param gear One of [ros.form.model::ROS_FORMS].
#' @param output_directory Root directory for export files and dated runs.
#' @return An `export_settings` object for use across the export steps.
#' @export
export_settings <- function(observe_version, ros_form_version, gear, output_directory) {
  form.tools::require_nonempty_string(observe_version, "observe_version")
  form.tools::require_nonempty_string(ros_form_version, "ros_form_version")
  form.tools::require_nonempty_string(gear, "gear")
  form.tools::require_nonempty_string(output_directory, "output_directory")
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
  structure(list(observe_version = observe_version, ros_form_version = ros_form_version,
                 gear = gear, output_directory = output_directory), class = "export_settings")
}

#' Locate the files and directories shared by exports using these settings
#' @param export_settings Export settings from [export_settings()].
#' @return A named list of output directories and prepared input paths.
#' @export
export_paths <- function(export_settings) {
  if (!inherits(export_settings, "export_settings")) {
    stop("Create the settings with export_settings().", call. = FALSE)
  }
  gear_directory <- file.path(path.expand(export_settings$output_directory),
                              paste0("observe-", export_settings$observe_version), export_settings$gear)
  target_directory <- file.path(gear_directory, paste0("ros-", export_settings$ros_form_version))
  inputs_directory <- file.path(target_directory, "inputs")
  list(gear_directory = gear_directory,
       target_directory = target_directory,
       inputs_directory = inputs_directory,
       observe_catalogue_directory = file.path(gear_directory, "observe-catalogue"),
       ros_catalogue_directory = file.path(target_directory, "ros-catalogue"),
       observe_form_path = file.path(inputs_directory, "observe-form.yaml"),
       observe_references_path = file.path(inputs_directory, "observe-references.yaml"),
       observe_sql_directory = file.path(inputs_directory, "observe-sql"),
       ros_form_path = file.path(inputs_directory, "ros-form.yaml"),
       ros_references_path = file.path(inputs_directory, "ros-references.yaml"),
       ros_template_path = file.path(inputs_directory, "ros-form-empty.xlsx"),
       mapping_path = file.path(inputs_directory, "mapping.yaml"),
       export_configuration_path = file.path(inputs_directory, "export.yaml"))
}

#' Prepare the input files for an ObServe export
#' @param export_settings Run settings from [export_settings()].
#' @return The absolute path to the prepared input directory.
#' @details ObServe resources and the workbook template come from this package.
#'   The ROS form model and lookup settings come from the installed
#'   `ros.form.model` and `ros.form.references` packages, respectively.
#'   Files are copied into `inputs/` under the ROS target directory on the first call.
#'   Later calls reuse the existing input directory.
#'   The form models, reference settings and export rules are copied alongside each other.
#' @export
prepare_export_inputs <- function(export_settings) {
  paths <- export_paths(export_settings)
  directory <- paths$inputs_directory
  if (dir.exists(directory)) return(normalizePath(directory, winslash = "/", mustWork = TRUE))
  if (file.exists(directory)) stop("Input path already exists: ", directory, call. = FALSE)
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
  observe_model <- form.model::read_form_model(file.path(observe_directory, "form.yaml"))
  observe_tables <- names(form.model::form_sheets(observe_model))
  observe_sql <- paste0(observe_tables, ".sql")
  mapping <- form.references::read_mapping_configuration(file.path(export_directory, "mapping.yaml"))
  correspondence_files <- unique(unlist(lapply(mapping$mappings, function(alternatives) {
    lapply(alternatives, function(alternative) alternative$file)
  }), use.names = FALSE))
  correspondence_paths <- normalizePath(as.character(correspondence_files),
                                        winslash = "/", mustWork = TRUE)
  export_prefix <- paste0(normalizePath(export_directory, winslash = "/", mustWork = TRUE), "/")
  if (any(!startsWith(correspondence_paths, export_prefix))) {
    stop("Correspondence files must be inside the selected export directory.", call. = FALSE)
  }
  active_correspondences <- substring(correspondence_paths, nchar(export_prefix) + 1L)

  ros_model_resource <- file.path("models", ros_form_version, paste0(gear, "-form.yaml"))
  ros_model_path <- form.model::form_resource(ros_model_resource, "ros.form.model")
  ros_reference_namespace <- loadNamespace("ros.form.references")
  ros_lookup_path <- file.path(getNamespaceInfo(ros_reference_namespace, "path"), "references.yaml")
  ros_template_path <- system.file("templates", ros_form_version, gear, "form-empty.xlsx",
                                   package = "ros.form.observe", mustWork = TRUE)
  source_files <- c(
    observe_form_path = file.path(observe_directory, "form.yaml"),
    observe_references_path = file.path(observe_directory, "references.yaml"),
    ros_form_path = ros_model_path,
    ros_references_path = ros_lookup_path,
    ros_template_path = ros_template_path,
    export_configuration_path = file.path(export_directory, "export.yaml"),
    mapping_path = file.path(export_directory, "mapping.yaml")
  )
  prepared_files <- unlist(paths[names(source_files)], use.names = FALSE)
  input_paths <- c(
    stats::setNames(source_files, basename(prepared_files)),
    stats::setNames(file.path(observe_directory, "sql", observe_sql),
                    file.path(basename(paths$observe_sql_directory), observe_sql)),
    stats::setNames(file.path(export_directory, active_correspondences), active_correspondences)
  )
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
  normalizePath(directory, winslash = "/", mustWork = TRUE)
}
