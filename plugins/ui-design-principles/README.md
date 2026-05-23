# ui-design-principles

A Claude Code plugin providing expert **UI/UX design guidance** based on Lidwell, Holden & Butler's *Universal Principles of Design* — visual hierarchy, interaction patterns, cognitive load, accessibility, and layout.

## What's Included

### Skill

| Skill | Triggers On | What It Provides |
|-------|-------------|------------------|
| **UI Design Principles** | UI design, UX design, design principles, usability, visual hierarchy, layout, accessibility, Fitts' Law, Hick's Law, cognitive load, Gestalt principles, progressive disclosure, mental model | Condensed actionable principles organized by category — visual perception, interaction, information architecture, cognition, typography, and layout proportion |

The skill includes comprehensive reference files with full principle descriptions.

### Agent

| Agent | Triggers | What It Does |
|-------|----------|--------------|
| **ui-design-reviewer** | Proactively after writing frontend code | Reviews HTML, CSS, and components for visual hierarchy issues, accessibility violations, interaction anti-patterns, information architecture problems, and consistency gaps |

## Installation

```bash
# From the Claude Code marketplace (recommended)
/install ui-design-principles

# Or install directly from GitHub
claude plugin add --git https://github.com/cyface/ui-design-principles-claude-plugin.git
```

## Skill Detail

### UI Design Principles

Covers actionable design principles organized by category:
- **Visual Perception** — Aesthetic-usability effect, figure-ground, similarity, von Restorff effect, white space, contour bias, Gestalt grouping
- **Interaction & Usability** — Fitts' Law, Hick's Law, affordance, progressive disclosure, feedback loops, consistency, forgiveness, 80/20 rule
- **Information Architecture** — Hierarchy, chunking, inverted pyramid, signal-to-noise ratio, wayfinding, LATCH organization
- **Cognition & Decision-Making** — Mental models, recognition over recall, satisficing, expectation effect, cognitive dissonance
- **Typography & Accessibility** — Legibility, readability, WCAG compliance, redundant coding, icon conventions
- **Layout & Proportion** — Proximity, alignment, golden ratio, rule of thirds, Gutenberg diagram

### Code Reviewer Agent

Automatically checks frontend code for:
- **Visual hierarchy issues**: Competing elements, missing grouping, overcrowded layouts, misalignment
- **Accessibility violations**: Missing labels, color-only indicators, small touch targets, no focus styles
- **Interaction anti-patterns**: Fitts' Law violations, Hick's Law overload, missing feedback, no affordance cues
- **Information architecture problems**: Unchunked lists, buried content, missing wayfinding
- **Consistency gaps**: Non-standard element placement, inconsistent terminology, unintuitive mappings
- **Typography issues**: Small text, bad line lengths, insufficient line height

## File Structure

```
ui-design-principles/
+-- .claude-plugin/
|   +-- plugin.json
+-- skills/
|   +-- ui-design-principles/
|       +-- SKILL.md
|       +-- references/
|           +-- visual-and-layout.md
|           +-- interaction-and-cognition.md
+-- agents/
|   +-- ui-design-reviewer.md
+-- README.md
+-- PRIVACY.md
+-- LICENSE
```

## Source Material

Principles drawn from: Lidwell, W., Holden, K., & Butler, J. — *Universal Principles of Design*, Revised and Updated (Rockport Publishers). Curated and adapted for software UI context.

## License

MIT
