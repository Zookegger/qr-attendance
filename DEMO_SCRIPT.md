# GitLab CI/CD & Project Management Demo Script

This script guides you through demonstrating GitLab's project management and CI/CD capabilities using this repository.

## Prerequisites
1.  Push this repository to a GitLab project.
2.  Ensure you have "Maintainer" access to the project.

## Scene 1: Project Structure & Code Owners
**Goal:** Show how the project is organized and how `CODEOWNERS` enforces review.

1.  **Open VS Code**.
2.  Show the file structure: `client/` (Flutter) and `server/` (Node.js).
3.  Open `.gitlab/CODEOWNERS`.
    *   Explain: "We define who owns which part of the codebase. Frontend team owns `client/`, Backend team owns `server/`."
    *   *Talking Point:* "This automatically adds the right reviewers to Merge Requests."

## Scene 2: Issue Tracking
**Goal:** Start work from a defined task.

1.  **Go to GitLab > Issues**.
2.  Click **New Issue**.
3.  Select the **Feature** template (if available) or just type:
    *   **Title:** "Add login validation for QR scanner"
    *   **Description:** "We need to ensure the QR code is valid before sending to backend."
4.  Assign it to yourself.
5.  Click **Create Issue**.
6.  Click **Create merge request** from the issue page.
    *   *Talking Point:* "GitLab links the code branch directly to the issue, keeping everything traceable."

## Scene 3: The CI/CD Pipeline (The "Magic")
**Goal:** Show automation.

1.  **Go to VS Code** (switch to the new branch created by the MR, e.g., `1-add-login-validation`).
2.  Open `.gitlab-ci.yml`.
    *   Walk through the stages: `test`, `build`, `deploy`.
    *   Highlight: "We run Flutter tests and Node.js tests in parallel."
3.  **Make a dummy change**:
    *   Open `client/lib/main.dart`.
    *   Add a comment: `// TODO: Implement validation logic`.
4.  **Commit and Push**:
    ```bash
    git add .
    git commit -m "Start implementing validation"
    git push
    ```
5.  **Go to GitLab > CI/CD > Pipelines**.
    *   Show the pipeline running.
    *   Click into it to show the graph.
    *   *Talking Point:* "Every commit triggers a pipeline. We build the Flutter web app and run all tests automatically."

## Scene 4: Merge Request & Review
**Goal:** Show collaboration and gates.

1.  **Go to the Merge Request**.
2.  Show the **Pipeline** widget: "The pipeline is running/passed."
3.  Show the **Approval Rules** (if configured) or just mention Code Owners.
4.  **Simulate a Review**:
    *   Comment on a line of code in the "Changes" tab.
5.  **Merge** the request (if pipeline passes).

## Scene 5: Deployment
**Goal:** Show CD to Staging and Production.

1.  Once merged to `main`, go to **CI/CD > Pipelines**.
2.  Find the pipeline for `main`.
3.  Show the `deploy_staging` job running automatically.
4.  Show the `deploy_production` job waiting for **Manual Action**.
    *   *Talking Point:* "We deploy to staging automatically for QA. Production is a manual button press to ensure safety."
5.  Click the **Play** button on `deploy_production`.

## Scene 6: Artifacts
**Goal:** Show the build output.

1.  Go to the `client_build_web` job in the pipeline.
2.  On the right sidebar, click **Browse** under "Job artifacts".
3.  Show the `client/build/web` folder.
    *   *Talking Point:* "The compiled app is stored here and can be downloaded or deployed."
