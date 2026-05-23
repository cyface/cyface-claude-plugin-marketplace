# Visual & Layout Principles

Detailed UI/UX design principles covering visual perception, typography, accessibility, and layout proportions. Drawn from Lidwell, Holden & Butler's *Universal Principles of Design*.

---

## Perception & Visual Processing

### Aesthetic-Usability Effect
Attractive designs are perceived as easier to use than ugly ones, regardless of actual usability. Users are more tolerant of minor usability issues in visually appealing interfaces. Invest in visual polish — it buys you forgiveness on rough edges and increases perceived credibility.

### Closure
People perceptually complete incomplete shapes and patterns. In UI, this means you don't need to draw every border or fully enclose every element — users will fill in gaps. Useful for card layouts, icon design, and reducing visual clutter while maintaining clear grouping.

### Color
Color can attract attention, convey meaning, group elements, and indicate state. Use a limited, intentional palette. Remember: ~8% of men have color vision deficiency, so never rely on color alone to convey critical information. Use color consistently — same meaning across the entire interface.

### Common Fate
Elements that move together or change together are perceived as a group — even if they're visually dissimilar or far apart. In UI, use coordinated animations, synchronized state changes, and parallel transitions to signal that elements are related. A loading skeleton that animates in unison feels like one coherent unit.

### Contour Bias
People prefer and react faster to objects with curved/organic contours over sharp-angled ones. Sharp angles trigger threat-detection responses. Prefer rounded corners on buttons, cards, and containers. Use angular shapes intentionally to signal warnings or urgency.

### Figure-Ground Relationship
People instinctively separate visual fields into a foreground figure and background. Use contrast, shadow, and layering to make interactive elements "pop" forward from the background. Modals, dropdowns, and popovers all rely on this principle. Ambiguous figure-ground relationships cause confusion.

### Good Continuation
The eye follows smooth, continuous paths rather than abrupt changes. Align elements along clear visual lines. If elements are arranged along a path, users will perceive them as related. Useful for form layouts, step indicators, and navigation flows.

### Horror Vacui
The fear of empty space — the tendency to fill every available area with detail. In UI design, resist this. White space is not wasted space; it improves comprehension, reduces cognitive load, and creates visual hierarchy. More sophisticated audiences tend to prefer less cluttered designs.

### Law of Pragnanz
People interpret complex images in the simplest way possible. Design your UI so the simplest interpretation is the correct one. If users have to think hard about what they're looking at, the design is failing. Reduce visual complexity; favor simple, clear shapes and layouts.

### Orientation Sensitivity
People are better at distinguishing elements that differ in orientation (horizontal vs. vertical vs. diagonal). Use orientation changes to differentiate sections, separate navigation from content, or create visual contrast between element types.

### Similarity
Elements that look alike (same color, shape, size, or style) are perceived as belonging together. Use consistent visual treatment to group related controls, and differentiate unrelated ones. This is a core Gestalt principle — one of the most powerful tools for visual organization.

### Symmetry
Symmetrical compositions feel balanced, stable, and orderly. Asymmetry creates dynamism and visual interest but can feel unstable. Use symmetry for layouts that need to feel calm and trustworthy (dashboards, forms). Use asymmetry for layouts that need energy (marketing pages, CTAs).

### Uniform Connectedness
Elements that are visually connected (by lines, boxes, shared backgrounds, or shared borders) are perceived as more related than elements that are merely close together. This is often stronger than proximity alone. Use cards, containers, dividers, and shared background colors to create explicit groupings.

### von Restorff Effect (Isolation Effect)
An item that stands out from its surroundings is more likely to be noticed and remembered. Make primary CTAs visually distinct from secondary actions. Use color, size, or weight contrast to highlight the one thing you want users to notice on each screen.

---

## Typography & Readability

### Legibility
The degree to which individual characters can be distinguished. Use typefaces designed for screen reading. Maintain adequate size (16px+ for body text), contrast (WCAG AA minimum), and spacing. Avoid decorative fonts for body text. Sans-serif generally performs better on screen.

### Readability
The ease with which text can be read and understood (distinct from legibility, which is about character recognition). Short paragraphs, clear headings, simple vocabulary, and adequate line height (1.4–1.6x) all improve readability. Aim for a line length of 45–75 characters.

---

## Accessibility & Inclusion

### Accessibility
Design should be usable by people with the widest range of abilities, operating within the widest range of situations. This means keyboard navigation, screen reader support, sufficient color contrast, text alternatives for images, and focus management. Accessibility isn't an add-on — it's a baseline requirement.

### Iconic Representation
Icons should be recognizable and unambiguous. Use established conventions (trash can = delete, gear = settings, magnifying glass = search). When icons are ambiguous, pair them with text labels. Test icon comprehension — what's obvious to designers is often unclear to users.

### Picture Superiority Effect
Images are remembered and processed faster than text. Use imagery to reinforce key messages, illustrate concepts, and create emotional connections. But use purposefully — decorative images that don't support comprehension add noise without signal.

---

## Layout & Proportion

### Golden Ratio (1:1.618)
This ratio appears throughout nature and is associated with aesthetic appeal. Apply to layout proportions (sidebar:main content), image cropping, and spacing relationships. Not a magic bullet, but useful as a starting proportion when you need a ratio that "just feels right."

### Proximity
Elements placed close together are perceived as related. Group related controls, labels with their fields, and actions with their context. Increase spacing between unrelated groups. Proximity is the simplest and most powerful layout tool for conveying relationships.

### Rule of Thirds
Divide a layout into a 3x3 grid; place key elements along the grid lines or at intersections for a more dynamic, visually engaging composition. More natural than centering everything. Useful for hero sections, image placement, and asymmetric layouts.

### Self-Similarity
Components that share visual patterns at different scales create a sense of coherence. A design system's consistency across atoms (buttons), molecules (form groups), and organisms (page sections) is self-similarity in action. It makes complex interfaces feel unified.

---

*Source: Lidwell, W., Holden, K., & Butler, J. — Universal Principles of Design, Revised and Updated (Rockport Publishers). Curated and adapted for software UI context.*
