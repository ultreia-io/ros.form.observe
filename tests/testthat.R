library(testthat)
library(ros.form.observe)

# Run the suite when the package contains implementation tests.
if (length(list.files("testthat", pattern = "^test-.*[.]R$")))
  test_check("ros.form.observe")
