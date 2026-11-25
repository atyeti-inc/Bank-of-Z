# Orchestrator Context

## 1. Functional Role & Scope Boundaries
- **Functional Role**: Hybrid multi-tier banking application on IBM z/OS demonstrating modern mainframe development patterns. Exposes REST APIs via z/OS Connect, routing banking transactions to CICS and IMS core transaction processing backends, Db2 databases, batch statement programs, and IBM MQ integration.
- **Issue Tracking & Scope Boundaries**:
  - All planned tasks, epics, and work orders map to `atyeti-inc/Bank-of-Z`.
  - Refusals & Out-of-Scope: Issues must be solved narrowly. Opportunistic cleanup, unrelated refactoring, or collateral alterations beyond the explicit issue scope are strictly prohibited. Any out-of-scope defects, improvements, or recommendations discovered must be noted as follow-up new issues on origin (`atyeti-inc/Bank-of-Z`), never upstream.
  - UI & Browser Automation Boundary: Strictly avoid UI emulation, browser automation, or frontend DOM clicking (e.g. issues requiring manual or headless browser tests). Focus strictly on backend transactional systems, copybooks, and resource definitions.

## 2. Qualified Problem Archetypes
- **Archetype A: Computational Precision**: Eliminating floating-point (`COMP-2`) penny-drop truncation when mapping to fixed-point decimal (`PIC S9(10)V99`) using deterministic mathematical sweeps.
- **Archetype B: Defensive Bounds Checking**: Enforcing string presence, length, and enumeration checks on COMMAREA buffers before Db2/CICS execution.
- **Archetype C: Configuration & Resource Sync**: Atomic excision of obsolete CICS resource definitions (`bank-of-z-definitions.yaml`) and procedural I/O (`ABNDFILE`) validated against JSON schemas.

## 3. Core Architectural Invariants & ADRs
- **Architecture Pattern**: Hybrid Multi-Tier Mainframe Application (Service-Oriented Mainframe & API Gateway)
- **Key Subsystems & Boundaries**:
  - `Frontend`: Single-page web UI using Carbon Web Components, Vanilla JS, HTML, and CSS served on Liberty port 9445/9081.
  - `API Gateway (z/OS Connect)`: Liberty server hosting OpenAPI 3.0 REST definitions and mapping configurations (`.dai`, `.cpy`) routing to backend core services.
  - `CICS Core Banking`: COBOL programs and BMS maps with Db2 SQL tables managing accounts, customers, transactions, and balances.
  - `IMS Core Banking`: COBOL, PL/I, and Java (JMP) programs executing DL/I calls against IMS databases.
  - `Batch Subsystem`: COBOL and PL/I programs driven by JCL for statement processing.
  - `Bank of Q (BOQ)`: Java message-driven components for interbank money transfers via IBM MQ.
  - `Provisioning & Automation`: Python (Jinja2, PyYAML) and Shell scripts for Db2 provisioning, RACF certificates, and DBB user builds.
- **Architectural Invariants / ADRs**:
  - Dual Backend Routing: Requests route to CICS or IMS core banking engines dynamically based on customer ID.
  - Keyring Certificate Re-Sign: Private key remains strictly within RACF keyring; certificates are re-signed with TLS Web Server Authentication EKU and SANs using the VSICA CA key.
  - Identifier & Schema Immutability: Copybook variable names, DCLGEN host structures, record layouts, and byte offsets/lengths are frozen contracts. Never rename fields or perform cosmetic "typo fixes" unless explicitly specified by the issue work order.
  - Mainframe Architecture Preservation: Reject blanket language rewrites. Preserve z/OS CICS, IMS, and Db2 semantics.
  - DCO Sign-off Invariant: All commits must include a Developer Certificate of Origin sign-off (`git commit -s`). For all signing, the author and email are Chris Caldwell <7295199+Thummpy@users.noreply.github.com>.
  - Detect-Secrets Invariant: Pre-commit scanning with `ibm/detect-secrets` against `.secrets.baseline` must pass without un-baselined secrets.
  - Build Invariants: z/OS native builds are governed by `dbb-app.yaml` and `zapp.yaml`.
- **Linguistic / Stack Constraints**:
  - Target Environment: IBM z/OS Unix System Services (USS) with CICS TS, IMS, Db2, and z/OS Connect Liberty.
  - Mainframe Languages: Fixed-format ANSI COBOL (columns 1-6 sequence, 7 indicator, 8-11 Area A, 12-72 Area B, 73-80 blank/identification), PL/I, BMS macros, and JCL conforming to DBB specifications.
  - Java: Java 21 LTS for IMS JMP and MQ Java components managed via Gradle.
  - Node.js: Node.js 22.22.1+ for IDE setup scripts.
  - Python: Python 3 with Jinja2 and PyYAML for templating and setup automation.

## 4. Toolchains & Operational Commands
- **Runtimes & Package Managers**: z/OS USS, Java 21 LTS, Node.js 22+, Python 3 (Jinja2, PyYAML, jsonschema), GnuCOBOL 3.2+, Gradle, pip, pre-commit
- **Local Verification Standard**:
  - `bash .archon/validate.sh`: Single authoritative local verification suite executing 6 discrete stages:
    - Stage 1: COBOL 80-column layout audit and GnuCOBOL syntax check (IMS modules and prepped CICS modules).
    - Stage 2: Standalone COBOL test runners for Archetype A decimal precision and Archetype B bounds checking.
    - Stage 3: Repository YAML syntax and CICS resource definition schema validation (`bank-of-z-definitions.yaml`).
    - Stage 4: Db2 template unit testing (`python3 -m unittest discover tests`).
    - Stage 5: Java & API builds via Gradle (gracefully skipped if Gradle is absent).
    - Stage 6: Repository governance audit (working tree cleanliness and DCO sign-offs).
  - Exit code contract: Exits 0 on success; non-zero immediately on any stage failure.
- **Build / Codegen Prerequisite**:
  - `gradle -p src/api build`: Generates API artifacts from OpenAPI schema via z/OS Connect Gradle plugin
  - `gradle -p src/base/ims/java build`: Compiles and packages IMS Java JMP jar
  - `gradle -p src/base/mq/java build`: Compiles and packages BOQ MQ Java jar
  - `node scripts/setup-vscode.js`: Downloads and installs required VS Code extensions and workspace setup
