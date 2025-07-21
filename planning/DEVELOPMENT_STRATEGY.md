# Development and Debugging Strategy

This document outlines the strategy to be followed during the development of AUS-OA V2 to ensure efficient progress and avoid common blockers.

## 1. Core Principles

The development process will be guided by modern software engineering best practices, adapted for a scientific computing context.

- **Agile and Incremental:** We will follow the project plan's phased and iterative approach. Changes will be small, logical, and committed frequently. This minimizes the risk of large, complex bugs and makes rollbacks easy if needed.
- **Test-Driven Mindset:** New code will be written with testability in mind. Tests will be developed concurrently with features, ensuring that all new logic is immediately verifiable. We will rely heavily on the `testthat` framework.
- **Continuous Integration (CI):** The GitHub Actions CI pipeline is the single source of truth for code quality. All changes must pass the automated checks before being considered complete.

## 2. Strategy for Handling Testing Errors

Getting stuck on a failing test can halt progress. The following process will be used to efficiently debug and resolve test failures:

1.  **Isolate the Failure:** Do not re-run the entire test suite. Use the `testthat` filtering capabilities to run only the specific test that is failing.
2.  **Read the Error Message Carefully:** The error output from `testthat` is informative. It provides the exact location of the failure and often a clear reason. This is the first and most important piece of debugging information.
3.  **Reproduce Locally:** Ensure the error can be reproduced consistently on the local machine. If it only occurs in the CI environment, the issue is likely related to dependencies or the environment itself, which is why the `Dockerfile` and `renv.lock` are critical.
4.  **Use Interactive Debugging:** For non-trivial bugs, insert a `browser()` statement into the test or the function being tested. This will pause execution and open an interactive debugging console, allowing for line-by-line execution and inspection of all variables in the environment.
5.  **Fix and Re-run:** Once a fix is attempted, re-run the single failing test to confirm the fix. Only after it passes should the full test suite be run to check for unintended side effects.

## 3. Strategy for Avoiding and Breaking Loops

Infinite loops are a common problem in simulations. The following safeguards will be used:

1.  **Timeouts on Major Processes:** Any function that executes a long, complex loop (e.g., the main simulation cycle) will be wrapped in a timeout function like `R.utils::withTimeout()`. If the process takes longer than a predefined limit, it will be terminated automatically, preventing the session from hanging.
2.  **Development-time Iteration Caps:** When writing or debugging code with loops, a temporary safety check will be added (e.g., `if (i > 1e6) stop("Iteration limit exceeded")`). This acts as a circuit-breaker for runaway loops during development and can be removed after the logic is confirmed to be stable.
3.  **System Monitoring:** During test runs of the full simulation, system resource usage (CPU and RAM) will be monitored. A process that consumes 100% of a CPU core for an unexpectedly long time is a primary symptom of an infinite loop and can be manually terminated.
4.  **Profiling:** The `profvis` tool, already part of the project plan, can also help identify unexpectedly long-running sections of code that may indicate an inefficient or infinite loop.
