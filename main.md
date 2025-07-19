main.md

Below are four self-contained “super-prompts”—one for each sprint lane (A-D).
Paste each block into Cursor / Windsurf / GitHub Copilot as the first message in a new chat or doc; it will generate scaffolds, sample code, test stubs, and docs for that lane.
Every prompt ends with a Definition-of-Done checklist so each teammate can verify their lane before merging to main.

⸻

Lane A — Developer-Facing UX

(Front-end panels, CLI Wizard, overall repo glue)

You are an expert VS Code extension & CLI engineer.  
Goal: ship a polished “GemHub” developer UX that talks to back-end APIs.

1. **Continue.dev Sidebar**
   • Tabs: Marketplace, Sandbox, Benchmarks, Chat.  
   • Commands palette entries: gemhub-wizard, gem-create, gem-benchmark.  
   • Use React + TypeScript; build with esbuild; hot-reload via `npm run dev`.  
   • WebSocket stream for logs; REST fetch for CRUD.

2. **CLI (Thor)**
   • `bin/gemhub wizard` → interactive gem creator (name, license, CI template).  
   • `bin/gemhub publish` → POST `/gems`; push tag.

3. **Branch & Repo Utilities**
   • Create root `README.md`, `CODEOWNERS`; set up `Procfile.dev`.  
   • Add GitHub Actions: lint, unit tests, container build.

### Definition of Done — Lane A
- [ ] Extension builds in VS Code with zero errors.
- [ ] CLI wizard generates a minimal, test-passing gem skeleton.  
- [ ] “Marketplace” tab lists gems returned by `GET /gems`.  
- [ ] All TS/JS passes `eslint --max-warnings=0`.  
- [ ] Docs: `extension/README.md` shows install & dev steps.  


⸻

Lane B — Core API & Registry

(Sinatra micro-service, SQLite models, rating/badge logic)

You are a Ruby/Sinatra API specialist.  
Goal: deliver GemHub’s registry service with lean code & full tests.

1. **Service Skeleton**
   • `services/api/app.rb` using Sinatra 3, Sequel ORM, SQLite.  
   • Models: Gem, Rating, Badge.  
   • CRUD routes: `/gems`, `/gems/:id/ratings`, `/badges`.

2. **Security Extras**
   • Endpoint `POST /scan` triggers CVE scanner (to be implemented in Lane C).  
   • Simple token auth (`ENV['API_TOKEN']`).

3. **Unit & Contract Tests**
   • RSpec + Rack::Test + json-matchers.

4. **Docker**
   • `Dockerfile` (Ruby 3.3-slim), health-check.  
   • Expose `4567`.

### Definition of Done — Lane B
- [ ] `docker compose up api` responds to `GET /gems` with 200 OK.  
- [ ] Full CRUD + validation tests green in CI.  
- [ ] Seed script loads ≥3 sample gems.  
- [ ] API docs auto-generated via `openapi3_renderer`.  


⸻

Lane C — Sandbox & Quality Gates

(One-click Rails demo, benchmark-ips, RubySec CVE scan)

You are an infra-savvy Ruby engineer focused on quality automation.

1. **Sandbox Orchestrator**
   • Bash script `services/sandbox_orch/launch.sh` that:  
     – Generates `docker-compose.sandbox.yml`.  
     – Mounts the target gem, boots a Rails 7 demo on port 3000.  
   • Provide teardown script.

2. **Benchmarks**
   • `services/bench/bench.rb` runs `benchmark-ips` comparing target gem vs baseline.  
   • Output JSON to `bench_results/`.

3. **CVE Scanner**
   • `services/cve_scanner/scan.rb` wraps RubySec API; returns JSON list of CVEs.  
   • Expose CLI `ruby scan.rb <gem_name>` and HTTP `/cve/:gem`.

4. **Reporting**
   • Write results to API via `/metrics` (to be consumed by Lane D charts).

### Definition of Done — Lane C
- [ ] `./launch.sh` opens Rails app showing the loaded gem.  
- [ ] Benchmark JSON contains iterations/sec & std-dev for ≥1 method.  
- [ ] CVE scan detects a seeded vulnerable gem in test.  
- [ ] Scripts run cross-platform (macOS/Linux) inside Docker.  


⸻

Lane D — AI Layer & Observability

(LLM gateway, FAISS vector store, D3 charts for metrics)

You are a Python/FastAPI & data-viz engineer.

1. **LLM Gateway (`services/llm_gateway`)**
   • FastAPI app, async routes `/rank`, `/suggest`.  
   • Uses `openai` 1.x; rate-limits via `slowapi`.  
   • Env vars: `OPENAI_API_KEY`, `MODEL=gpt-4o-mini`.

2. **Vector Store**
   • Script `services/vector_store/ingest.py` builds FAISS index from gem READMEs.  
   • Provide `search(text, k=5)` util.

3. **Metrics & Charts**
   • In extension panel (Lane A), add D3 widget fed by `/metrics` endpoint.  
   • Show benchmarks, CVE count, popularity stars.

4. **DevOps Glue**
   • Update `docker-compose.yml` to include llm_gateway & vector_store.  
   • Add Makefile target `make embed` to refresh FAISS.

### Definition of Done — Lane D
- [ ] `POST /rank` returns gem IDs ordered by LLM relevance.  
- [ ] FAISS index builds in <30 s for 100 docs.  
- [ ] Charts render in sidebar with real data.  
- [ ] Gateway unit tests mock OpenAI and fully pass.  


⸻

Cross-Lane Integration Checklist (pre-merge to main)
	•	Branch naming: lane-a/*, lane-b/*, etc.; fast-forward squash into main.
	•	docker compose up brings all services healthy (green).
	•	Extension, CLI, and API versions agree on route paths & payload shapes.
	•	End-to-end demo: wizard ➜ sandbox ➜ benchmark ➜ publish ➜ AI rank runs without manual fixes.
	•	README.md root shows one-command setup & demo GIF.

Follow these lane prompts and checklists, and the four-person team can sprint independently yet land a seamlessly integrated GemHub MVP on a single main branch. Happy hacking!