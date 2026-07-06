# Example: HMP

Per-subdirectory style: `HMP/data/` stays a real directory (holds code-relevant
subdirs); only the heavy children are symlinked. `HMP/outputs` is linked whole.

## Link structure
```
/home/aolab/Desktop/SeGA/HMP/outputs           -> /data/HMP/outputs
/home/aolab/Desktop/SeGA/HMP/data/amass        -> /data/HMP/data/amass
/home/aolab/Desktop/SeGA/HMP/data/body_models  -> /data/HMP/data/body_models
```

## Assets placed under /data
```
outputs/generative/results/model/local_encoder.pth
outputs/generative/results/model/nemf.pth
outputs/generative/results/model/global_encoder.pth
data/body_models/mano/
data/amass/generative/mean-neutral-128-30fps.pt
data/amass/generative/std-neutral-128-30fps.pt
```
