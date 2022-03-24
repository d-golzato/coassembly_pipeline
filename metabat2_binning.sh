#!/bin/bash

#This script will do binning or co-binning according to the output of bowtie2
coassembly_directory=$var1/      #co-assembly directory
coassembly_name=$var2            #coassembly name
bin_type=$var3                   #Binning type
mem=$var4                        #min contig lenght
max_p=$var5                      #good contigs percentage
min_s=$var6                      #min score for a edge
max_e=$var7                      #max edges
advanced=$var8                   #advanced parameters
ncores=$var9                     #number of cores
assembler=$var10                 #assembler used (default is megahit)


metabat_dir="/shares/CIBIO-Storage/CM/cmstore/tools/metabat-2.12.1/"
metabat_output_dir=${coassembly_directory}/${coassembly_name}/${assembler}/${bin_type}/bins_dir/

if [ ! -d $metabat_output_dir ]; then mkdir -p $metabat_output_dir; fi

${metabat_dir}jgi_summarize_bam_contig_depths --outputDepth ${metabat_output_dir}/depth.txt ${coassembly_directory}/${coassembly_name}/${assembler}/${bin_type}/*.bam

${metabat_dir}metabat2 -m ${mem} -t 8 --unbinned --maxP ${max_p} --minS ${min_s} --maxEdges ${max_e} --seed 0 -i ${coassembly_directory}/${coassembly_name}/${assembler}/filtered_contigs.fa -a ${coassembly_directory}/${coassembly_name}/${assembler}/${bin_type}/bins_dir/depth.txt -o ${metabat_output_dir}/${coassembly_name}_bin ${advanced}