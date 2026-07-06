# Example: HandX

Per-subdirectory style: the parent dirs (`diffusion/body_models/`, `data/`) stay real
directories; only the heavy children are symlinked.

## Link structure
```
/home/aolab/Desktop/HandX/diffusion/body_models/mano -> /data/HandX/diffusion/body_models/mano
/home/aolab/Desktop/HandX/data/handx                 -> /data/HandX/data/handx
```
