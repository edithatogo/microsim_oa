# Quick Reference Cheat Sheet

## Daily Workflow
1. \git status\ - Check repository status
2. \Rscript scripts/check-quality.R\ - Run quality checks
3. \Rscript run_test.R\ - Run all tests
4. Make your changes with tests
5. \git commit -m "descriptive message"\ - Commit changes
6. \git push\ - Push to trigger CI/CD
7. Monitor GitHub Actions results
8. Address any failing checks

## Essential Commands

### Quality & Testing
\\\ash
# Check code quality
Rscript scripts/check-quality.R

# Run tests
Rscript run_test.R

# Check test coverage
Rscript -e "covr::package_coverage()"

# Lint code
Rscript -e "lintr::lint_package()"

# Auto-fix style
Rscript -e "styler::style_pkg()"
\\\

### Documentation
\\\ash
# Update documentation
Rscript scripts/maintain-docs.R

# Build docs site
Rscript -e "pkgdown::build_site()"

# Preview docs locally
Rscript -e "pkgdown::preview_site()"
\\\

### Performance
\\\ash
# Profile code
Rscript -e "profvis::profvis({ your_code })"

# Check memory
Rscript -e "pryr::mem_used()"

# Benchmark
Rscript -e "bench::mark(your_function())"
\\\

## Health Monitoring

### Check Current Status
- View \output/health_report.md\ for latest health report
- Check GitHub Actions tab for workflow status
- Review \output/baselines/\ for performance baselines

### Alert Response
1. Check alert details in health report
2. Review specific failing metrics
3. Take corrective action
4. Verify fix in next health report

## Key Files & Directories

### Important Files
- \TEAM_TRAINING_GUIDE.md\ - Complete training guide
- \output/health_report.md\ - Current health status
- \scripts/check-quality.R\ - Quality check script
- \un_test.R\ - Test runner script

### Important Directories
- \.github/workflows/\ - All automation workflows
- \output/\ - Generated reports and artifacts
- \docs/\ - Documentation website
- \scripts/\ - Development utility scripts
- \	ests/\ - Test files

## Common Issues & Solutions

### Tests Failing
 Check test output and fix failing tests
 Ensure all dependencies are installed
 Review test data and expectations

### Quality Gate Failing
 Run \Rscript scripts/check-quality.R\
 Fix linting issues with styler
 Address code quality warnings

### Documentation Issues
 Run \Rscript scripts/maintain-docs.R\
 Add missing function documentation
 Update roxygen2 comments

### Performance Issues
 Profile code with profvis
 Check memory usage with pryr
 Optimize bottlenecks

## Emergency Contacts
- **Repository Issues**: Create GitHub issue
- **CI/CD Problems**: Check workflow logs
- **Quality Issues**: Review health reports
- **Urgent Alerts**: Check notification channels

---
*Keep this cheat sheet handy for quick reference!*
