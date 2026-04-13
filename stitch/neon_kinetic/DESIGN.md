# Design System Strategy: The Kinetic Lens

## 1. Overview & Creative North Star
The North Star for this design system is **"The Kinetic Lens."** 

In an industry saturated with static, boxy fitness apps, this system treats the interface as a living, breathing high-performance engine. We move beyond "standard" dark mode by utilizing deep tonal depth and glassmorphism to create a sense of infinite space. By rejecting rigid lines in favor of **Tonal Layering** and **Asymmetric Balance**, we mirror the organic yet precise nature of human movement. 

The goal is an editorial-grade experience that feels like a premium sports car dashboard—high-tech, energetic, and intensely focused. We achieve this by contrasting ultra-wide `Space Grotesk` display type with the functional precision of `Manrope`.

## 2. Colors & Surface Architecture
The palette is rooted in the "Deep Sea" navy of the background, punctuated by high-vibrancy "Performance Neon" accents.

### The "No-Line" Rule
**Strict Mandate:** Designers are prohibited from using 1px solid borders for sectioning or containment. Boundaries must be defined through background color shifts or tonal transitions. To separate a workout module from the feed, place a `surface-container-low` element on the `surface` background. The eye should perceive change through depth, not strokes.

### Surface Hierarchy & Nesting
Treat the UI as a series of nested physical layers. 
- **Base Layer:** `surface` (#12121d) for the primary application background.
- **Sectioning:** Use `surface-container-low` to define large content areas.
- **Interactive Elements:** Use `surface-container-high` or `highest` for cards and interactive components to bring them closer to the user’s eye.
- **Nesting:** A `surface-container-lowest` card placed inside a `surface-container-low` section creates a "sunken" utility feel, perfect for secondary data like step counts.

### The "Glass & Gradient" Rule
To capture the "AI-Powered" energy, floating elements (modals, navigation bars) must utilize **Glassmorphism**:
- **Fill:** `surface-variant` at 40%–60% opacity.
- **Effect:** Background blur at 20px–40px.
- **Signature Glow:** Main CTAs should not be flat. Apply a linear gradient from `primary` (#c4c0ff) to `primary-container` (#8781ff) at a 135-degree angle to provide "visual soul."

## 3. Typography: The Editorial Edge
The type system creates a rhythmic contrast between "The Athlete" (Display) and "The Data" (Body).

*   **Display & Headlines (`Space Grotesk`):** These are your "shout" moments. Use `display-lg` for daily goal achievements. The wide stance of Space Grotesk feels high-tech and aggressive. Use tight letter-spacing (-2%) for headlines to maintain a compact, premium feel.
*   **Body & Labels (`Manrope`):** Used for all functional data. Manrope’s geometric clarity ensures readability during high-intensity movement.
*   **Hierarchy Tip:** Never pair two bold weights of different sizes. If the headline is `headline-lg` (Bold), the supporting text should be `body-md` (Regular) to ensure the editorial "breathing room" required for a premium feel.

## 4. Elevation & Depth: Tonal Layering
We do not use drop shadows to indicate "elevation" in the traditional sense. We use **Luminance Stacking.**

*   **The Layering Principle:** Higher importance = Higher Luminance. As an object "rises" toward the user, its surface color moves from `surface-dim` toward `surface-bright`.
*   **Ambient Shadows:** When an element must float (e.g., a "Start Workout" FAB), use a tinted shadow. Instead of black, use `on-primary` at 8% opacity with a 32px blur. This creates a "glow" rather than a "shadow," fitting the energetic theme.
*   **The "Ghost Border" Fallback:** For accessibility in complex data grids, you may use a border. It must be the `outline-variant` token at **20% opacity max**. This "Ghost Border" provides a hint of structure without breaking the fluid glass aesthetic.
*   **Glassmorphism Depth:** Elements using backdrop-blur should be reserved for the highest level of the Z-index (Global Nav, Pop-overs). This allows the energetic primary gradients of the background to bleed through, softening the UI.

## 5. Components

### Buttons: The "Power" Component
*   **Primary:** Gradient fill (`primary` to `primary-container`). 16px (`xl`) rounded corners. No border. White text (`on-primary`).
*   **Secondary:** Glass-filled (`surface-variant` at 20% opacity) with a "Ghost Border" of `primary` at 30% opacity. 
*   **Tertiary:** Text-only using `tertiary` (#3ae275) for positive actions (e.g., "Complete Workout").

### Cards & Lists: The "No-Divider" Rule
*   **Cards:** Use `lg` (16px) corner radius. Separate cards using `1rem` to `1.5rem` of vertical whitespace. 
*   **Lists:** Forbid the use of 1px divider lines. Separate list items by alternating between `surface-container-low` and `surface-container-lowest`, or simply use generous padding to let the typography define the break.

### Progress Gauges (Signature Component)
Given the fitness context, progress bars should utilize the `secondary` (Coral) to `tertiary` (Green) spectrum. Use a 4px thickness with a subtle outer glow (blur: 8px) of the same color to simulate a neon fiber-optic cable.

### Inputs
*   **Fields:** Use `surface-container-highest` with a 16px radius. The "Active" state should not be a thicker border, but an increase in the "Ghost Border" opacity to 40% and a subtle `primary` glow.

## 6. Do's and Don'ts

### Do:
*   **Do** use intentional asymmetry. Shift a headline 8px to the left of the body text to create an editorial, "non-template" look.
*   **Do** use `tertiary` (#3ae275) for all "Growth" or "Success" metrics.
*   **Do** utilize large amounts of "Negative Space" (minimum 24px gutters) to allow the deep navy background to "breathe."

### Don't:
*   **Don't** use pure black (#000000). It kills the depth of the glassmorphism. Always use `surface` or `background` tokens.
*   **Don't** use 100% opaque borders. They create "visual noise" that distracts from the biometric data.
*   **Don't** stack more than three levels of surface nesting. If you need a fourth level, use a gradient shift instead of a solid color change.
*   **Don't** use standard "Material Design" blue for links. Use `primary` (#c4c0ff) to maintain the "Kinetic Lens" identity.