# Create Project Document Skill

Create project documentation for AstralCloud services and components.

## Usage

When invoked, ask the user:

1. **What type of document?** (README, Architecture, API, ADR, or All)
2. **Which service/component?** (dashboard, file-storage, media-streaming, auth, infra, or root)

Then generate the appropriate document(s) in the correct location.

---

## Document Types

### 1. README.md

**Location:** `<service>/README.md`

**Template:**

```markdown
# <Service Name>

One-line description of what this service does.

## Overview

2-3 sentences on the purpose and responsibilities of this service.

## Tech Stack

- **Language:** Go / Next.js / etc.
- **Database:** PostgreSQL / SQLite / Redis / etc.
- **Port:** <default port>

## Getting Started

### Prerequisites

- List dependencies (Go 1.22+, Node 20+, etc.)

### Run locally

\`\`\`bash

# commands to run the service

\`\`\`

### Run tests

\`\`\`bash

# commands to run tests

\`\`\`

## Configuration

| Env Var        | Description                | Default |
| -------------- | -------------------------- | ------- |
| `PORT`         | Service port               | `8080`  |
| `DATABASE_URL` | Database connection string | -       |

## API

Brief summary or link to full API doc.

## Docker

\`\`\`bash
docker build --platform linux/arm64 -t tara-astralcloud/<service>:<tag> .
\`\`\`
```

---

### 2. Architecture Document

**Location:** `docs/architecture/<component>.md`

**Template:**

```markdown
# <Component> Architecture

## Purpose

What problem does this component solve?

## Design

High-level description of the design approach.

## Component Diagram

\`\`\`
[Draw ASCII diagram or describe components]
\`\`\`

## Key Design Decisions

| Decision | Choice        | Reason |
| -------- | ------------- | ------ |
| Database | PostgreSQL    | ...    |
| Auth     | Keycloak OIDC | ...    |

## Data Flow

Step-by-step description of the main data flow.

## Dependencies

- **Upstream:** services this component calls
- **Downstream:** services that call this component

## Scalability & Constraints

Notes on Pi/ARM64 constraints, memory limits, etc.
```

---

### 3. API Reference

**Location:** `docs/api/<service>.md`

**Template:**

```markdown
# <Service> API Reference

Base URL: `http://<service>.<namespace>.svc.cluster.local:<port>`

All endpoints require a valid Keycloak JWT in the `Authorization: Bearer <token>` header unless marked public.

---

## Endpoints

### `GET /health`

Public health check.

**Response**
\`\`\`json
{ "status": "ok" }
\`\`\`

---

### `<METHOD> /<resource>`

**Description:** What this endpoint does.

**Request**
\`\`\`json
{
"field": "type"
}
\`\`\`

**Response**
\`\`\`json
{
"field": "type"
}
\`\`\`

**Errors**

| Code | Meaning        |
| ---- | -------------- |
| 400  | Bad request    |
| 401  | Unauthorized   |
| 404  | Not found      |
| 500  | Internal error |
```

---

### 4. Architecture Decision Record (ADR)

**Location:** `docs/adr/<NNN>-<short-title>.md`

Number ADRs sequentially (001, 002, ...).

**Template:**

```markdown
# ADR-<NNN>: <Title>

**Date:** YYYY-MM-DD
**Status:** Proposed | Accepted | Deprecated | Superseded by ADR-<NNN>

## Context

What situation or problem prompted this decision?

## Decision

What was decided?

## Consequences

**Positive:**

- ...

**Negative:**

- ...

## Alternatives Considered

| Option | Why rejected |
| ------ | ------------ |
| ...    | ...          |
```

---

## Document Creation Rules

- Always check if the document already exists before creating it
- Create any missing parent directories
- For README: read existing source files in the service to fill in accurate details — don't make up commands or config
- For API docs: read actual route definitions from source code
- For ADRs: ask for context, decision, and tradeoffs before writing
- After creating, add/commit using `/git-manage` conventions:
  - `docs(<scope>): add README`
  - `docs(<scope>): add architecture doc`
  - `docs(<scope>): add API reference`
  - `docs(adr): add ADR-NNN <title>`
