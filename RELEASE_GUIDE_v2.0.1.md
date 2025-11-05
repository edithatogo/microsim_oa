# AUS-OA Release Guide v2.0.1

## 📦 Release Overview

This guide covers the release process for AUS-OA v2.0.1, a minor release that adds comprehensive dataset documentation and research support features.

## 🎯 Release Summary

**Version**: 2.0.1 (Minor Release)
**Date**: September 10, 2025
**Type**: Documentation and Research Enhancement Release

### Key Changes
- ✅ Comprehensive dataset documentation (50+ public OA datasets)
- ✅ Enhanced features matrix and documentation
- ✅ Improved research support and citation features
- ✅ Updated maintainer information
- ✅ Enhanced README and package metadata

## 🚀 GitHub Release Process

### Step 1: Push Changes to GitHub
```bash
# If you have authentication issues, you may need to:
# 1. Set up SSH keys or personal access token
# 2. Or push manually through GitHub Desktop/GitKraken

git push origin main
git push origin v2.0.1
```

### Step 2: Create GitHub Release
1. Go to: https://github.com/edithatogo/microsim_oa/releases
2. Click "Create a new release"
3. **Tag version**: `v2.0.1`
4. **Release title**: `AUS-OA v2.0.1 - Dataset Documentation & Research Enhancement`
5. **Release description**:

```markdown
## 🎉 AUS-OA v2.0.1 Release

### New Features
- **📚 Comprehensive Dataset Documentation**: Added extensive documentation for 50+ public OA datasets
- **📋 Enhanced Features Matrix**: Updated with comprehensive feature documentation
- **🔗 External Data Integration**: Improved support for integrating public OA datasets
- **📖 Research Support**: Enhanced documentation and citation support for academic research

### Documentation Improvements
- Updated README.md with dataset documentation references
- Enhanced features matrix to reflect current capabilities
- Improved package citation and attribution information
- Added comprehensive research support documentation

### Package Maintenance
- Updated maintainer information to Dylan Mordaunt (dylan.mordaunt@vuw.ac.nz)
- Improved package metadata and citation format
- Enhanced research attribution and citation support

### Files Changed
- `DESCRIPTION`: Version bump to 2.0.1
- `NEWS.md`: Updated release notes
- `README.md`: Enhanced with dataset documentation
- `docs/`: Added 5 new documentation files
- `CRAN_READINESS.md`: Updated for v2.0.1
- `cran-comments.md`: Updated submission comments

### Installation
```r
# Install from GitHub
remotes::install_github("edithatogo/microsim_oa@v2.0.1")

# Or from CRAN (once approved)
install.packages("ausoa")
```

### Links
- 📖 [Full Documentation](https://edithatogo.github.io/microsim_oa/)
- 📚 [Dataset Documentation](https://github.com/edithatogo/microsim_oa/blob/main/docs/DATASET_DOCUMENTATION_OVERVIEW.md)
- 🐛 [Issue Tracker](https://github.com/edithatogo/microsim_oa/issues)
```

6. **Set as latest release**: ✅ Yes
7. **Publish release**: Click "Publish release"

## 📋 CRAN Submission Process

### Step 1: Build Package
```bash
# Run the build script
Rscript build_package.R

# Or build manually
R CMD build .
R CMD check ausoa_2.0.1.tar.gz
```

### Step 2: Test Package
```bash
# Test installation
R CMD INSTALL ausoa_2.0.1.tar.gz

# Test basic functionality
R -e "library(ausoa); help(package='ausoa')"
```

### Step 3: Submit to CRAN
1. Go to: https://cran.r-project.org/submit.html
2. **Package**: Upload `ausoa_2.0.1.tar.gz`
3. **Comments**: Upload `cran-comments.md`
4. **Submitter Email**: dylan.mordaunt@vuw.ac.nz
5. **Submit**

### Step 4: Monitor Submission
- **CRAN Response Time**: Typically 1-2 weeks
- **Email Notifications**: Monitor for feedback
- **Common Issues**: Address any NOTES/WARNINGs promptly

## 📊 Release Checklist

### Pre-Release ✅
- [x] Version bumped to 2.0.1
- [x] NEWS.md updated with changes
- [x] All tests passing
- [x] Documentation updated
- [x] CRAN readiness verified

### GitHub Release ✅
- [x] Changes committed and tagged
- [ ] Push to GitHub repository
- [ ] Create GitHub release with description
- [ ] Verify release appears on GitHub

### CRAN Submission ⏳
- [ ] Package built successfully
- [ ] R CMD check passes
- [ ] Package installs correctly
- [ ] Submit to CRAN
- [ ] Monitor for approval/rejection

### Post-Release ⏳
- [ ] Update pkgdown site if needed
- [ ] Announce release on relevant forums
- [ ] Update any dependent documentation
- [ ] Monitor for user feedback/issues

## 🔧 Troubleshooting

### GitHub Authentication Issues
```bash
# Option 1: Use personal access token
git remote set-url origin https://YOUR_USERNAME:YOUR_TOKEN@github.com/edithatogo/microsim_oa.git

# Option 2: Use SSH (if configured)
git remote set-url origin git@github.com:edithatogo/microsim_oa.git
```

### CRAN Check Issues
```bash
# Run detailed check
R CMD check --as-cran ausoa_2.0.1.tar.gz

# Check specific issues
R CMD check --no-manual --no-vignettes ausoa_2.0.1.tar.gz
```

### Package Build Issues
```bash
# Clean build
rm -rf ausoa.Rcheck/
R CMD build --no-build-vignettes .

# Force rebuild documentation
R -e "devtools::document(); devtools::build()"
```

## 📞 Support

### For Release Issues
- **GitHub Issues**: https://github.com/edithatogo/microsim_oa/issues
- **CRAN Maintainers**: cran-submissions@r-project.org
- **Package Author**: dylan.mordaunt@vuw.ac.nz

### Documentation
- **Package Docs**: https://edithatogo.github.io/microsim_oa/
- **CRAN Policies**: https://cran.r-project.org/web/packages/policies.html
- **R Package Development**: https://r-pkgs.org/

---

## 🎉 Release Complete!

Once both GitHub and CRAN releases are complete, AUS-OA v2.0.1 will be available to the R community with enhanced dataset documentation and research support capabilities.
