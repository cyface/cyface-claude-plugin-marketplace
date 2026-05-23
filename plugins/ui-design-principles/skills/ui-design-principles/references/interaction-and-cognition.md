# Interaction & Cognition Principles

Detailed UI/UX design principles covering interaction design, information architecture, cognition, process, and system design. Drawn from Lidwell, Holden & Butler's *Universal Principles of Design*.

---

## Interaction & Usability

### 80/20 Rule (Pareto Principle)
Roughly 80% of usage comes from 20% of features. Identify the critical 20% and make those interactions as smooth as possible. Deprioritize or hide the rarely-used 80%. Don't give equal visual weight to all features — it creates noise.

### Affordance
The physical or perceived properties of an element that suggest how it should be used. Buttons should look pressable, links should look clickable, drag handles should look grabbable. If users can't tell something is interactive, it doesn't matter how well it works.

### Confirmation
Require verification before destructive or irreversible actions (delete, submit, send). Use dialogs, undo buffers, or two-step processes. Match the friction to the severity — a "are you sure?" dialog for deleting a draft is annoying, but appropriate for deleting an account.

### Consistency
Consistent interfaces are learnable. Use the same patterns, terminology, placement, and behavior across the entire application. Four types matter: aesthetic (visual style), functional (same action = same result), internal (consistent within your app), and external (consistent with platform conventions).

### Constraint
Limit the actions available at any point to prevent errors. Disable buttons when actions aren't valid. Use appropriate input types (date pickers, not free text for dates). Gray out unavailable options rather than hiding them (so users know they exist). Constraints guide users toward correct behavior.

### Control
Users need to feel in control. Let them undo, go back, cancel, pause, and customize. Avoid trapping users in flows they can't escape. Provide clear navigation, breadcrumbs, and exit points. The more control users feel, the more comfortable they are exploring.

### Errors
Design for errors — they will happen. Prevent them where possible (validation, constraints). Detect and surface them clearly when they occur (inline, near the source, in plain language). Make recovery easy (preserve user input, suggest fixes). Never show raw error codes or stack traces.

### Feedback Loop
Every user action should produce visible, immediate feedback. Clicks should animate, submissions should confirm, loading should indicate progress. Positive feedback loops encourage continued use. Without feedback, users don't know if their action registered and will retry or abandon.

### Fitts' Law
The time to reach a target is a function of the target's size and distance. Make frequently-used controls large and close to where the cursor/finger already is. Make destructive actions small and distant from common actions. Touch targets should be at least 44x44 px.

### Flexibility-Usability Tradeoff
As flexibility increases, usability decreases. A tool that does everything is harder to learn than one that does one thing well. When adding customization or options, weigh the cost to the majority of users who won't need them. Progressive disclosure helps manage this tension.

### Forgiveness
Design that helps prevent and recover from errors. Include undo, autosave, input validation, confirmation dialogs, and forgiving input parsing (accept "212-555-1234" and "2125551234"). The more forgiving the interface, the more willing users are to explore.

### Garbage In-Garbage Out
System output quality depends on input quality. Validate and sanitize inputs. Use smart defaults, structured input fields, and clear formatting examples. Guide users toward providing good input rather than accepting anything and producing bad output.

### Hick's Law
Decision time increases with the number and complexity of choices. Minimize options at each decision point. Use progressive disclosure to stage choices rather than presenting everything at once. Categorize and group options when many must be shown.

### Mapping
The relationship between controls and their effects should be intuitive. A slider that moves left-to-right should control values from low-to-high. Vertical scroll should move content vertically. When mapping is natural, no labels are needed. When it's arbitrary, users must memorize the relationship.

### Performance Load
Every task has a cognitive component (thinking) and a kinematic component (physical action). Reduce both. Minimize steps, pre-fill known data, provide intelligent defaults, use autocomplete, and eliminate unnecessary choices. The less effort required, the higher the completion rate.

### Progressive Disclosure
Show only the essential information and controls initially; reveal details and advanced options on demand. This reduces initial complexity while keeping power available. Use expandable sections, "Advanced" toggles, tooltips, and contextual help. Stage information so users get what they need when they need it.

### Visibility
Important controls and information should be visible, not hidden in menus or behind interactions. If users need it frequently, it should be on screen. Prioritize discoverability over cleanliness — a clean interface that hides critical controls is worse than a slightly busier one that shows them.

---

## Information Architecture & Layout

### Advance Organizer
An overview or preview presented before detailed content that helps users build a framework for understanding what follows. Use section headers, table of contents, breadcrumbs, progress indicators, and summary cards. These help users orient before diving into detail.

### Alignment
Visual alignment creates order, organization, and visual connections between elements. Align elements to a consistent grid. Edge alignment (left, right, top) is stronger than center alignment for creating visual relationships. Misalignment — even by a few pixels — creates a sense of sloppiness.

### Chunking
Break information into small, manageable units (typically 4+/-1 items). Apply to navigation menus, form fields, content sections, and data displays. Phone numbers, credit card numbers, and addresses are all chunked for a reason. Long, undifferentiated lists overwhelm working memory.

### Entry Point
The first point of interaction with a design. It must be inviting, clearly communicate purpose, and orient users. Minimize barriers (registration walls, splash screens). Provide clear starting points. First impressions are disproportionately sticky — users who bounce at entry rarely return.

### Five Hat Racks (LATCH)
There are only five ways to organize information: by Location, Alphabet, Time, Category, or Hierarchy. Choose based on the user's task. Time works for feeds and logs. Category for feature organization. Alphabet for reference lookups. Hierarchy for showing importance or structure.

### Gutenberg Diagram
In layouts with evenly distributed content, Western readers follow a Z-pattern: top-left (primary focus) -> top-right -> bottom-left (least attention) -> bottom-right (terminal area). Place the most important elements at the top-left. Place CTAs and next-step actions at the bottom-right.

### Hierarchy
Organize elements to indicate relative importance. Use size, color, contrast, position, and spacing. Every screen should have a clear visual hierarchy that tells users where to look first, second, and third. If everything is emphasized, nothing is.

### Highlighting
Use visual cues to draw attention to specific elements. Bold, color, size, animation, and contrast all work. But highlighting is relative — it only works when used sparingly. If you highlight everything, you highlight nothing. Limit highlighting to the most critical items per view.

### Interference Effects
Competing information or stimuli impair processing and memory. In UI, avoid placing competing calls-to-action next to each other, mixing multiple visual patterns on one screen, or showing new information that conflicts with what the user just learned. Visual and functional interference slows comprehension and increases errors.

### Inverted Pyramid
Present information in order of decreasing importance: conclusion first, then key details, then background. Users scan and may leave at any point. Front-load the most valuable content. Apply to error messages, notifications, onboarding text, and help documentation.

### Layering
Organize information into related groups and present them one layer at a time. Use tabs, accordions, drill-downs, and nested views to manage complexity. Each layer should be self-contained and coherent. Don't force users to hold information from one layer to understand another.

### Redundancy
Use multiple cues to convey the same information. Don't rely solely on color (add icons or text), solely on position (add labels), or solely on shape (add text labels). Redundant coding improves comprehension and accessibility. Error states should combine color + icon + text.

### Signal-to-Noise Ratio
Maximize the ratio of relevant information to irrelevant. Every element on screen should earn its place. Eliminate decorative elements that don't aid comprehension, reduce chrome and visual noise, and simplify data visualizations. Higher signal-to-noise ratio = faster comprehension.

### Wayfinding
Help users understand where they are, where they can go, and how to get back. Use breadcrumbs, navigation highlights, progress indicators, back buttons, and clear page titles. Users should never feel lost. The cost of disorientation is abandonment.

---

## Cognition & Decision-Making

### Cognitive Dissonance
People experience discomfort when their actions conflict with their beliefs or when they encounter contradictory information. In UI, ensure messaging, tone, and behavior are internally consistent. Don't ask users to do things that contradict what you've told them.

### Comparison
People need to compare options to make decisions. Facilitate comparison with side-by-side layouts, comparison tables, and consistent formatting across options. Ensure compared items use the same units, scales, and presentation so differences are easy to spot.

### Cost-Benefit
Users unconsciously weigh the effort of an action against its expected value. Reduce friction (fewer steps, less typing, clearer paths) and increase perceived benefit (clear value propositions, previews of outcomes). If the cost exceeds the benefit, users won't act.

### Expectation Effect
People's experience is influenced by their expectations. If users expect a button to be in the top-right corner, put it there. Follow platform conventions. Violating expectations creates friction even when your solution is objectively better. Innovate on value, not on where the back button goes.

### Exposure Effect (Mere Exposure)
People develop preferences for things they encounter repeatedly. Familiar UI patterns feel more comfortable and trustworthy than novel ones. Use established conventions (hamburger menus, tab bars, search boxes) rather than inventing new ones. Reserve novelty for your core differentiator.

### Framing
The way information is presented affects decisions and judgments. "95% uptime" and "down 18 days/year" are the same fact, presented differently. Frame positive outcomes to encourage action, negative outcomes to create urgency. Be aware of how your copy frames the user's choices.

### Inattentional Blindness
People focused on a task often fail to notice unexpected things, even prominent ones. Don't assume users will see a banner just because it's on screen. Critical information needs to interrupt the user's flow (modals, inline alerts) rather than sitting passively in a corner.

### Mental Model
Users have existing expectations about how things work based on prior experience. Your interface should match these models. If users expect drag-and-drop, provide it. If they expect a settings gear icon, use one. The gap between a user's mental model and your actual model is where confusion lives.

### Nudge
Subtle design choices that guide behavior without restricting options. Default selections, pre-checked options, smart ordering, and visual emphasis all nudge. Use nudges ethically to guide users toward good decisions. Place the recommended option first or make it visually prominent.

### Priming
Exposure to a stimulus influences response to subsequent stimuli. The visual language, imagery, and copy users see before an interaction influences how they interpret it. Onboarding sequences prime expectations. Loading screens can prime patience. Color and imagery prime emotional state.

### Recognition Over Recall
It's easier to recognize something previously encountered than to recall it from memory. Show options rather than requiring users to remember and type them. Use dropdowns, suggestion lists, recent items, and visual thumbnails. Minimize reliance on user memory.

### Satisficing
Users pick the first option that's "good enough" rather than evaluating all options for the best one. Put the best/recommended option first. Don't assume users will scroll through all choices. Design for the satisficer — which is most users, most of the time.

### Scarcity
Limited availability increases perceived value. "3 seats remaining" or "offer expires in 24h" creates urgency. Use ethically and honestly. Artificial scarcity erodes trust. Real scarcity (rate limits, capacity) should be communicated clearly so users understand constraints.

### Serial Position Effects
People remember items at the beginning (primacy) and end (recency) of a list better than those in the middle. Place the most important navigation items at the start and end of menus. In onboarding flows, the first and last steps leave the strongest impressions.

---

## Process & Strategy

### Design by Committee
Group decision-making leads to watered-down, incoherent designs that try to please everyone. Strong design requires a clear decision-maker. Seek input broadly, but vest design authority in a small group or individual. Consensus-driven design produces mediocrity.

### Desire Line
Observe how users actually behave rather than how you designed them to behave. Analytics, heatmaps, and user testing reveal "desire lines" — the paths users actually take. Adapt your design to support the desire lines rather than fighting them.

### Iteration
Good design emerges through cycles of prototyping, testing, and refinement — not from getting it right the first time. Plan for multiple rounds of revision. Test early with low-fidelity prototypes. Each iteration should be informed by observation of real user behavior.

### Most Advanced Yet Acceptable (MAYA)
The most successful designs push boundaries while remaining recognizable and comfortable. Too innovative = rejected as confusing. Too familiar = ignored as boring. Find the sweet spot: innovate on one dimension while keeping everything else conventional.

### Personas
Archetypal users based on research, used to guide design decisions. Good personas capture goals, frustrations, and context — not just demographics. Design for your personas' tasks and mental models. When debating a feature, ask "what would [persona] need here?"

### Prototyping
Build rough versions to test ideas before investing in full implementation. Paper sketches, wireframes, and clickable mockups all count. The goal is to fail fast and cheap. Prototype the riskiest assumptions first.

---

## System Design

### Factor of Safety
Design systems to handle more stress than expected. Apply to server capacity, form validation, timeout durations, and error handling. If you expect 1000 concurrent users, design for 2000. If a field should hold 100 characters, don't break at 101.

### Modularity
Build interfaces from independent, interchangeable components. Modular design enables reuse, easier testing, and flexible composition. Aligns directly with component-based UI frameworks (React, Vue, etc.). Each module should have a single responsibility and a clear interface.

### Ockham's Razor
Given competing designs that solve the same problem, prefer the simplest one. Don't add features, options, or visual elements unless they serve a clear purpose. Complexity is a cost — every addition must justify itself. When in doubt, leave it out.

### Weakest Link
A system is only as strong as its weakest component. Your beautiful dashboard is useless if the login flow is broken. Identify and strengthen the weakest points in user flows. Common weak links: error states, empty states, loading states, edge cases, and mobile layouts.

---

*Source: Lidwell, W., Holden, K., & Butler, J. — Universal Principles of Design, Revised and Updated (Rockport Publishers). Curated and adapted for software UI context.*
