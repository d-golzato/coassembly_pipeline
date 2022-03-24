#!/bin/bash
shopt -s nullglob

coassembly_directory=$var1     #Path to the folder with all the co-assembly projects
coassembly_name=$var2          #Name of the co-assembly
sample_name=$var3              #Name of the sample to map against co-assembly contigs
ncores=$var4                   #number of cores
mem=$var5                      #memory available
extension=$var6                #reads extension
assembler=$var7                #Assembler previously used


coassembly_name_directory=${coassembly_directory}/${coassembly_name}/
contigs_folder=${coassembly_name_directory}/${assembler}
cobinning_dir="${coassembly_name_directory}/${assembler}/cobinning/"
reads_folder=${coassembly_name_directory}/tmp_reads

bwt2="/shares/CIBIO-Storage/CM/cmstore/tools/bowtie2-2.2.9/"
samtools="/shares/CIBIO-Storage/CM/cmstore/tools/samtools-1.3.1/bin/samtools"

mkdir -p ${cobinning_dir}

R1=(${reads_folder}/${sample_name}_R1.${e}*); R1=$(echo ${R1[@]} | tr " " ",");
R2=(${reads_folder}/${sample_name}_R2.${e}*); R2=$(echo ${R2[@]} | tr " " ",");
UN=(${reads_folder}/${sample_name}_UN.${e}*); UN=$(echo ${UN[@]} | tr " " ",");

${bwt2}bowtie2-build ${contigs_folder}/filtered_contigs.fa ${cobinning_dir}/${sample_name}

if [ ! -z ${R1} ]; then 
    if [ ! -z ${UN} ]; then 
            ${bwt2}bowtie2 -x ${cobinning_dir}/${sample_name}  -1 ${R1} -2 ${R2} -U ${UN} -S - --very-sensitive-local --no-unal -p ${ncores} | ${samtools} view -bS - > ${cobinning_dir}/${sample_name}.unsorted.bam;
    else
            ${bwt2}bowtie2 -x ${cobinning_dir}/${sample_name}  -1 ${R1} -2 ${R2} -S - --very-sensitive-local --no-unal -p ${ncores} | ${samtools} view -bS - > ${cobinning_dir}/${sample_name}.unsorted.bam;
    fi
else
    ${bwt2}bowtie2 -x ${cobinning_dir}/${sample_name} -U ${UN} -S - --very-sensitive-local --no-unal -p ${ncores} | ${samtools} view -bS - > ${cobinning_dir}/${sample_name}.unsorted.bam;
fi

${samtools} sort  ${cobinning_dir}/${sample_name}.unsorted.bam -o ${cobinning_dir}/${sample_name}.bam -m ${mem}G
${samtools} index ${cobinning_dir}/${sample_name}.bam ${cobinning_dir}/${sample_name}.bam.bai

rm ${cobinning_dir}/${sample_name}*bt2
rm ${cobinning_dir}/${sample_name}.unsorted.bam


