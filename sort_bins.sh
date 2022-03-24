#!/bin/bash

coassembly_directory=$var1  #Coassembly directory
coassembly_name=$var2       #Coassembly name
assembler=$var3             #Assembler used
bin_type=$var4              #Binning type
scripts_dir=$var5           #Scripts directory

qual_sort=${scripts_dir}/sortBins.py

binning_folder=${coassembly_directory}/${coassembly_name}/${assembler}/${bin_type}
stats_file=${binning_folder}/${bin_type}_summary_checkm.txt
bins_place=${binning_folder}/bins_dir/

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
conda activate davide.golzato 

if [ ! -f ${stats_file} ]; then
    echo "${coassembly_name} does not exists. Please generate it with step n. 6"
    exit 1
fi

if [ ! -d ${bins_place} ]; then
    echo "${bins_place} does not exist. Please run metabat2 to bin your assembly"
    exit 1
fi

python3 ${qual_sort} ${stats_file} ${bins_place}

