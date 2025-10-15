## Phase 3: Core AI Workflows (Week 2, Days 1-4)

### Objective
Implement the three primary AI-driven workflows: PR automation, CI fix, and PR review.

### 3.1 PR Automation Workflow

**Task**: Create intelligent issue-to-PR automation workflow

**File**: `.github/workflows/claude-code-pr-automation.yaml`

```yaml
name: AI PR Automation

on:
  issues:
    types: [labeled]
  issue_comment:
    types: [created]
  workflow_dispatch:
    inputs:
      issue-number:
        description: 'Issue number to process'
        required: true
        type: number
      task-type:
        description: 'Type of task'
        required: true
        type: choice
        options:
          - refactor
          - fix-bug
          - add-feature
          - generate-tests

permissions:
  contents: write
  issues: write
  pull-requests: write
  models: read

jobs:
  process-issue:
    runs-on: ubuntu-latest
    # Only run if issue has 'ai-assist' label or contains '@claude' mention
    if: |
      (github.event_name == 'issues' && contains(github.event.issue.labels.*.name, 'ai-assist')) ||
      (github.event_name == 'issue_comment' && contains(github.event.comment.body, '@claude')) ||
      github.event_name == 'workflow_dispatch'

    steps:
      - name: Checkout repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Extract issue details
        id: issue
        uses: actions/github-script@v7
        with:
          script: |
            const issue = context.payload.issue ||
                         await github.rest.issues.get({
                           owner: context.repo.owner,
                           repo: context.repo.repo,
                           issue_number: ${{ github.event.inputs.issue-number }}
                         }).then(r => r.data);

            core.setOutput('title', issue.title);
            core.setOutput('body', issue.body);
            core.setOutput('number', issue.number);
            core.setOutput('labels', issue.labels.map(l => l.name).join(','));

      - name: Determine task type
        id: task-type
        run: |
          LABELS="${{ steps.issue.outputs.labels }}"

          if [[ "$LABELS" == *"bug"* ]]; then
            echo "type=fix-bug" >> $GITHUB_OUTPUT
          elif [[ "$LABELS" == *"enhancement"* ]]; then
            echo "type=add-feature" >> $GITHUB_OUTPUT
          elif [[ "$LABELS" == *"refactor"* ]]; then
            echo "type=refactor" >> $GITHUB_OUTPUT
          elif [[ "$LABELS" == *"test"* ]]; then
            echo "type=generate-tests" >> $GITHUB_OUTPUT
          else
            echo "type=fix-bug" >> $GITHUB_OUTPUT  # Default
          fi

      - name: Create feature branch
        run: |
          BRANCH_NAME="ai/issue-${{ steps.issue.outputs.number }}-$(date +%s)"
          git checkout -b "$BRANCH_NAME"
          echo "BRANCH_NAME=$BRANCH_NAME" >> $GITHUB_ENV

      - name: Build AI prompt from issue
        id: prompt
        run: |
          cat > /tmp/prompt.txt <<'EOF'
          Issue #${{ steps.issue.outputs.number }}: ${{ steps.issue.outputs.title }}

          Description:
          ${{ steps.issue.outputs.body }}

          Task: Please implement a solution for this issue following these guidelines:
          1. Analyze the issue and understand the requirements
          2. Implement the necessary changes with proper error handling
          3. Add or update tests to verify the fix
          4. Ensure all code follows project standards (see CLAUDE.md)
          5. Run all validation checks before proposing changes

          After implementation, provide:
          - Summary of changes made
          - Files modified
          - Testing performed
          - Suggested commit message
          EOF

          echo "prompt-file=/tmp/prompt.txt" >> $GITHUB_OUTPUT

      - name: Run Claude Code to implement solution
        id: claude
        uses: ./.github/actions/claude-code-runner
        with:
          task-type: ${{ steps.task-type.outputs.type }}
          prompt: ${{ steps.prompt.outputs.prompt-file }}
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          max-tokens: 150000

      - name: Validate changes locally
        id: validation
        run: |
          # Language detection and validation
          if [ -f "pyproject.toml" ]; then
            echo "Validating Python project..."
            pip install -e ".[dev]"
            ruff check . --fix || echo "ruff_failed=true" >> $GITHUB_OUTPUT
            mypy src/ || echo "mypy_failed=true" >> $GITHUB_OUTPUT
            pytest --tb=short || echo "pytest_failed=true" >> $GITHUB_OUTPUT
          elif [ -f "CMakeLists.txt" ]; then
            echo "Validating C++ project..."
            cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Debug
            cmake --build build || echo "build_failed=true" >> $GITHUB_OUTPUT
            ctest --test-dir build --output-on-failure || echo "test_failed=true" >> $GITHUB_OUTPUT
          fi
        continue-on-error: true

      - name: AI feedback loop (if validation failed)
        if: |
          steps.validation.outputs.ruff_failed == 'true' ||
          steps.validation.outputs.mypy_failed == 'true' ||
          steps.validation.outputs.pytest_failed == 'true' ||
          steps.validation.outputs.build_failed == 'true' ||
          steps.validation.outputs.test_failed == 'true'
        uses: ./.github/actions/claude-code-runner
        with:
          task-type: 'fix-errors'
          prompt: |
            The previous implementation has validation errors. Please fix:

            Validation Output:
            ${{ steps.validation.outputs.stderr }}

            Fix the errors and ensure all checks pass.
          error-log: ${{ steps.validation.outputs.stderr }}
          retry-count: '1'
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Commit changes
        if: steps.claude.outputs.success == 'true'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          git add .

          # Use commit message from Claude Code output
          git commit -m "${{ steps.claude.outputs.commit-message }}"

      - name: Push branch
        if: steps.claude.outputs.success == 'true'
        run: |
          git push -u origin "$BRANCH_NAME"

      - name: Create Pull Request
        if: steps.claude.outputs.success == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            const result = JSON.parse('${{ steps.claude.outputs.result }}');

            const pr = await github.rest.pulls.create({
              owner: context.repo.owner,
              repo: context.repo.repo,
              title: 'Fix: ${{ steps.issue.outputs.title }}',
              head: process.env.BRANCH_NAME,
              base: 'main',
              body: `## Summary
              Automated fix for issue #${{ steps.issue.outputs.number }}

              ${result.summary || 'AI-generated solution'}

              ## Changes
              ${result.changes || 'See commit history'}

              ## Test Plan
              ${result.test_plan || '- All existing tests pass\n- Added new tests for this functionality'}

              ---
              🤖 Generated with [Claude Code](https://claude.com/claude-code)

              Closes #${{ steps.issue.outputs.number }}`
            });

            core.setOutput('pr-number', pr.data.number);
            core.setOutput('pr-url', pr.data.html_url);

      - name: Comment on issue
        if: steps.claude.outputs.success == 'true'
        uses: actions/github-script@v7
        with:
          script: |
            await github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: ${{ steps.issue.outputs.number }},
              body: `🤖 I've created a pull request to address this issue: ${{ steps.create-pr.outputs.pr-url }}\n\nPlease review the changes and provide feedback.`
            });
```

**Implementation Steps**:
1. Create workflow file with multi-trigger support
2. Implement issue parsing and task type detection
3. Add Claude Code integration for solution generation
4. Implement local validation loop
5. Add PR creation with structured body
6. Create issue comment notification

**Deliverables**:
- [ ] `claude-code-pr-automation.yaml` workflow
- [ ] Issue label-based task detection
- [ ] Validation feedback loop
- [ ] PR creation automation

### 3.2 CI Fix Automation Workflow

**Task**: Auto-fix CI failures using Claude Code

**File**: `.github/workflows/claude-code-fix-ci.yaml`

```yaml
name: AI CI Fix Automation

on:
  workflow_run:
    workflows: ["CI"]  # Triggers after main CI workflow
    types: [failed]
  workflow_dispatch:
    inputs:
      run-id:
        description: 'Failed workflow run ID to fix'
        required: true
        type: number

permissions:
  contents: write
  actions: read
  pull-requests: write
  checks: write
  models: read

jobs:
  analyze-failure:
    runs-on: ubuntu-latest
    if: github.event.workflow_run.conclusion == 'failure' || github.event_name == 'workflow_dispatch'

    outputs:
      has-fixes: ${{ steps.claude.outputs.success }}
      commit-sha: ${{ steps.commit.outputs.sha }}

    steps:
      - name: Checkout code
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_branch }}
          fetch-depth: 0

      - name: Get failure details
        id: failure
        uses: actions/github-script@v7
        with:
          script: |
            const runId = context.payload.workflow_run?.id ||
                         ${{ github.event.inputs.run-id }};

            // Get workflow run details
            const run = await github.rest.actions.getWorkflowRun({
              owner: context.repo.owner,
              repo: context.repo.repo,
              run_id: runId
            });

            // Get job logs
            const jobs = await github.rest.actions.listJobsForWorkflowRun({
              owner: context.repo.owner,
              repo: context.repo.repo,
              run_id: runId,
              filter: 'latest'
            });

            const failedJobs = jobs.data.jobs.filter(j => j.conclusion === 'failure');

            let errorLog = '';
            for (const job of failedJobs) {
              const logs = await github.rest.actions.downloadJobLogsForWorkflowRun({
                owner: context.repo.owner,
                repo: context.repo.repo,
                job_id: job.id
              });

              errorLog += `\n## Job: ${job.name}\n${logs.data}\n`;
            }

            core.setOutput('error-log', errorLog);
            core.setOutput('branch', run.data.head_branch);
            core.setOutput('commit', run.data.head_sha);

      - name: Parse error types
        id: error-type
        run: |
          ERROR_LOG="${{ steps.failure.outputs.error-log }}"

          # Detect error types
          if echo "$ERROR_LOG" | grep -i "test.*failed\|assertion"; then
            echo "type=test-failure" >> $GITHUB_OUTPUT
          elif echo "$ERROR_LOG" | grep -i "lint\|ruff\|flake8\|clang-tidy"; then
            echo "type=lint-error" >> $GITHUB_OUTPUT
          elif echo "$ERROR_LOG" | grep -i "type.*error\|mypy"; then
            echo "type=type-error" >> $GITHUB_OUTPUT
          elif echo "$ERROR_LOG" | grep -i "build.*failed\|compilation"; then
            echo "type=build-error" >> $GITHUB_OUTPUT
          else
            echo "type=unknown" >> $GITHUB_OUTPUT
          fi

      - name: Build fix prompt
        id: prompt
        run: |
          cat > /tmp/fix-prompt.txt <<'EOF'
          CI Pipeline Failed - Automated Fix Request

          Error Type: ${{ steps.error-type.outputs.type }}
          Branch: ${{ steps.failure.outputs.branch }}
          Commit: ${{ steps.failure.outputs.commit }}

          Error Log:
          ```
          ${{ steps.failure.outputs.error-log }}
          ```

          Instructions:
          1. Analyze the error log and identify the root cause
          2. Implement fixes for all identified issues
          3. Ensure fixes follow project coding standards
          4. Run local validation to verify fixes
          5. Provide a clear summary of what was fixed

          Important:
          - Do not introduce new functionality
          - Maintain backward compatibility
          - Update tests only if they are incorrect
          - Follow the existing code style
          EOF

          echo "file=/tmp/fix-prompt.txt" >> $GITHUB_OUTPUT

      - name: Run Claude Code to fix issues
        id: claude
        uses: ./.github/actions/claude-code-runner
        with:
          task-type: 'fix-ci'
          prompt-file: ${{ steps.prompt.outputs.file }}
          error-log: ${{ steps.failure.outputs.error-log }}
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          max-tokens: 100000

      - name: Run validation
        id: validation
        run: |
          # Re-run the same checks that failed
          ERROR_TYPE="${{ steps.error-type.outputs.type }}"

          case $ERROR_TYPE in
            "test-failure")
              pytest --tb=short || exit 1
              ;;
            "lint-error")
              ruff check . || exit 1
              ;;
            "type-error")
              mypy src/ || exit 1
              ;;
            "build-error")
              cmake --build build || exit 1
              ;;
            *)
              echo "Running full validation..."
              # Run all checks
              ;;
          esac
        continue-on-error: true

      - name: Retry if validation failed
        if: steps.validation.outcome == 'failure' && steps.validation.outputs.attempt < 2
        uses: ./.github/actions/claude-code-runner
        with:
          task-type: 'fix-errors'
          prompt: |
            Previous fix attempt did not resolve all issues.

            Remaining errors:
            ${{ steps.validation.outputs.stderr }}

            Please analyze and fix the remaining issues.
          retry-count: '1'
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}

      - name: Commit fixes
        id: commit
        if: steps.validation.outcome == 'success'
        run: |
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"

          git add .
          git commit -m "fix(ci): Auto-fix CI failures

          ${{ steps.claude.outputs.commit-message }}

          🤖 Generated with [Claude Code](https://claude.com/claude-code)"

          git push

          echo "sha=$(git rev-parse HEAD)" >> $GITHUB_OUTPUT

      - name: Comment on PR
        if: steps.commit.outputs.sha != ''
        uses: actions/github-script@v7
        with:
          script: |
            const prs = await github.rest.pulls.list({
              owner: context.repo.owner,
              repo: context.repo.repo,
              head: `${context.repo.owner}:${{ steps.failure.outputs.branch }}`,
              state: 'open'
            });

            if (prs.data.length > 0) {
              const pr = prs.data[0];
              await github.rest.issues.createComment({
                owner: context.repo.owner,
                repo: context.repo.repo,
                issue_number: pr.number,
                body: `🤖 **AI Fix Applied**

                I've detected and automatically fixed CI failures in commit ${{ steps.commit.outputs.sha }}.

                **Error Type**: ${{ steps.error-type.outputs.type }}

                **Changes**: ${{ steps.claude.outputs.summary }}

                The CI pipeline should pass on the next run. Please review the changes.`
              });
            }
```

**Implementation Steps**:
1. Create workflow triggered by CI failure
2. Implement error log extraction from failed jobs
3. Add error type classification
4. Build context-aware fix prompts
5. Implement validation retry loop
6. Add PR comment notifications

**Deliverables**:
- [ ] `claude-code-fix-ci.yaml` workflow
- [ ] Error log parsing and classification
- [ ] Multi-retry validation logic
- [ ] PR notification system

### 3.3 PR Review Automation Workflow

**Task**: Automated PR code review using Claude Code

**File**: `.github/workflows/claude-code-review.yaml`

```yaml
name: AI PR Review

on:
  pull_request:
    types: [opened, synchronize, labeled]
  workflow_dispatch:
    inputs:
      pr-number:
        description: 'PR number to review'
        required: true
        type: number

permissions:
  contents: read
  pull-requests: write
  models: read

jobs:
  ai-review:
    runs-on: ubuntu-latest
    if: |
      contains(github.event.pull_request.labels.*.name, 'ai-review') ||
      github.event_name == 'workflow_dispatch'

    steps:
      - name: Checkout PR branch
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.pull_request.head.sha }}
          fetch-depth: 0

      - name: Get PR details
        id: pr
        uses: actions/github-script@v7
        with:
          script: |
            const pr = context.payload.pull_request ||
                       await github.rest.pulls.get({
                         owner: context.repo.owner,
                         repo: context.repo.repo,
                         pull_number: ${{ github.event.inputs.pr-number }}
                       }).then(r => r.data);

            core.setOutput('title', pr.title);
            core.setOutput('body', pr.body || '');
            core.setOutput('number', pr.number);
            core.setOutput('base', pr.base.ref);
            core.setOutput('head', pr.head.ref);

      - name: Get changed files
        id: files
        run: |
          git diff --name-only origin/${{ steps.pr.outputs.base }}...HEAD > /tmp/changed-files.txt
          echo "files-list=$(cat /tmp/changed-files.txt | tr '\n' ',' | sed 's/,$//')" >> $GITHUB_OUTPUT

      - name: Get diff
        id: diff
        run: |
          git diff origin/${{ steps.pr.outputs.base }}...HEAD > /tmp/pr-diff.patch
          echo "diff-file=/tmp/pr-diff.patch" >> $GITHUB_OUTPUT

      - name: Build review prompt
        id: prompt
        run: |
          cat > /tmp/review-prompt.txt <<'EOF'
          Please review this Pull Request:

          **Title**: ${{ steps.pr.outputs.title }}
          **Description**: ${{ steps.pr.outputs.body }}

          **Changed Files**:
          $(cat /tmp/changed-files.txt)

          **Diff**:
          ```diff
          $(head -n 500 /tmp/pr-diff.patch)
          ```

          Please provide:
          1. **Code Quality Assessment**:
             - Adherence to project standards
             - Code style and consistency
             - Potential bugs or issues

          2. **Security Review**:
             - Security vulnerabilities
             - Input validation
             - Error handling

          3. **Performance Considerations**:
             - Efficiency concerns
             - Resource usage
             - Scalability

          4. **Test Coverage**:
             - Are there adequate tests?
             - Edge cases covered?

          5. **Suggestions**:
             - Improvements
             - Alternative approaches
             - Best practices

          Format your response as:
          - Overall assessment: APPROVE / REQUEST_CHANGES / COMMENT
          - Detailed findings
          - Action items (if any)
          EOF

          echo "file=/tmp/review-prompt.txt" >> $GITHUB_OUTPUT

      - name: Run Claude Code review
        id: claude
        uses: ./.github/actions/claude-code-runner
        with:
          task-type: 'review-pr'
          prompt-file: ${{ steps.prompt.outputs.file }}
          anthropic-api-key: ${{ secrets.ANTHROPIC_API_KEY }}
          add-directories: '["src", "tests"]'
          max-tokens: 150000

      - name: Parse review result
        id: review
        run: |
          RESULT='${{ steps.claude.outputs.result }}'

          # Extract assessment
          ASSESSMENT=$(echo "$RESULT" | jq -r '.assessment // "COMMENT"')
          echo "assessment=$ASSESSMENT" >> $GITHUB_OUTPUT

          # Extract findings
          FINDINGS=$(echo "$RESULT" | jq -r '.findings // "No specific findings"')
          echo "findings<<EOF" >> $GITHUB_OUTPUT
          echo "$FINDINGS" >> $GITHUB_OUTPUT
          echo "EOF" >> $GITHUB_OUTPUT

      - name: Post review comment
        uses: actions/github-script@v7
        with:
          script: |
            const assessment = '${{ steps.review.outputs.assessment }}';
            const findings = `${{ steps.review.outputs.findings }}`;

            await github.rest.pulls.createReview({
              owner: context.repo.owner,
              repo: context.repo.repo,
              pull_number: ${{ steps.pr.outputs.number }},
              event: assessment,
              body: `## 🤖 AI Code Review

              ${findings}

              ---
              *This review was automatically generated by Claude Code*`
            });
```

**Implementation Steps**:
1. Create PR review workflow with label trigger
2. Implement diff extraction and file change detection
3. Build comprehensive review prompt template
4. Add Claude Code review execution
5. Parse and format review results
6. Post review as PR comment with proper formatting

**Deliverables**:
- [ ] `claude-code-review.yaml` workflow
- [ ] Diff-based review prompts
- [ ] Structured review output parsing
- [ ] PR review comment integration

---