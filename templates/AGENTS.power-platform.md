# Power Platform project overlay

Add this overlay to a project-specific `AGENTS.md`; it does not replace that
project's existing instructions or source-of-truth rules.

## 探索・試作

MCP and AI skills may create and validate new, temporary assets only in a
development environment. For Canvas Apps, use version-controlled artifacts
when available. For FlowAgent, create a new cloud flow in a **stopped state**.
For Dataverse, inspect metadata and read data by default.

Do not replace, delete, publish, import, or change existing managed assets in
this lane. State the temporary target and rollback path before a trial that
writes data or schema.

## 採用・運用

Move work to Git-managed project source before it becomes shared, long-lived,
multi-environment, business-affecting, or data/security affecting. The
project's Python, Solution, YAML, flow definition, version-controlled Canvas
artifact, and CI/CD remain the source of truth.

Review the diff before applying an approved change. Record connection
references, dependencies, and verification evidence with the promoted source.

## Approval boundary

**Explicit approval** is required before any operation on existing managed
assets, publish, deletion, security role change, environment change, Solution
import, channel configuration, or production operation.

Copilot Studio pull, push, publish, and channel changes are cloud mutations and
require target, diff, connection, and publish-state review first. Dataverse
schema/data changes, security changes, and imports require the same approval.

Keep tenant URLs, accounts, tokens, authentication caches, and user-specific
MCP settings outside repository files and shared reports.
