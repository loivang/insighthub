# MLOps Overview Notes

## Lifecycle Map

MLOps covers the path from dataset collection to model training, evaluation,
approval, deployment, monitoring, and rollback. For InsightHub, the current app
uses hosted LLM/embedding providers, but the same lifecycle applies if the team
later owns an embedding or reranking model.

## Registry And Approval Gate

A model registry records model versions, metadata, metrics, and lineage. An
approval gate decides which version can move from staging to production. DevOps
usually owns the gate automation; ML engineers own evaluation criteria and
model quality signals.

## Drift

Drift happens when production traffic or source documents differ from the data
used during model evaluation. For a RAG app this can show up as lower answer
quality, retrieval misses, higher hallucination rate, or latency/cost changes.

## Rollback

Rollback means restoring a previous model, prompt, embedding model, or index
configuration when quality, latency, or cost regresses. Rollback should be tied
to observable signals and should not depend on manual guesswork.

## Ownership Boundary

DevOps owns platform reliability: deployment, observability, alerts, rollback
mechanics, and cost controls. ML engineers own model behavior, evaluation,
training data, and acceptance thresholds. Shared ownership is required for
production incidents because failures often cross both boundaries.
