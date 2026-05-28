FROM --platform=linux/arm64 node:20-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci

FROM --platform=linux/arm64 node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV AUTH_SECRET=build \
    AUTH_KEYCLOAK_ID=build \
    AUTH_KEYCLOAK_SECRET=build \
    AUTH_KEYCLOAK_ISSUER=http://keycloak.svc/auth/realms/astralcloud \
    NEXTAUTH_URL=http://dashboard.astralcloud.local
RUN npm run build

FROM --platform=linux/arm64 node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production PORT=3000
RUN addgroup -S nodejs && adduser -S nextjs -G nodejs
COPY --from=builder /app/public ./public
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static
USER nextjs
EXPOSE 3000
CMD ["node", "server.js"]
