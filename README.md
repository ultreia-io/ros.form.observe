# ros.form.observe

Trip extraction saves one CSV per source table through a database connection or the ObServe public API.

See `vignettes/source-loading.Rmd` for YAML configuration, session credentials and one-trip examples.

[![Build](https://img.shields.io/github/actions/workflow/status/ultreia-io/ros.form.observe/Build.yaml?branch=develop&label=Build&logo=githubactions&logoColor=white)](https://github.com/ultreia-io/ros.form.observe/actions/workflows/Build.yaml?query=branch%3Adevelop)
[![Website](https://img.shields.io/badge/website-documentation-blue?logo=readthedocs&logoColor=white)](https://ultreia-io.github.io/ros.form.observe/index.html)
[![License](https://img.shields.io/badge/license-GPL--3-blue?logo=gnu&logoColor=white)](https://github.com/ultreia-io/ros.form.observe/blob/main/LICENSE)

[![Latest release](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fapi.github.com%2Frepos%2Fultreia-io%2Fros.form.observe%2Freleases%2Flatest&query=%24.tag_name&label=Latest%20release&color=blue&logo=github&logoColor=white)](https://github.com/ultreia-io/ros.form.observe/releases/latest)
![CRAN release](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fcrandb.r-pkg.org%2Fros.form.observe&query=%24.Version&label=CRAN%20release&color=brightgreen&logo=r&logoColor=white)

[![Coverage develop](https://img.shields.io/codecov/c/github/ultreia-io/ros.form.observe/develop?label=coverage%20develop&logo=codecov)](https://app.codecov.io/gh/ultreia-io/ros.form.observe/tree/develop)
[![Coverage main](https://img.shields.io/codecov/c/github/ultreia-io/ros.form.observe/main?label=coverage%20main&logo=codecov)](https://app.codecov.io/gh/ultreia-io/ros.form.observe/tree/main)

## About this project

> `ros.form.observe` populates ROS forms from ObServe data.

Read the [Terminology](https://ultreia-io.github.io/ros.form.observe/articles/terminology.html) for the concepts used here.

A ROS form is an Excel workbook used to report observations from fishing trips.

ObServe records the source observations. This package connects those records to the fields of the selected ROS form.

The design separates shared export operations from the mappings specific to longline and purse-seine forms.

## Related packages

* [ros.form.model](https://github.com/ultreia-io/ros.form.model) supplies versioned ROS form definitions.
* [ros.form.references](https://github.com/ultreia-io/ros.form.references) supplies reference catalogues and lookups.
* [form.tools](https://github.com/ultreia-io/form.tools) populates Excel form templates.
* [ros.form.validation](https://github.com/ultreia-io/ros.form.validation) validates populated ROS forms.

## Installation

Install the latest version available on CRAN:

```r
# Install ros.form.observe from CRAN.
install.packages("ros.form.observe")
```

Alternatively, install the latest GitHub release:

```r
# Install the package installation tool.
install.packages("pak")
# Install the latest GitHub release and its dependencies.
pak::pak("ultreia-io/ros.form.observe@*release")
```

For the development version:

```r
# Install the development version and its dependencies.
pak::pak("ultreia-io/ros.form.observe@develop")
```

## Getting started

Follow the [Getting started guide](https://ultreia-io.github.io/ros.form.observe/articles/ros.form.observe.html)
to understand the export scope and the role of the related packages.

## Load source data

Use `create_observe_h2_backup_connection_provider()` to open connections from an ObServe `.sql.gz` backup.

Use `observe_sql_extract_trip_csv()` with a DBI connection.

Use `observe_public_api_extract_trip_csv()` with an ObServe public API session.

The [trip-loading guide][source-loading] covers backups, existing databases and the public API.

[source-loading]: https://ultreia-io.github.io/ros.form.observe/articles/source-loading.html

## Further information

* [Function reference](https://ultreia-io.github.io/ros.form.observe/reference/index.html).
* [Contributing](https://ultreia-io.github.io/ros.form.observe/CONTRIBUTING.html).
* [Maintainer guide](https://ultreia-io.github.io/ros.form.observe/DEVELOPMENT.html).
