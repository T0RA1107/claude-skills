# scripts/<entrypoint>_<variant>_<variant>.sh
#
# A script records WHICH CONFIG COMBINATION was run — nothing else.
# No loops (use Hydra multirun: -m seed=1,2,3), no branching (write a second script),
# no path building / aggregation / inline python (that is essential code -> src/).
#
# <RUN> is the project's runner: `uv run`, `pixi run python`, plain `python`, ...
<RUN> ./src/<entrypoint>.py \
  <group>=<variant> \
  <sibling>=<variant> \
  <entrypoint>.<param>=<value> \
  wandb.enabled=false \
  "$@"   # forward ad-hoc overrides from the command line
