FROM node:20.18.0-slim AS builder

WORKDIR /home/perplexica

COPY package.json yarn.lock ./
RUN yarn install --frozen-lockfile --network-timeout 600000

COPY tsconfig.json next.config.mjs next-env.d.ts postcss.config.js drizzle.config.ts tailwind.config.ts ./
COPY src ./src
COPY public ./public

RUN mkdir -p /home/perplexica/data
RUN yarn build

FROM node:20.18.0-slim

WORKDIR /home/perplexica

COPY --from=builder /home/perplexica/public ./public
COPY --from=builder /home/perplexica/.next/static ./public/_next/static

COPY --from=builder /home/perplexica/.next/standalone ./
COPY --from=builder /home/perplexica/data ./data

RUN mkdir /home/perplexica/uploads

# Créer le script qui génère le config.toml
RUN echo '#!/bin/bash\n\
\n\
# Générer config.toml à partir des variables d'\''environnement\n\
cat > /home/perplexica/config.toml << EOF\n\
[GENERAL]\n\
SIMILARITY_MEASURE = "${SIMILARITY_MEASURE:-cosine}"\n\
KEEP_ALIVE = "${KEEP_ALIVE:-5m}"\n\
\n\
[MODELS.OPENAI]\n\
API_KEY = "${OPENAI:-}"\n\
\n\
[MODELS.GROQ]\n\
API_KEY = "${GROQ_API_KEY:-}"\n\
\n\
[MODELS.ANTHROPIC]\n\
API_KEY = "${ANTHROPIC_API_KEY:-}"\n\
\n\
[MODELS.GEMINI]\n\
API_KEY = "${GEMINI_API_KEY:-}"\n\
\n\
[MODELS.CUSTOM_OPENAI]\n\
API_KEY = "${CUSTOM_OPENAI_API_KEY:-}"\n\
API_URL = "${CUSTOM_OPENAI_API_URL:-}"\n\
MODEL_NAME = "${CUSTOM_OPENAI_MODEL_NAME:-}"\n\
\n\
[MODELS.OLLAMA]\n\
API_URL = "${OLLAMA_API_URL:-}"\n\
\n\
[API_ENDPOINTS]\n\
SEARXNG = "${SEARXNG_API_URL:-}"\n\
EOF\n\
\n\
echo "Configuration générée. Démarrage de l'\''application..."\n\
\n\

RUN chmod +x /home/perplexica/start.sh

ENTRYPOINT ["/home/perplexica/start.sh"]
CMD ["node", "server.js"]