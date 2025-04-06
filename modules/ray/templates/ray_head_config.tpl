#!/bin/bash
pip install ray[default]==${ray_version}
pip install ray[data]==${ray_version}
pip install ray[train]==${ray_version}
pip install ember3d proteinmpnn biopython
ray start --head --port=6379
