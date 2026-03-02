# AGENTS

These instructions apply to the `neoxp_haibao` workspace (Electron desktop app).

## Product Intent

- This app is a non-linear workbench, not a wizard.
- Users should be able to configure all required settings in parallel, then click one run entry.
- UI should feel like a mature desktop tool (VSCode-like dark style), not a web form page.

## Layout and Interaction Rules

- Keep the in-window layout edge-to-edge. Do not add decorative outer padding.
- Default startup window baseline is `1080 x 620`.
- Adaptive row-density thresholds must be practical:
  - 1-column/1-item-per-row layout is reserved for very narrow widths only.
  - Baseline desktop widths should usually allow 2/3/4 items per row where controls are short enough.
  - Avoid over-conservative breakpoints that force single-column layout at normal widths.
- Use a merged custom top bar (title + menu + window controls), VSCode-like:
  - Left: app mark + top menus.
  - Right: minimize / maximize-restore / close controls.
  - No extra second-row in-window menu.
- Bottom strip is a single-line status/help area:
  - Show contextual help when hovering controls.
  - Show status text when idle.
  - Do not prefix with labels like `Status:` or `Help:`.
- Pane boundaries are line-based and draggable.
- File pane, settings pane, and log pane support collapse-to-bar behavior:
  - Collapsed header text uses rotated horizontal text, not vertical writing mode.
  - Double-click bar or divider restores collapsed pane.
  - Dragging from collapsed bar should restore smoothly when crossing restore threshold.
- Auto-collapse should be conservative:
  - Trigger only when window is genuinely narrow.
  - If user manually re-expands while window is still narrow, keep it expanded until window width returns to a normal range.
- Resize behavior must be stable:
  - No flicker around collapse thresholds.
  - No horizontal overflow on initial render.
  - Maximize/restore/resize must keep all panes usable.
- Collapse priority for outer panes:
  - Narrow width first collapses file pane.
  - Further narrowing then collapses log pane.
  - Keep at least one outer pane expanded at all times.
- Custom top menu behavior should match desktop norms:
  - Hover highlights the selectable area (text color should stay neutral).
  - If one top menu is already open, moving over another top menu switches the open popup immediately.
- Window control hover behavior:
  - Minimize/maximize/close controls use square hover regions (no rounded corners).
  - Close control hover/focus/pressed must use red background.
  - Top-bar text/icon foreground should stay stable; state feedback is mainly via background.
- Multi-action button rows should default to right alignment:
  - Keep command clusters visually anchored to the right edge of their section.
  - This includes file import command rows such as `Open` / `Read`.
  - On very narrow widths, wrapping is allowed, but alignment should remain right-biased.

## Technical Rules

- Language: TypeScript + React renderer, Electron main/preload.
- Build i18n on day one:
  - All user-facing text must come from translation keys.
  - Keep `zh-CN` complete and authoritative first.
  - Add new languages by adding catalogs, not hardcoding strings in logic.
- Use Fluent UI components for controls unless there is a clear reason not to.
- Use Fluent UI icon components for status markers and menu icons whenever possible.
- Prefer Fluent UI controls for both editable and read-only surfaces:
  - Use `Combobox` + `Option` instead of native `<select>` for dropdowns that must follow pane theme colors.
  - Prefer Fluent `Textarea` for read-only multiline content (for example path/log panes) instead of custom `div` text blocks.
- Keep layout math deterministic and clamp pane widths.
- Use hysteresis thresholds for collapse/restore (separate values) to avoid oscillation.
- Keep user-select disabled for non-editable UI regions; allow normal text selection in editable inputs.
- Window control buttons must stay Fluent-based:
  - Use Fluent `Button` + Fluent icons.
  - Maximize button icon must switch by real window state (`maximize` vs `restore`).
  - State should sync through IPC events from Electron main process.
- Collapse animation behavior must be shared:
  - Outer panes and inner collapsible sections use one common motion pattern and state model.
  - Both collapse and expand must animate (not expand-only).
  - During active drag-resize, collapse animations should be temporarily disabled to avoid flicker.
- Keep a visible but subtle window boundary line in all four edges across normal/maximized states.
- Text/menu interactions should remain keyboard-friendly and accessible (`focus-visible`, `aria-expanded` states must remain styled and usable).

## Theme and Color Baseline

- Pane colorization must be token-driven and scalable:
  - Each pane root uses `className=\"pane\"` and `data-pane-tone=\"files|settings|logs\"`.
  - Pane accent derives from tone and must flow to Fluent tokens (focus stroke, brand stroke/background, hover/pressed states).
  - New controls added inside a pane should inherit pane accent without control-specific hardcoded color classes.
- Keep visual hierarchy consistent in dark mode:
  - App/workspace/pane/status backgrounds use layered dark neutrals.
  - Active pane highlight is subtle and uses the same pane accent family.
  - Dividers and borders remain visible but low-noise.
- Avoid one-off per-button color overrides unless a control is intentionally semantic (for example destructive).

## Operation Pane Rules

- Operation pane is organized as collapsible drawers, and each drawer can contain one or more boxed subgroups.
- The boxed subgroup container is not decorative only; it is the primary structure for logical parameter grouping.
- Drawer top descriptions should stay concise and purpose-focused:
  - Avoid long "purpose + step-by-step + notes" paragraphs at the top of each drawer.
  - Put detailed guidance near the specific control it explains.
- Responsive layout should support:
  - narrow width: vertical stacking inside subgroup boxes,
  - wider width: compact multi-column layout where safe.
- Action sections that require explicit apply must use a drawer-level bottom toolbar:
  - files,
  - cell ROI,
  - data,
  - debug.
- For these apply-enabled drawers:
  - place the Apply button at the far right of the drawer toolbar,
  - keep subgroup content scrollable while the drawer toolbar stays anchored at drawer bottom.
- Drawers not listed above should not expose a redundant apply button.
- Numeric inputs should use Fluent spin-button style interactions (increment/decrement) where applicable.
- Dropdown/list popups must not be clipped by parent containers; overlays should render above pane content.
- Discrete mode choices should use segmented clickable controls when applicable:
  - Prefer Fluent segmented interactions (`TabList`/`Tab`) for small fixed option sets (for example strictness levels, exclusion polarity).
  - Do not use sliders for discrete categorical choices.
- Keep control accent synchronization complete:
  - if a Fluent control supports themed accent tokens, bind them to the current pane tone.
  - this includes checkboxes, radios, switches, progress, combobox/list options, focus rings, and hover/pressed states.
- Keep exception rule:
  - switches and circular options may keep rounded Fluent default shape,
  - most other controls stay square-cornered to match the desktop style.
- Important bright action buttons should use dark foreground text for contrast consistency.
- ROI state visualization must be consistent:
  - Use one icon mapping everywhere (table/list cells and related context menu items).
  - Use colored Fluent icons for the three ROI states (`native`, `auto`, `none`).
  - Do not use plain text symbols such as `●`, `▲`, `X` as final UI markers.
  - Context menus should keep icon-column alignment for all items.
  - If a specific item intentionally has no icon (for example `Learn fluorescence ROI`), keep an empty icon slot for alignment.

## Run and Verify

From `neoxp_haibao`:

1. `npm install`
2. `npm run typecheck`
3. `npm run build`
4. `npm run dev:ps:fast`

Manual verification checklist:

1. Initial window: no right-side overflow.
2. Drag left and center dividers repeatedly: no flicker.
3. Collapse pane, keep mouse down, continue drag, restore pane: stable.
4. Narrow window until file pane auto-collapses; manually reopen while narrow; it stays open.
5. Widen window back; auto-collapse state resets correctly.
6. In each pane, focused input/combobox/border accents match that pane tone.
7. Combobox popup list (`Option` hover/selected/focus) follows the current pane tone.
8. Log pane controls and log surface follow log-tone colors.
9. Top bar menu item hover shows background highlight without blue text shift.
10. Open one top menu, then move pointer over another top menu: popup switches immediately.
11. Middle window button icon toggles correctly between maximize and restore shapes.
12. Window controls have square hover blocks; close button turns red on hover.
13. Outer pane collapse and expand both show visible motion, matching inner section behavior.
14. At baseline window size, major operation subgroups are not forced into single-column unless necessary.
15. Right-aligned button rows remain right-biased across widths, including `Open` / `Read`.
16. ROI state icons are Fluent-based and consistent between list cells and context menus.
17. Strictness and exclusion mode use segmented click controls (not sliders) with clear selected state.
