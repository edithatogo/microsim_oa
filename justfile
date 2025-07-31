# justfile for AUS-OA

# Install dependencies
install:
    @echo "Installing dependencies..."
    Rscript -e "renv::restore()"

# Run the test suite
test: install
    @echo "Running tests..."
    Rscript scripts/run_tests.R

# Lint the package
lint: install
    @echo "Linting package..."
    Rscript -e "lintr::lint_package()"

# Build the documentation
docs: install
    @echo "Building documentation..."
    Rscript -e "pkgdown::build_site()"

# Run R CMD check
check: install
    @echo "Running R CMD check..."
    Rscript -e "rcmdcheck::rcmdcheck(args = '--no-manual', error_on = 'warning')"

# Clean the project
clean:
    @echo "Cleaning project..."
    rm -rf *.Rcheck
    rm -rf docs
    rm -f *.tar.gz
