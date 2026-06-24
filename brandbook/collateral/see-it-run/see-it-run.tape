# vhs tape — renders see-it-run.gif for the "See It Run" collateral.
# https://github.com/charmbracelet/vhs
#
# Honest + deterministic recording of the one-command launcher:
#   terminal -> bin/see-it-run.sh -> brand banner (URL, routes, next commands).
#
# Driven by .github/workflows/see-it-run-collateral.yml, which first boots the
# shared backend on :4700 so the launcher's reuse probe short-circuits
# ("Port 4700 is already serving — reusing it.") and prints the banner without
# needing Docker. --web-only --no-open keep the cast headless and deterministic
# (no native toolchain, no browser auto-open). Regenerate locally with:
#
#   cd examples/phoenix_host && PORT=4700 mix phx.server &   # or bin/see-it-run.sh
#   vhs brandbook/collateral/see-it-run/see-it-run.tape
#   gifsicle -O3 --colors 128 -o brandbook/collateral/see-it-run/see-it-run.gif \
#     brandbook/collateral/see-it-run/see-it-run.gif

Output brandbook/collateral/see-it-run/see-it-run.gif

Require bash

Set Shell "bash"
Set FontSize 14
Set Width 960
Set Height 720
Set Padding 18
Set Framerate 12
Set PlaybackSpeed 1.0

Sleep 700ms
Type "bin/see-it-run.sh --web-only --no-open"
Sleep 600ms
Enter

# Let the reuse probe + full brand banner render before the GIF ends.
Sleep 6s
