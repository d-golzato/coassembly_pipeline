#!/bin/bash

#This script runs CheckM on the bins generated by binning and co-binning of the co-assemblies

coassembly_directory=$var1         #Coassembly directory
coassembly_name=$var2              #Coassembly name
bin_type=$var3                     #Binning type (binning or cobinning)
ncores=$var4                       #Number of cores
assembler=$var5                    #Assembler used

coassembly_name_directory=${coassembly_directory}/${coassembly_name}
bins_place=$coassembly_name_directory/${assembler}/${bin_type}/bins_dir

export PATH=/shares/CIBIO-Storage/CM/cmstore/tools/hmmer-3.1b2/binaries:$PATH
export PATH=/shares/CIBIO-Storage/CM/cmstore/tools/prodigal-2.6.3:$PATH
export PATH=/shares/CIBIO-Storage/CM/cmstore/tools/pplacer-1.1.alpha19:$PATH 

__conda_setup="$('/shares/CIBIO-Storage/CM/cmstore/tools/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
     eval "$__conda_setup"
     else
         if [ -f "/shares/CIBIO-Storage/CM/cmstore/tools/anaconda3/bin/conda" ]; then
              . "/shares/CIBIO-Storage/CM/cmstore/tools/anaconda3/bin/conda"
         else
              export PATH="/shares/CIBIO-Storage/CM/cmstore/tools/anaconda3/bin/conda:$PATH"
        fi
fi

unset __conda_setup

conda deactivate
conda activate checkMr 

checkm_output_dir=${bins_place}/checkm/

#if [ ! -d $checkm_output_dir/checkm ]; then mkdir -p $checkm_output_dir; fi

checkm lineage_wf -x fa            \
                  -t ${ncores}     \
                  --pplacer_threads ${ncores}     \
                  --tab_table                     \
                  --file ${coassembly_name_directory}/${assembler}/${bin_type}/bins_dir/checkm/stats.tsv \
                  ${bins_place}/                                                                         \
                  ${bins_place}/checkm
    