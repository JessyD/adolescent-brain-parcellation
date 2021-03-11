# adolescent-brain-parcellation

This project aims to create a brain parcellation for pre-adolescents subjects using the ABCD dataset. When performing a neuroscience study, it is common to extract regions of interest using a parcellation scheme. Although many parcellation schemes exist, these parcellations have been derived from adult data and might lead to biases when applied to a different age group. This repository contains code to create pre-adolescent brain parcellation following the methods described by [Yeo et al. (2011)](https://journals.physiology.org/doi/full/10.1152/jn.00338.2011) using the ABCD dataset.

The code inside 'cbig_simplified' contains a modified version of the code provided by the [Computational Brain Imaging Group (CBIG)](https://github.com/ThomasYeoLab/CBIG/tree/master/stable_projects/brain_parcellation/Yeo2011_fcMRI_clustering). This modified version make sure that the code can be run using a singularity container. 

The code was developed during the [ABCD-ReproNim course's project week](https://www.abcd-repronim.org/about.html).
