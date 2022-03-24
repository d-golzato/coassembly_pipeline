#!/bin/bash
shopt -s nullglob

# Mapping of the reads is a necessary prior step to run binning or co-binning: 
#   - For binning, this script will map all the reads together (as if they were merged into a single sample)
#     to produce a single bam file. This bam file will be used to produce a single depth.txt file from metabat2
#   - For co-binning, this script will map in a sample-wise way the samples against the overall metagenome
#     assembly. These bam files will then be used to produce multiple depth.txt files that will be used
#     to exploit co-variance of contig depth for co-binning


coassembly_directory=$var1  #Coassembly directory
coassembly_name=$var2       #Coassembly name
ncores=$var3                #Number of cores
mem=$var4                   #Memory used
e=$var5                     #Extension of the reads
assembler=$var6             #Assembler you used for the assembly


coassembly_name_directory=${coassembly_directory}/${coassembly_name}/
contigs_folder=${coassembly_name_directory}/${assembler}
binning_dir="${coassembly_name_directory}/${assembler}/binning/"
reads_folder=${coassembly_name_directory}/tmp_reads


bwt2="/shares/CIBIO-Storage/CM/cmstore/tools/bowtie2-2.2.9/"
samtools="/shares/CIBIO-Storage/CM/cmstore/tools/samtools-1.3.1/bin/samtools"

mkdir -p ${binning_dir}

R1=(${reads_folder}/*_R1.fastq.bz2); R1=$(echo ${R1[@]} | tr " " ",");
R2=(${reads_folder}/*_R2.fastq.bz2); R2=$(echo ${R2[@]} | tr " " ",");
UN=(${reads_folder}/*_UN.fastq.bz2); UN=$(echo ${UN[@]} | tr " " ",");


${bwt2}bowtie2-build ${contigs_folder}/filtered_contigs.fa ${binning_dir}/${coassembly_name}

if [ ! -z ${R1} ]; then 
    if [ ! -z ${UN} ]; then 
            ${bwt2}bowtie2 -x ${binning_dir}/${coassembly_name}  -1 ${R1} -2 ${R2} -U ${UN} -S - --very-sensitive-local --no-unal -p ${ncores} | ${samtools} view -bS - > ${binning_dir}/${coassembly_name}.unsorted.bam;
    else
            ${bwt2}bowtie2 -x ${binning_dir}/${coassembly_name}  -1 ${R1} -2 ${R2} -S - --very-sensitive-local --no-unal -p ${ncores} | ${samtools} view -bS - > ${binning_dir}/${coassembly_name}.unsorted.bam;
    fi
else
    ${bwt2}bowtie2 -x ${binning_dir}/${coassembly_name} -U ${UN} -S - --very-sensitive-local --no-unal -p ${ncores} | ${samtools} view -bS - > ${binning_dir}/${coassembly_name}.unsorted.bam;
fi

${samtools} sort  ${binning_dir}/${coassembly_name}.unsorted.bam -o ${binning_dir}/${coassembly_name}.bam -m ${mem}G
${samtools} index ${binning_dir}/${coassembly_name}.bam ${binning_dir}/${coassembly_name}.bam.bai


rm ${binning_dir}/${coassembly_name}*bt2
rm ${binning_dir}/${coassembly_name}.unsorted.bam