#!/bin/bash

coassembly_directory=$var1  #Coassembly directory
coassembly_name=$var2       #Coassembly name
scripts_dir=$var3           #Scripts directory
filter_len=$var4            #Minimum length filter
assembler=$var5             #Assembler used

out="${coassembly_directory}/${coassembly_name}/${assembler}/filtered_contigs.fa"
pi="${coassembly_directory}/${coassembly_name}/${assembler}/final.contigs.fa"
filt="${scripts_dir}/filter_contigs.py"

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

python ${filt} ${pi} -n ${coassembly_name} -l ${filter_len} > ${out}

rm $pi
