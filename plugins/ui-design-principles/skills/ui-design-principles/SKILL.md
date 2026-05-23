---
name: UI Design Principles
description: >-
  This skill should be used when the user asks about "UI design", "UX design",
  "design principles", "usability", "visual hierarchy", "layout principles",
  "accessibility design", "Fitts' Law", "Hick's Law", "cognitive load",
  "information architecture", "visual design", "interaction design",
  "affordance", "progressive disclosure", "Gestalt principles",
  "color theory", "typography", "readability", "legibility",
  "golden ratio", "rule of thirds", "proximity", "alignment",
  "figure-ground", "signal-to-noise ratio", "mental model",
  "design review", "UI review", "design patterns",
  or mentions improving the visual design, layout, or usability of an interface.
version: 1.0.0
---

# UI Design Principles Reference

A curated reference for software/web UI design, drawn from Lidwell, Holden & Butler's *Universal Principles of Design*. Only principles directly applicable to UI/UX work are included.

## Visual Perception

- **Aesthetic-Usability Effect** — Attractive designs are perceived as easier to use. Visual polish buys forgiveness on rough edges.
- **Figure-Ground** — Use contrast, shadow, and layering to make interactive elements pop forward. Ambiguous layering causes confusion.
- **Similarity & Uniform Connectedness** — Elements that look alike or are visually connected are perceived as related. Use consistent styling to group, and containers/dividers for explicit grouping.
- **von Restorff Effect** — An item that stands out is more likely to be noticed. Make primary CTAs visually distinct from secondary actions.
- **Horror Vacui** — Resist filling every space. White space improves comprehension, reduces cognitive load, and creates hierarchy.
- **Law of Pragnanz** — People interpret complex images in the simplest way possible. If users have to think hard about what they see, the design is failing.
- **Contour Bias** — Prefer rounded corners on buttons and cards. Sharp angles trigger threat-detection responses.

## Interaction & Usability

- **Fitts' Law** — Target acquisition time depends on size and distance. Make frequent controls large and close. Touch targets: at least 44x44 px.
- **Hick's Law** — Decision time increases with the number of choices. Minimize options at each decision point. Use progressive disclosure.
- **Affordance** — Elements must visually suggest how they're used. Buttons look pressable, links look clickable, drag handles look grabbable.
- **Progressive Disclosure** — Show essentials first, reveal details on demand. Reduces initial complexity while keeping power available.
- **Feedback Loop** — Every action needs visible, immediate feedback. Without it, users retry or abandon.
- **Consistency** — Same patterns, terminology, placement, and behavior across the entire application. Aesthetic, functional, internal, and external consistency all matter.
- **Forgiveness** — Include undo, autosave, validation, and forgiving input parsing. The more forgiving, the more willing users are to explore.
- **80/20 Rule** — 80% of usage comes from 20% of features. Prioritize the critical 20%.

## Information Architecture

- **Hierarchy** — Every screen needs a clear visual hierarchy: where to look first, second, third. If everything is emphasized, nothing is.
- **Chunking** — Break information into 4 plus or minus 1 items. Apply to menus, forms, and data displays.
- **Inverted Pyramid** — Present information in decreasing importance. Users scan and may leave at any point.
- **Signal-to-Noise Ratio** — Every element must earn its place. Eliminate decorative elements that don't aid comprehension.
- **Wayfinding** — Breadcrumbs, navigation highlights, progress indicators, back buttons, clear page titles. Users should never feel lost.
- **Five Hat Racks (LATCH)** — Only five ways to organize: Location, Alphabet, Time, Category, Hierarchy. Choose based on user task.

## Cognition & Decision-Making

- **Mental Model** — Match users' existing expectations. The gap between their model and yours is where confusion lives.
- **Recognition Over Recall** — Show options rather than requiring users to remember. Use dropdowns, suggestions, recent items.
- **Satisficing** — Users pick the first "good enough" option. Put the best option first.
- **Expectation Effect** — Follow platform conventions. Violating expectations creates friction even when your solution is objectively better.
- **Cognitive Dissonance** — Ensure messaging, tone, and behavior are internally consistent.

## Typography & Accessibility

- **Legibility** — 16px+ body text, WCAG AA contrast minimum, sans-serif for screen.
- **Readability** — Short paragraphs, clear headings, line height 1.4-1.6x, line length 45-75 characters.
- **Accessibility** — Keyboard navigation, screen reader support, color contrast, text alternatives, focus management. Not an add-on — a baseline.
- **Redundancy** — Never rely on a single cue. Error states should combine color + icon + text.
- **Iconic Representation** — Use established icon conventions. When ambiguous, pair with text labels.

## Layout & Proportion

- **Proximity** — Elements placed close together are perceived as related. The simplest and most powerful layout tool.
- **Alignment** — Align to a consistent grid. Misalignment — even by pixels — creates a sense of sloppiness.
- **Golden Ratio (1:1.618)** — Useful starting proportion for sidebar:content ratios and spacing relationships.
- **Rule of Thirds** — Place key elements along grid lines for more dynamic, engaging compositions.
- **Gutenberg Diagram** — Western readers follow a Z-pattern. Important elements top-left, CTAs bottom-right.

## Additional Resources

For complete principle descriptions with detailed explanations:

- [Visual & Layout Principles](references/visual-and-layout.md) — Perception, typography, readability, accessibility, layout proportions
- [Interaction & Cognition Principles](references/interaction-and-cognition.md) — Usability, information architecture, cognition, process, system design
