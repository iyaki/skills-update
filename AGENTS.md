# Agent Guidelines

## Spec-First Workflow

- Read `specs/README.md` before any feature work.
- Assume specs describe intent, not implementation.
- Verify reality in the codebase before claiming something exists.
- Implement to spec patterns and data shapes; update specs only when asked.
- When Writting specs, **NEVER** follow Test Driven Development practices. Write the spec first and stop.
- For programming tasks, always load Test Driven Development skill.

## Testing and Quality Gates

- Follow Test Driven Development practices: write failing tests before implementation.
- Coverage gate: 100%.
- Execute mutation testing ONLY in final stages of the task development. **NEVER** execute mutation testing during the Test Driven Development process.

## Commands

## Deployment (Optional)

## Database Migrations (Optional)

## Local Testing

## Architecture

## Code Style

## Implementation Guidance

- Keep scans deterministic and reproducible.
- Skip binary/oversized files per spec; record skipped file stats.
- Treat match text as sensitive; avoid logging it in console.
- When multiple code paths do similar work with small variations, consolidate into shared services with request structs.
