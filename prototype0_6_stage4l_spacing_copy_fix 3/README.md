# Learnly Prototype 0.6 - Stage 4J Consistency Pass

This build stabilizes the visual and interaction rules identified during manual review.

## Changes in Stage 4J
- Every course learning card now uses the same header structure: Composition 101 context pill on the left and Week 1 on the right.
- Context-pill dimensions are fixed across views.
- Primary instructional text uses high-contrast white; gray is reserved for metadata and secondary microcopy.
- Type / Dictate is used consistently for speech-to-text input.
- Repeated dictation explanations have been removed from activity cards; unsupported-browser guidance appears only when needed.
- Writing instructions now appear before the task prompt in the same prompt block.
- Buttons and short controls use Title Case consistently.
- Existing adaptive support, formative retry, faculty view, research view, offline state, and Week 1 flow remain intact.

## Run
```bash
npm run seed
npm start
```
Open http://localhost:4173

## Test
```bash
npm test
```


## Stage 4L refinements
- Removes repeated Week 1 wording from the course title.
- Adds consistent writing/reflection response placeholders with Speak guidance.
- Normalizes prompt-to-Speak-to-response spacing.
