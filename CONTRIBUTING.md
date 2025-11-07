# Contributing to AUS-OA

We love feedback and contributions! This document outlines the process for contributing to the AUS-OA project.

## Code of Conduct

By participating in this project, you agree to abide by our [Code of Conduct](CODE_OF_CONDUCT.md).

## How to Contribute

### Reporting Bugs

- Use the issue tracker to report bugs
- Describe the issue in detail with a minimal reproducible example
- Include your R version, package version, and platform information
- Check existing issues to avoid duplicates

### Suggesting Features

- Use the issue tracker to propose new features
- Explain the use case clearly
- Describe how the feature would benefit users
- Consider implementation complexity

### Pull Requests

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-oa-feature`)
3. Make your changes following the style guide
4. Add documentation and tests for your changes
5. Ensure all tests pass (`devtools::test()`)
6. Submit the pull request

### Code Style

This package follows the [tidyverse style guide](https://style.tidyverse.org/). Please:

- Use snake_case for functions and variables
- Write clear, concise comments
- Follow existing indentation and spacing
- Document functions with Roxygen
- Include runnable examples in documentation

### Development Workflow

- All changes should have corresponding tests
- Documentation should be updated for new functions
- Follow existing naming conventions
- Maintain backward compatibility when possible
- Write clear commit messages

### Testing

- Write unit tests for all functions
- Ensure code coverage remains high
- Test edge cases and error conditions
- Use `testthat` for testing framework

## Getting Started

1. Clone your fork of the repository:
   ```
   git clone https://github.com/YOUR_USERNAME/microsim_oa.git
   ```

2. Install development dependencies:
   ```r
   devtools::install_dev_deps()
   ```

3. Run the existing tests:
   ```r
   devtools::test()
   ```

Thank you for your interest in improving the AUS-OA package!