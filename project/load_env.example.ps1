# Copy this file to load_env.ps1 and fill in your real values.
# load_env.ps1 is gitignored on purpose -- never commit real API keys.

$env:OPENAI_API_KEY = "sk-..."
$env:OPENAI_BASE_URL = ""   # leave blank unless using a proxy (e.g. a course gateway)

$env:QDRANT_URL = "https://YOUR-CLUSTER-ID.qdrant.io:443"   # use :443, not :6333, behind a
                                                              # corporate TLS-inspecting proxy (Zscaler etc.)
$env:QDRANT_API_KEY = "YOUR-QDRANT-API-KEY"

# Tuned from the default 0.30 -> 0.50; see mp3_reflection.md for why.
$env:RETRIEVAL_THRESHOLD = "0.50"

Write-Host "Environment variables set for this PowerShell session."
