# ---------- builder ----------
FROM node:23.11.0 AS builder
WORKDIR /app

# Pin pnpm to match your lockfile (change if yours is v8/9/10)
ARG PNPM_VERSION=7.33.6

# Allow corepack to download to a writable dir during build
ENV COREPACK_HOME=/root/.cache/corepack \
    XDG_CACHE_HOME=/root/.cache \
    npm_config_cache=/root/.npm

RUN corepack enable && corepack prepare pnpm@${PNPM_VERSION} --activate

# Copy manifests first
COPY package.json pnpm-lock.yaml ./
# COPY pnpm-workspace.yaml ./

# Dev deps needed for build: tsc, copyfiles, etc.
RUN pnpm install --frozen-lockfile

# Copy the rest and build
COPY . .
# Remove any host-generated tsc incremental cache so the container does a clean full emit.
# tsconfig.tsbuildinfo can contain absolute paths that break emits inside Docker.
RUN rm -f tsconfig.tsbuildinfo && pnpm build

# ---------- runtime (OpenShift-friendly) ----------
FROM node:23.11.0 AS runner
WORKDIR /app

# IMPORTANT: Make caches writable even under random UID
ENV HOME=/tmp \
    COREPACK_HOME=/tmp/corepack \
    XDG_CACHE_HOME=/tmp/.cache \
    npm_config_cache=/tmp/.npm \
    NODE_ENV=production

# Pre-create dirs with open perms so arbitrary UID can write
RUN mkdir -p /app /tmp /tmp/corepack /tmp/.cache /tmp/.npm && \
    chmod -R 777 /app /tmp

# Copy only what you need to run
COPY package.json pnpm-lock.yaml ./
# Install prod deps only (no pnpm use at runtime afterwards)
RUN corepack enable && corepack prepare pnpm@7.33.6 --activate && \
    pnpm install --prod --frozen-lockfile

# Bring built artifacts
COPY --from=builder /app/dist ./dist

EXPOSE 4000

# OpenShift runs with random UID by default; no USER needed if perms are open.
CMD ["node", "./dist/index.js"]
