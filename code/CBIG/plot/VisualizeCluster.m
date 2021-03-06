function VisualizeCluster(clusters_mat, num_clusters, ref_file, mesh_name, output_fig)

if(ischar(num_clusters))
   num_clusters = str2num(num_clusters); 
end

clustered = load(clusters_mat);
ref = load(ref_file);
CBIG_DrawSurfaceMaps_fslr(clustered.lh_labels, clustered.rh_labels, mesh_name, 'inflated', 0, num_clusters, ref.colors);
print('-djpeg', '-r1000', output_fig)

close all