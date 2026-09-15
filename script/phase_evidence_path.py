"""Resolve a phase-evidence path whether its phase directory is live or archived.

`/gsd-complete-milestone` MOVES every phase directory from
`.planning/workstreams/<ws>/phases/<phase>` to
`.planning/workstreams/<ws>/milestones/<version>-phases/<phase>`. A checker that
hardcodes the live path passes for the whole life of a milestone and then breaks,
all at once, the moment that milestone ships.

Resolution prefers the live location and falls back to any archived one. When
neither exists it returns the LIVE path so the caller fails with a missing-file
error naming the location a reader would expect — never a silent "nothing to
check", which would turn absent evidence into a pass.
"""

from __future__ import annotations

import glob
import os

WORKSTREAMS = ".planning/workstreams"


def resolve(workstream: str, phase_relative: str, root: str | os.PathLike = ".") -> str:
    """Return the live path if it exists, else the archived one, else the live path."""
    live = os.path.join(root, WORKSTREAMS, workstream, "phases", phase_relative)
    if os.path.exists(live):
        return live

    pattern = os.path.join(
        root, WORKSTREAMS, workstream, "milestones", "*-phases", phase_relative
    )
    # A phase directory is only ever archived once, so any match is the match;
    # sorting just keeps the choice deterministic.
    matches = sorted(glob.glob(pattern))
    return matches[-1] if matches else live
