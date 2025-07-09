# justfile for AUS-OA

# Run the test suite
test:
    @echo "Running tests..."
    Rscript scripts/run_tests.R
