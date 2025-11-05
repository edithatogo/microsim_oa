@echo off
echo 🚀 Starting CRAN Submission Preparation for ausoa v2.2.0
echo ========================================================
echo.

echo 📦 Step 1: Building package...
R.exe -e "devtools::build()" > build_output.txt 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error building package
    type build_output.txt
    exit /b 1
)
echo ✅ Package built successfully
type build_output.txt
echo.

echo 🔍 Step 2: Running R CMD check...
R.exe -e "rcmdcheck::rcmdcheck(path='.', args=c('--as-cran', '--no-manual', '--no-vignettes'), check_dir='cran_check_results')" > check_output.txt 2>&1
if %errorlevel% neq 0 (
    echo ❌ Error during R CMD check
    type check_output.txt
    exit /b 1
)
echo ✅ R CMD check completed
type check_output.txt
echo.

echo 📋 Step 3: Package Information
R.exe -e "desc <- desc::desc(); cat('Package:', desc$get('Package'), '\nVersion:', desc$get('Version'), '\nTitle:', desc$get('Title'), '\nMaintainer:', desc$get('Maintainer'), '\n')" > pkg_info.txt 2>&1
type pkg_info.txt
echo.

echo 🎯 Step 4: CRAN Submission Instructions
echo =====================================
echo 1. Go to: https://cran.r-project.org/submit.html
echo 2. Fill out the submission form with:
echo    - Package source: Select the built .tar.gz file
echo    - Email: dylan.mordaunt@vuw.ac.nz
echo    - Upload cran-comments.md as comments
echo 3. Submit and wait for CRAN response
echo.

echo 📁 Files ready for submission:
echo - Comments file: cran-comments.md
for %%f in (*.tar.gz) do echo - Package file: %%f

echo.
echo ✨ CRAN submission preparation complete!
echo 📧 Check your email for CRAN confirmation and any follow-up requests.
pause
