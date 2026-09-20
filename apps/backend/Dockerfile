# ==========================================
# STAGE 1: Build & Compile TypeScript
# ==========================================
FROM node:22-alpine AS builder

WORKDIR /app

# Install build dependencies
COPY package*.json ./
RUN npm ci

# Copy source and configurations
COPY tsconfig*.json nest-cli.json ./
COPY src/ ./src/

# Compile NestJS application to /app/dist
RUN npm run build

# Remove development dependencies to keep image small
RUN npm prune --production

# ==========================================
# STAGE 2: Lightweight Production Runtime
# ==========================================
FROM node:22-alpine AS runner

WORKDIR /app

# Set production environment
ENV NODE_ENV=production
ENV PORT=3000

# Create non-root system user for security
USER node

# Copy production artifacts from builder stage
COPY --chown=node:node --from=builder /app/package*.json ./
COPY --chown=node:node --from=builder /app/node_modules ./node_modules
COPY --chown=node:node --from=builder /app/dist ./dist

EXPOSE 3000

# Start NestJS application
CMD ["node", "dist/main.js"]
