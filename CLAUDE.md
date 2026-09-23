# SwiftMotion Lab

A single-purpose demo repo driven live in front of an audience on a fixed time budget.

## Don't read README.md / readme.md

The handout (`readme.md` on disk, referred to as `README.md`) is the participant lab
handout. It contains step-by-step solutions to the exercises this repo is built around, so
reading it defeats the exercise and wastes your context. Don't open it, and don't take
architecture from it. `docs/` holds screenshots for that handout.

Every source file opens with a comment stating what it is for, and types and properties
carry their own documentation. That is the architecture reference — read the code.

## Exercise map

Adding an animation style touches exactly two files: `Models/DeliveryAnimator.swift` and
`Models/HouseAnimator.swift` — a case on the style enum (`title`, `description`,
`parameters`) plus the matching `animation` / `playDuration` / `contactDelay` branches.
`TuningValues.swift` already holds every tunable, including spring-timing helpers
(`tuning.spring`, `Spring.timeToFirstReachingTarget`); `ControlPanelView` generates its
sliders from `parameters` alone. Do not modify `TuningValues.swift`, `ControlPanelView.swift`,
or `MotionLabViewModel.swift` for this kind of change.

## Live-demo rule: implement and compile, don't run

During the timed live demo: write the code, then verify it compiles with one
`BuildProject` — nothing else.

Do **not** run the app, do **not** render previews, and do **not** look anything up: no
`RunProject`, no `RenderPreview`, no device-interaction skill, no verification subagents,
no `DocumentationSearch`, no `RunCodeSnippet`, no `RunAllTests` (the last three are also
denied in `.claude/settings.json` — this is why). A cold preview render alone can cost over
3 minutes, and a documentation search or a code-snippet run each cost a full round trip the
fixed demo time budget doesn't have. The presenter checks the result on screen during the
timed segment — that is the demo.

This restriction is scoped to the timed segment, not a blanket rule. Outside it — a
participant working the lab solo, or anyone explicitly asking for the app to be run or
validated — the default "Validating your work" guidance applies normally. If asked to run
or validate, do it.

Work economically even inside the restriction: read every file you need in one parallel
batch rather than discovering them one at a time; make one `Edit` per file, not one per
change site; if you need a deferred tool's schema, load every one you'll need in a single
`ToolSearch` call (`select:ToolA,ToolB`) rather than one call each.

## The animation APIs here are not new

Established (iOS 17+); no documentation lookup needed:

- `Animation.interpolatingSpring(mass:stiffness:damping:initialVelocity:)`
- `Animation.linear(duration:)`, `.easeInOut(duration:)`, `.bouncy(duration:extraBounce:)`
- `Spring(mass:stiffness:damping:)` and its `settlingDuration` — how a spring reports the
  time it takes to come to rest, since it is never given a duration

## Paths

Every prompt is preceded by a hook listing the project's files in **Xcode workspace
form**, e.g. `SwiftMotionLab/SwiftMotionLab/Models/HouseAnimator.swift`. Its leading
`SwiftMotionLab/` names the *Xcode project container*, not a real directory — the repo can
be cloned anywhere, under any root directory name, so never hardcode a path here or infer
one from where you happen to find the repo this session.

Two different tool families want two different forms, derived from that same hook line —
mixing them up is the most common wasted round trip in this repo:

- **`XcodeRead` / `XcodeRefreshCodeIssuesInFile` / `XcodeGlob` / `XcodeGrep`** — use the
  hook's path **verbatim** (e.g. `SwiftMotionLab/SwiftMotionLab/Models/HouseAnimator.swift`).
  Passing these an absolute path fails with "File not found in project structure" even
  though the file exists — don't retry with a different absolute path, switch to this form.
- **`Read` / `Edit`** — take the hook's path and **strip exactly one leading
  `SwiftMotionLab/`** (e.g. `SwiftMotionLab/Models/HouseAnimator.swift`), then resolve that
  against your working directory. Prefer `Edit` with this resolved path for targeted
  changes; reserve `XcodeWrite` for new files or genuine whole-file rewrites. If an absolute
  `Read` ever fails, don't retry it verbatim — re-derive it this way instead. The working
  directory may contain spaces, so quote it in any shell command.

## Comments on code you add

Leave a single-line `// MARK: <Concept>` at each site you change — one line, no prose
paragraphs — so the change sites are reviewable from Xcode's jump bar. Write ordinary
documentation everywhere else: describe what something is and why, never steps for a
reader to follow.
