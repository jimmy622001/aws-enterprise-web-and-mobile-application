# Name
Pipilo Architecture & Delivery

# Description
Project-specific guidance for Pipilo. Apply AWS architecture best practices to this repository with the current PoC constraints, including tagging, DR documentation, observability, cost optimization, and secure handling of sensitive data.

# Instructions
When working in this project, apply the following project-specific rules in addition to general AWS architecture best practices.

## Project Context
- This repository is currently a PoC.
- Local Terraform state is acceptable for now, but the design should be easy to migrate to AWS-managed remote state later.
- The landing zone is out of scope for now and may be used in the future.
- The project includes infrastructure, ECS, API, frontend, and related deployment assets.

## Mandatory Rules

### 1. No sensitive information in code
- Do not place secrets, credentials, tokens, or private keys in source code.
- Keep sensitive values only in approved environment-specific files or secure secret storage.
- Treat generated environment files and shell helpers as sensitive unless proven otherwise.
- Prefer safe handling of credentials in CI/CD and local workflows.

### 2. Tagging
- Every AWS resource must include the `pipilo` tag.
- Preserve consistent tagging across all modules and environments.
- If useful, also apply standard tags such as environment, service, or owner, but `pipilo` is mandatory.
- Flag any resource or module that does not clearly propagate tags.

### 3. Observability
- Ensure observability is complete, not partial.
- Review logging, metrics, alarms, dashboards, and retention as a unified system.
- Identify missing alarms, missing dashboards, weak alert thresholds, or unhelpful telemetry.
- Prefer actionable monitoring over noisy or redundant monitoring.

### 4. Disaster Recovery
- DR documentation must include:
    - the purpose of DR
    - target RTO
    - target RPO
    - failover behavior through Route 53
    - the process for failover validation
    - periodic DR testing
- The DR design should explain how primary failure results in failover to DR.
- The DR process should be realistic, repeatable, and documented clearly.

### 5. Cost Optimization
- Recommend practical cost optimizations wherever possible.
- Review always-on resources, logging retention, idle services, and oversized infrastructure.
- Prefer right-sizing and scaled-down non-production environments where appropriate.
- Highlight unnecessary cost drivers and suggest lower-cost alternatives when safe.

### 6. Terraform and state
- Local state is allowed for this PoC only.
- Do not block the current build on remote state migration.
- However, keep the architecture ready for future remote state adoption with locking and encryption.
- Call out any design choices that would make migration harder later.

## Expected Review Behavior
- Be practical and specific.
- Distinguish between PoC-acceptable decisions and production concerns.
- If something is acceptable for PoC but not ideal long term, say so clearly.
- If something is risky now, explain the risk and suggest a better path.
- Do not invent requirements that are not part of this project’s current direction.
- Ask targeted questions when a decision depends on missing context.

## Review Priorities
When reviewing this repo, prioritize:
1. Security and sensitive data handling
2. Tagging consistency
3. DR clarity and documentation
4. Observability completeness
5. Cost controls
6. Future readiness for remote state and landing zone adoption

## Output Style
- Be concise, direct, and actionable.
- Use clear headings for findings.
- Separate critical issues from improvements.
- Include practical remediation steps.
- Keep PoC constraints in mind, but do not ignore risky patterns.

## Final Goal
Help Pipilo remain secure, observable, cost-aware, and DR-ready while staying practical for the current PoC stage and easy to evolve into a production-ready AWS platform later.