#!/bin/bash

## This script is used to summarize, on the basis of
## the stats file from checkm, the bins that are
## >= 50 % completeness and < 5% contamination
## then it parses the outputtted file and copies on 
## the genomes_comp50_cont05 folder the genomes 
## following these caracteristics.

coassembly_directory=$var1          #Dataset name
coassembly_name=$var2               #Assembly directory
assembler=$var3                     #Assembler previously used
bin_type=$var4                      #Binning type


coassembly_name_directory=${coassembly_directory}/${coassembly_name}/${assembler}
sp='bins_dir/checkm/storage/'
binning_place="${coassembly_name_directory}/${bin_type}"
bins_place=${binning_place}/${sp}

if test -d "${bins_place}"; then   
    sed "s/\t{.*//g" ${bins_place}/bin_stats_ext.tsv > ${bins_place}/qa.tsv
    sed "s/.*'Completeness': //g" ${bins_place}/bin_stats_ext.tsv | sed "s/,.*//g" >> ${bins_place}/qa.tsv; 
    sed "s/.*'Contamination': //g" ${bins_place}/bin_stats_ext.tsv | sed "s/,.*//g" >> ${bins_place}/qa.tsv 
    sed "s/.*'Genome size': //g" ${bins_place}/bin_stats_ext.tsv | sed "s/,.*//g" >> ${bins_place}/qa.tsv 
    sed "s/.*'N50 (contigs)': //g" ${bins_place}/bin_stats_ext.tsv | sed "s/,.*//g" >> ${bins_place}/qa.tsv 
    sed "s/.*'marker lineage': //g" ${bins_place}/bin_stats_ext.tsv | sed "s/,.*//g" >> ${bins_place}/qa.tsv;

    for i in $(seq 1 $(($(cat ${bins_place}/qa.tsv | wc -l)/6)))
    do 
        sed -n ${i}~$(($(cat ${bins_place}/qa.tsv | wc -l)/6))p ${bins_place}/qa.tsv > ${bins_place}/tmp.tsv 
        tr "\n" "\t" < ${bins_place}/tmp.tsv >> ${bins_place}/qa2.tsv; echo "" >> ${bins_place}/qa2.tsv 
    done

    rm ${bins_place}/qa.tsv ${bins_place}/tmp.tsv 
    mv ${bins_place}/qa2.tsv ${bins_place}/qa.tsv 

fi

grep "" ${bins_place}qa.tsv | sed 's,/bins_dir/checkm/storage/qa.tsv:,\t,g' | sed "s,${coassembly_name_directory}/,,g"  > ${binning_place}/${bin_type}_summary_checkm.txt
