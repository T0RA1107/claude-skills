"""<Entry point one-line description>."""
import sys
from pathlib import Path

# Add project root to Python path so `src.` imports resolve when run as a script.
sys.path.append(str(Path(__file__).resolve().parents[1]))

import hydra
from loguru import logger
from omegaconf import DictConfig
from pyinstrument import Profiler

from src.utils.logger import init_logger


class <Entrypoint>Runner:
    """Orchestrates the <entrypoint> procedure."""

    def __init__(self, cfg: DictConfig):
        """Initialize from the resolved Hydra config.

        Args:
            cfg: Hydra configuration
        """
        # Components are built from config — no if/else dispatch on names.
        logger.info(f"Initializing <group>: {cfg.<group>._target_}")
        self.<group> = hydra.utils.instantiate(cfg.<group>)

        self.run_dir = Path(cfg.path.run_dir)
        self.ckpt_dir = self.run_dir / cfg.path.ckpt_dir
        self.ckpt_dir.mkdir(parents=True, exist_ok=True)

    def run(self) -> None:
        """Run the main loop."""
        raise NotImplementedError


@hydra.main(version_base=None, config_path="../configs", config_name="<entrypoint>")
# reraise=True is required: without it loguru swallows the exception and the
# process exits 0, so a crashed run (or a whole multirun sweep) reports success.
@logger.catch(reraise=True)
def main(cfg: DictConfig):
    """Main entry point.

    Args:
        cfg: Hydra configuration
    """
    init_logger(cfg)

    if cfg.profile:
        profiler = Profiler()
        profiler.start()

    runner = <Entrypoint>Runner(cfg)
    runner.run()

    if cfg.profile:
        profiler.stop()
        profiler.print()
        output_path = Path(cfg.path.run_dir) / "profiling_report.html"
        output_path.write_text(profiler.output_html())


if __name__ == "__main__":
    main()
