#!/bin/bash
shopt -s nullglob

#This script compress bins and removes all intermediate files from mapping, checkm ...

coassembly_directory=$var1  #Coassembly directory
coassembly_name=$var2       #Coassembly name
assembler=$var3             #Assembler used
bin_type=$var4              #Binning type
scripts_dir=$var5           #Scripts directory

#Remove .bam files and .bai files
binning_folder=${coassembly_directory}/${coassembly_name}/${assembler}/${bin_type}
rm ${binning_folder}/*.bam
rm ${binning_folder}/*.bam.bai

#Remove Checkm intermediate files
bins_place=${binning_folder}/bins_dir/
rm -r ${bins_place}/checkm/
rm ${bins_place}/depth.txt

#Compress bins
for bin in ${bins_place}/{HQ,MQ,LQ,CO}/*.fa; do
    bzip2 $bin
done
