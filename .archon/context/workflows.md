# Workflow Execution Context

## 1. Delivery & Git Invariants
- **Remote Invariant**: All mutations (`git checkout`, `git push`, PR creation) target `origin` ONLY. `upstream` is strictly read-only for Yeti autonomous work.
- **PR Delivery Contract**:
  - Contribution Lifecycle:
    1. Yeti implements the issue on `origin:feature/<issue-name>`.
    2. User reviews the Candidate PR in the fork (`atyeti-inc/Bank-of-Z`).
    3. Rebase the feature branch onto `upstream:main`.
    4. Submit `feature/<issue-name>` upstream to `IBM/Bank-of-Z`.
  - Upstream Contribution Rules:
    - Mandatory DCO: All commits must include `-s` (`Signed-off-by: Full Name <email>`). Unsigned commits are rejected by upstream checks.
    - Clean History: Rebase onto `upstream:main` before upstream PR submission; no merge bubbles or dirty commits.
  - Plan-vs-diff containment: Confine implementation strictly to the accepted issue scope. Opportunistic cleanup, unsolicited refactoring, or collateral modifications are strictly prohibited.
  - Out-of-scope logging: Any issues, cleanup opportunities, or defects discovered outside the issue scope must be logged as follow-up new issues on the origin repository (`atyeti-inc/Bank-of-Z`), NOT upstream.

## 2. Toolchain & Boundary Invariants (Optional)
- **Primary Languages & Extensions**:
  - COBOL (`.cbl`, `.cpy`), PL/I (`.pli`), BMS maps (`.bms`), JCL (`.jcl`, `.j2`), Assembler (`.asm`)
  - Java (`.java`), Gradle (`.gradle`)
  - JavaScript (`.js`), HTML (`.html`), CSS (`.css`)
  - Python (`.py`), YAML (`.yaml`, `.yml`), Shell (`.sh`)
- **Directory Layout & Boundaries**:
  - `src/base/`: Core z/OS programs divided into `cics/`, `ims/`, `batch/`, and `mq/`.
  - `src/api/`: z/OS Connect API Gradle project, OpenAPI definitions (`src/main/api/openapi.yaml`), and mapping assets (`src/main/zosAssets/`).
  - `src/frontend/`: Static Carbon Design System web UI.
  - `.setup/`: Provisioning, deployment, and configuration scripts.
  - `tests/`: Automated test suite (Python regression tests and bash verification scripts).

## 3. Verification & Test Harness Contract
- **Test Runner & Verification**:
  - `python3 -m unittest discover tests`: Local regression tests for Db2 provisioning and templating logic (requires Python 3 with `jinja2` and `pyyaml`).
  - `bash tests/run-all.sh`: Installation verification script running all test scripts in `tests/`.
  - `bash tests/test-setup.sh`: Setup script verification.
  - `bash tests/test_frontend.sh`: Frontend availability and endpoint verification.
- **Lint / Typecheck**:
  - `pre-commit run --all-files`: Pre-commit hook validating files against `.secrets.baseline`.
  - `detect-secrets scan --baseline .secrets.baseline`: Direct detect-secrets audit.
- **Test Isolation & Sandbox Requirements**:
  - Local unit tests in `tests/test_db2_provisioning.py` are mock-based and do not execute z/OS commands or provision hardware.
  - Live verification tests (`test_*.sh`) require active z/OS Connect and Liberty instances configured via `BASE_URL` and `FRONTEND_URL`.
- **Pass Criteria**: Zero syntax errors, zero test regressions, clean git working tree, zero un-baselined secrets, and 100% DCO sign-offs.

## 4. Code Style & Design Invariants
- **Typing Discipline**:
  - Strict compliance with COBOL copybook structure definitions (`.cpy`) and BMS field layouts.
  - Strict schema compliance with OpenAPI 3.0 specification in `src/api/src/main/api/openapi.yaml`.
  - Strong typing in Java 21 components with no raw types.
- **Error Handling**:
  - CICS programs must inspect and handle CICS response codes (`RESP` / `RESP2`) and invoke `ABNDPROC` on unexpected failures.
  - IMS programs must evaluate DL/I status codes after each call.
  - Db2 SQL queries must evaluate `SQLCODE` / `SQLSTATE`.
  - z/OS Connect operations must standardize HTTP error code mapping (400, 401, 403, 404, 500) at the API boundary.
