# Repository Guidelines

## Project Structure & Module Organization
- `api/` houses the TypeScript Express backend (routes in `lib/routes`, scheduled jobs in `lib/cron.ts`, adapters for external services). Build artifacts land in `dist/`.
- `app/` is the Flutter mobile client (screens in `lib/screens`, shared widgets in `lib/widgets`, localization under `lib/gen_l10n`). Native shells sit in `android/` and `ios/`.
- `dashboard/` delivers the React + Vite admin UI (page modules inside `src`, shared UI in `src/components`, Tailwind hooks in `vite.config.ts`).
- `deploy/` and the `docker-compose*.yml` files spin up local infrastructure (Postgres, Redis, API). Historical data and resources live under `acc2counts/` and `days.json`.

## Build, Test, and Development Commands
- `api/`: `pnpm install` once, `pnpm dev` for the watch server, `pnpm build` to emit `dist/`, `pnpm test` for Jest specs in `test/**/*.test.ts`. Provide DB credentials via `.env` or shell variables.
- `dashboard/`: `pnpm install`, `pnpm dev` for live reload at `localhost:5173`, `pnpm build` for production assets, `pnpm lint` to enforce ESLint + TypeScript rules.
- `app/`: `flutter pub get` to sync packages, `flutter run` for a simulator/device, `flutter test` to execute `test/*.dart`.
- Full stack: `docker-compose up --build` from the repo root builds the API image and launches Postgres/Redis for integration work.

## Coding Style & Naming Conventions
- TypeScript code sticks to 2-space indentation; prefer named exports for services and routers, and keep DTOs aligned with Joi schemas.
- React components use PascalCase files, hooks start with `use`, and Tailwind utility classes remain inline rather than extracted.
- Flutter files use snake_case filenames, PascalCase classes, and lowerCamelCase methods; run `dart format .` before committing.
- Commit related configuration alongside code (e.g., update `node.config.json` or `analysis_options.yaml` when introducing new lint rules).

## Testing Guidelines
- Backend unit tests mirror `lib/**` structure (e.g., `test/routes/*.test.ts`); cover success and error paths for new logic with Jest.
- Flutter widget and model tests live in `test/` with `*_test.dart` names; stub async services via `package:mocktail` to isolate UI state.
- Frontend currently relies on manual QA; add Vitest/React Testing Library coverage in `src/__tests__` when introducing complex components or state transitions.

## Commit & Pull Request Guidelines
- Use concise, imperative commit subjects (“Support self-assessed activity bouts and energy”); add a brief body for context or references.
- Rebase before raising a PR, summarise scope, list verification steps (command output snippets or UI screenshots), and link related issues.
- Tag maintainers across API/App/Dashboard when changes span modules, and document follow-up tasks to keep infrastructure and analytics assets aligned.
