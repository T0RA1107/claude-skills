import sys

from loguru import logger
from omegaconf import DictConfig


def init_logger(cfg: DictConfig):
    """Send loguru output to the console and to the Hydra run directory.

    Args:
        cfg: Hydra configuration containing the `logger` group
    """
    logging_cfg = cfg.logger
    fmt = logging_cfg.formatters.loguru.format
    level = logging_cfg.root.level

    logger.remove()
    # Console sink — keep it, or a failing run prints nothing at all.
    # Colour markup in `fmt` renders here and is stripped in the file sink.
    logger.add(sys.stderr, backtrace=True, format=fmt, level=level)
    logger.add(logging_cfg.filename, backtrace=True, format=fmt, level=level)
