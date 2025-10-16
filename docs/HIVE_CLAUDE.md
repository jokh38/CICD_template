## AI-Powered GitHub Workflow Control System Documentation

### Overview

This system aims to control the entire development workflow using natural language commands through an AI assistant named `claude`. Users can instruct `claude` to perform all processes, including issue creation, code review, testing, building, PR creation, and merging, without directly interacting with GitHub.

### System Architecture

1.  **User**: Gives commands to `claude` in natural language.
2.  **Claude (AI Assistant)**:
    * Interprets user commands and translates them into GitHub actions.
    * Triggers GitHub Actions workflows.
    * Reports the results and logs back to the user.
3.  **GitHub**:
    * Executes workflows triggered by `claude`.
    * Performs tasks such as source code storage, building, testing, and deployment.
    * Returns the results of the actions to `claude`.

### `.github/claude/CLAUDE.md`

The following is an example of a document that `claude` can use to understand and direct the entire workflow.

---

# Claude: An AI-Powered Guide to C++ Development Workflow

This document describes how to manage the entire development lifecycle of a C++ project using the AI assistant `claude`. `claude` enhances development productivity by automating complex tasks such as code review, building, testing, and Pull Request (PR) creation through natural language commands.

## 1. Workflow Overview

This project uses an automated workflow that combines a CI/CD pipeline based on GitHub Actions with the `claude` AI assistant.

* **CI (Continuous Integration)**: Automatically builds and runs tests whenever code is pushed to the `main` branch or a PR is created. (`.github/workflows/ci.yaml`)
* **AI Assistant**: You can invoke `claude` by mentioning `@claude` in an issue, PR, or comment. `claude` provides code analysis, builds, test execution, and a summary of the results. (`.github/workflows/ai-workflow.yaml`)
* **Code Quality**: Automatically performs code styling and static analysis using `clang-format` and `clang-tidy` through `pre-commit` hooks. (`.pre-commit-config.yaml`)

## 2. How to Invoke Claude

You can issue commands to `claude` by including the `@claude` keyword in a GitHub issue, PR, or comment.

**Example:**

> `@claude, please review the code in this PR and run the build and tests.`

## 3. Key Commands and Scenarios

`claude` understands and executes the following natural language commands.

### Scenario 1: New Feature Development

1.  **Requesting Feature Implementation**
    * **User**: `@claude, create an issue to add a user authentication feature and write the corresponding code.`
    * **Claude**:
        1.  Creates a new issue titled `feat: Add user authentication`.
        2.  Creates a new branch (`feature/user-authentication`) to implement the feature.
        3.  Generates and commits boilerplate code for the necessary files (e.g., `src/auth.cpp`, `include/auth.hpp`, `tests/auth_test.cpp`).
        4.  Reports the progress to the user.

2.  **Requesting Code Review and Testing**
    * **User**: `@claude, review the code on the current branch and run the tests.`
    * **Claude**:
        1.  Performs static analysis using `clang-tidy` and `cppcheck`.
        2.  Runs `ctest` to verify that all test cases pass.
        3.  Summarizes the code review comments and test results and reports them to the user.

3.  **Requesting PR Creation and Merging**
    * **User**: `@claude, create a PR with the changes so far and merge it into the `main` branch.`
    * **Claude**:
        1.  Creates a PR from the current branch to the `main` branch.
        2.  Confirms that all checks in the CI workflow have passed.
        3.  If all checks pass, automatically merges the PR into the `main` branch.
        4.  Provides a final report to the user upon completion.

### Scenario 2: Bug Fixing

1.  **Reporting and Requesting a Bug Fix**
    * **User**: `@claude, there's a memory leak when logging in. Create an issue and fix it.`
    * **Claude**:
        1.  Creates an issue titled `fix: Memory leak on login`.
        2.  Creates a `bugfix/login-memory-leak` branch.
        3.  Analyzes the relevant code to identify the cause of the memory leak and proposes a fix.
        4.  Commits the corrected code.

2.  **Verifying and Merging the Fix**
    * **User**: `@claude, test if the fix is correct and merge it into `main`.`
    * **Claude**:
        1.  Adds a test case specifically for the memory leak.
        2.  Runs the full test suite and build.
        3.  After all checks pass, creates a PR and merges it into the `main` branch.
        4.  Automatically closes the issue and reports to the user.

### Command Summary

| Category | Example Command | Claude's Action |
| :--- | :--- | :--- |
| **Issue/Branch** | `@claude, create an issue for [feature]` | Creates an issue, creates a feature branch. |
| | `@claude, make a branch to fix [bug]` | Creates a bugfix branch. |
| **Code Generation** | `@claude, write boilerplate for [class]` | Generates C++ class HPP/CPP files. |
| | `@claude, add a test for [function]` | Adds a GTest-based test case. |
| **Review/Test** | `@claude, review the code` | Performs static analysis, style checks, suggests improvements. |
| | `@claude, build and test the project` | Runs CMake build and CTest. |
| **PR/Merge** | `@claude, create a PR` | Creates a PR from the current branch to `main`. |
| | `@claude, merge when all checks pass` | Auto-merges the PR upon successful CI completion. |

## 4. Principles for Interacting with Claude

* **Clear and Specific Instructions**: Provide clear instructions so that `claude` can understand the task accurately.
* **Break Down Complex Tasks**: It is better to divide complex tasks into several steps and give instructions sequentially.
* **Confirm Results**: Always check the results reported by `claude` (build logs, test results, etc.) before proceeding to the next step.

---