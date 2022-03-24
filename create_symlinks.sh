#!/bin/bash

#Do not modify; this keeps track of how many mutually exclusive options have been specified by user
exclusive_options_c=0

#PRESET variables
output_folder='/shares/CIBIO-Storage/CM/scratch/users/davide.golzato/analyses/co-assemblies/'
default_dataset_folder="/shares/CIBIO-Storage/CM/scratch/data/meta/" 
#default_dataset_folder="/shares/CIBIO-Storage/CM/scratch/users/davide.golzato/fucina/assembly_on_server_example/scratch/data/meta/"
reads_folder="reads"

help_message="\n\nThis script creates a folder with the symbolic links to fastq files of samples that you want to coassembly.\n\nYou can specify:\n    - A list with the fullpaths to the folder containing a sample reads (-L TEXT_FILE)\n    - Specify the name of the dataset that we have in scratch/data/meta and the list of sample names in it (-N CM_TEST -S Sample1 Sample2 Sample3 ...)\n    - Specify the folder containing the sub-directories of the samples with the reads in them  (-C PATH/TO/CUSTOM/DIR ) \n\n"

while getopts "h?d:s:c:n:l:f:r" opt; do
    case "$opt" in
    h)
        printf "$help_message"
        exit 0
        ;;
    f) 
        dataset_folder="$OPTARG/"
        ;;
    r) 
        reads_folder="$OPTARG"
        ;;
    d) 
        dataset="$OPTARG"
        exclusive_options_c=$(($exclusive_options_c+1))
        ;;
    s) 
        samples=($OPTARG)
        until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
            samples+=($(eval "echo \${$OPTIND}"))
            OPTIND=$((OPTIND + 1))
        done
        ;;
    l)
        list="$OPTARG"
        exclusive_options_c=$(($exclusive_options_c+1))
        ;;
    o)
        output_folder="$OPTARG"
        ;;
    c)
        custom_directory="$OPTARG"
        exclusive_options_c=$(($exclusive_options_c+1))       
        ;; 
    n)
        coassembly_name="$OPTARG" 
        ;;
    \?)
        printf "$help_message"
        exit 1
        ;;
    esac
done

# If you specify f,r,d,s option then it will go look into the dataset_folder, create the symlinks and exit
if [ "$#" -lt 1 ]; then
    printf "$help_message\n"
    echo -e "ERROR: You didn't provide any option\n"
    exit 1
fi

#TODO: Exit if you specify mutually exclusive options (-d, -c, -l)
if [ ! ${exclusive_options_c} -eq 1 ]; then
    echo "-c, -d and -l are mutually exclusive options, please specify only one of these"
    exit 1
fi


if [ -z "$dataset_folder" ]; then
    dataset_folder=${default_dataset_folder}
fi

if [ ! -z $list ]; then

    list=$(realpath $list)

    if [ -z $coassembly_name ]; then
        random_string=$(echo $(basename $list) | md5sum | head -c 10 ; echo '')
        coassembly_name="${random_string}_$(basename $list )"
        coassembly_name=${coassembly_name%.*}
    fi
    

    tmp_reads_folder=$output_folder/$coassembly_name/tmp_reads
    mkdir -p "$tmp_reads_folder"

    while read -r line; do

        if [ ! -d $line ]; then
            echo "Folder for sample $(basename $line) folder missing"
        fi
        if [ -z "$(ls -A $line)" ]; then
            echo "Folder for sample $(basename $line) is empty"
        fi

        if [ ! -z "$(ls -A $line/*.fastq.bz2)" ]; then
            for library in $line/*.fastq.bz2; do
                ln -s $(realpath $library) $tmp_reads_folder
            done
        fi
    done < $list
    exit 1
fi

if [ ! -z $custom_directory ]; then
    
    if [ ! -d $custom_directory ]; then 
        printf "$help_message\n"
        echo -e "ERROR: The folder you provide ($custom_directory) doesn't exist\n"
        exit 1
    fi
    
    if [ -z $coassembly_name ]; then
            random_string=$(echo $(basename $custom_directory) | md5sum | head -c 10 ; echo '')
            coassembly_name="${random_string}_$(basename $custom_directory)"
    fi

    tmp_reads_folder=$output_folder/$coassembly_name/tmp_reads
    mkdir -p $tmp_reads_folder

    samples=$(ls -d $custom_directory/*)    
    for sample in $samples; do
        for library in $sample/*.fastq.bz2; do
            ln -s $(realpath $library) $tmp_reads_folder
        done
    done
    exit 1
fi

#You specified a dataset and some samples
if [ ! -z "$dataset" ]; then
    dataset_folder=$default_dataset_folder/$dataset/$reads_folder
else
    printf "$help_message\n"
    echo -e "ERROR: Please provide at least the name of an existing dataset in ${dataset_folder}"
    exit 1
fi

if [ "${#samples[@]}" -le 1 ]; then
    echo "Please provide at least one existing sample ${dataset_folder}"
    exit 1
fi

if [ -z "$coassembly_name" ]; then
    sorted_samples=$(printf '%s\n' "${samples[@]}" |sort)
    random_string=$(echo ${sorted_samples[@]} | md5sum | head -c 10 ; echo '')
    coassembly_name="${random_string}_$(basename $dataset)"   
fi    
    
tmp_reads_folder=$output_folder/$coassembly_name/tmp_reads/
mkdir -p $tmp_reads_folder

for sample in ${samples[@]}; do
    for f in $dataset_folder/$sample/*.fastq.bz2; do
       ln -s $(realpath $f) $tmp_reads_folder/
    done
done 
    
exit 1