#!/bin/bash

singularity exec -c \
	-B /shared/project-brain-parcellation/adolescent-brain-parcellation/cbig_simplified:/cbig_simplified \
	-B /shared/project-brain-parcellation/data/output/abcd-octave-parcellation:/yeo2011 \
	-B /shared/project-brain-parcellation/adolescent-brain-parcellation/code/container:/sing \
    -B /shared/project-brain-parcellation/abcd_sub_list.txt:/tmp/abcd_sub_list.txt \
    /shared/project-brain-parcellation/adolescent-brain-parcellation/code/container/yeo2011.sif "$@"
