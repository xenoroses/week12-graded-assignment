# MP3 Reflection

## Grounding & abstention

I started at the provided `RETRIEVAL_THRESHOLD = 0.30` and printed the top retrieval
score for every predefined and learner question before trusting it. The two
plausible-sounding out-of-corpus questions scored much higher than the FAQ's example
suggested: "Who is Professor Moriarty, and how does he meet his end?" retrieved a
top chunk at **0.482** (a vaguely similar "criminal gets caught" passage from the
Red-Headed League capture scene), and my own learner abstain question, "What breed
is Sherlock Holmes's tracking dog Toby...", scored **0.480**. Both were comfortably
above 0.30, so at the default threshold they would have been answered from outside
knowledge instead of abstaining. Meanwhile, the six genuinely answerable questions'
top scores ranged from **0.528 to 0.689**. I raised `RETRIEVAL_THRESHOLD` to **0.50**
— it sits in the ~0.05 gap between the two clusters, so the score gate alone now
correctly separates "plausible but not in this corpus" from "actually answerable,"
with real questions never scoring that close to the line. A genuinely out-of-domain
question ("What is the boiling point of water?") scored only 0.144, nowhere near
either cluster, so the threshold decision really only turned on the two tricky
in-genre lookalikes.

With that threshold, abstention accuracy came out at **1.0** across all three
should-abstain questions (two predefined + my own), and the hallucination rate was
**0.0** — nothing was ever answered from outside knowledge.

The more interesting case was the opposite direction: three of my six *answerable*
questions (`q1` — Red-Headed League assistant identity, `q2` — Speckled Band murder
weapon, `q5` — Red-Headed League scheme) also abstained, even though retrieval
correctly pulled chunks from the right story every time. Inspecting the retrieved
text directly (e.g. for `q1`) showed the top-3 chunks named the assistant's alias
("Vincent Spaulding") but not his real identity ("John Clay") — that reveal lives in
a later chunk ("The Capture") that ranked 6th by cosine similarity, well past
`k=3`. The model, given only the setup chunks, correctly said "I don't know" rather
than guess the name. This isn't a bug in `should_abstain` (the score gate passed —
top scores were 0.55–0.69) — it's the model's own in-prose refusal when its
retrieved evidence window doesn't contain the specific fact asked for. It's
technically correct grounding behaviour, but it means my abstention mechanism can't
currently distinguish "this document isn't in the corpus" from "the right document
is here, but my top-k window missed the one paragraph with the answer."

## Citations

Across all nine live questions, `validate_citations` never caught a fabricated
marker — gpt-4o-mini stayed within the numbering it was given every time (e.g. `q3`
cited `[1][2]` from the two retrieved "The Photograph" chunks; `q6` cited `[3]` for
the James Ryder confession). I confirmed the catching logic itself works via
`selftest`, which feeds it a deliberately out-of-range marker (`validate_citations("An
outside fact [3].", 2)` must flag `invalid == [3]`) — that case passes offline, so I
trust it would catch a real fabrication if gpt-4o-mini produced one. Given how often
the model instead abstained (3 of 9 questions) rather than answer loosely, I suspect
the system prompt's framing ("If the excerpts do not contain the answer, reply with
exactly...") pushed it toward under-answering rather than over-citing, which is the
safer failure mode for this kind of assistant.

## Reading your eval table

```
Retrieval hit rate    : 1.0   (6 answerable questions)
Grounded & cited rate : 0.5   (KPI: grounded response rate)
Abstention accuracy   : 1.0   (3 should-abstain questions)
Hallucination rate    : 0.0   (KPI: hallucination rate)
```

Retrieval hit rate (1.0) and abstention accuracy (1.0) are both perfect, and
hallucination rate (0.0) is the ideal floor — on this small corpus, dense retrieval
reliably finds the right *document*, and the tuned threshold reliably keeps the
system from guessing on out-of-corpus questions. The weakest number is **grounded &
cited rate at 0.5**: half the answerable questions were correctly grounded and
cited (`q3`, `q4`, `q6`), and half abstained despite the right document being
retrieved (`q1`, `q2`, `q5`) — the fact that mattered for the answer ranked outside
the fixed `k=3` window in each case. If I were to improve one thing, I'd raise `k`
(I checked manually: the missing fact for `q5` only appears at rank 6, so even
`k=5` wouldn't have been enough) or chunk each story so that "setup" and
"resolution" sections aren't split as far apart — right now a 500-character target
chunk size breaks a single Sherlock Holmes case into ~13 pieces, and the
resolution/reveal chunk consistently scores lower against the question's own
wording (which echoes the setup vocabulary, not the reveal's).

## One surprise

I expected abstention failures to look like hallucination (the model confidently
answering a Moriarty question from outside knowledge). Instead, the real failure
mode was the opposite and much harder to spot from the eval table alone: the system
was *too* willing to abstain on real, in-corpus questions once the evidence window
didn't cover the exact requested fact. From the outside, "abstained because the
story isn't in the corpus" and "abstained because retrieval's top-3 window missed
the one paragraph with the answer" look identical in the eval table (both show
`abstained: ✓`) — I only found the distinction by manually printing the retrieved
chunk text for each failing question. A production version of this eval harness
would need a third category (something like "retrieved-but-incomplete") to tell
those two apart automatically instead of requiring that manual inspection.
