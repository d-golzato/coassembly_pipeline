#!/bin/bash

# Variables to modify
#scripts_dir='/shares/CIBIO-Storage/CM/scratch/users/davide.golzato/mytools/coassembly_pipeline/'
scripts_dir='/shares/CIBIO-Storage/CM/scratch/users/davide.golzato/fucina/coassembly_pipeline/'
assembly_dir='/shares/CIBIO-Storage/CM/scratch/users/davide.golzato/analyses/co-assemblies'
base_assembler='megahit'

# Variables to not modify
steps_string_metagenome="(1) Prepare co-assembly folder (create symbolic link to the fastq files of the samples you want to co-assemble.). \n(2) Run co-assembly (megahit [default] or spades)\n(3) Filter out small contigs from the co-assembly\n(4) Run contig mapping using Bowtie2: you can choose to run sample mapping against co-assembled contigs sample-wise (co-binning), or globally (co-assembly)\n(5) Run Metabat2 \n(6) Run CheckM \n(7) Summarize CheckM results \n(8) Sort out bins according to their quality in different folders\n(9) Remove intermediate files and compress fasta files\n"
queue_message=$(echo ${base_queue} | tr '[:upper:]' '[:lower:]' | cut -d "_" -f 1)
header_message="\n********************************************************************\n\n\t\t\tCO-ASSEMBLY PIPELINE \n\n********************************************************************\n"
steps_message_metagenome="\n\nCO-ASSEMBLY STEPS :\n${steps_string_metagenome}\n"
help_message="\nSCRIPT PARAMETERS:\n-N: The name of the coassembly.\n\n-s assembly_step: see available steps.\n\n-f dataset_folder: [Optional] alternative location for the dataset.\n\tDefault: /shares/CIBIO-Storage/CM/scratch/data/meta\n\n-r reads_folder: [Optional] alternative name for the reads folder.\n\tDefault: reads\n-E reads_extension: [Optional] alternative extension for the read files.\n\tDefault: fastq.bz2\n\n-M memory: Assigned memory per each job (GB). Defaults: 20, 20, 20 and 30.\n-c ncpus: Assigned CPUs per each job. Defaults: 3, 4, 3 and 4.\n\n-t [FLAG] When specified, cobinning mode is ON [spefici to steps > 4; default: OFF/Binning mode ]\n\n-j jobs: Number of samples to process parallely [used only for mapping step for co-binning]. Default: 1. \n\nSTEP 1 SPECIFIC PARAMETERS [OPTIONAL]:\n-A assembler: Assembler tool: spades, megahit.\n\tDefault: ${base_assembler}\n-a arguments: [Warning] Advanced arguments passed as a String.\n\tExample: -a \"--no-mercy --k-min 30\"\n\nSTEP 3 SPECIFIC PARAMETERS [OPTIONAL]:\n-l min_contig_len: Minimum lenght for consider a contig.\n\tDefault: 1000\n\nSTEP 6 SPECIFIC PARAMETERS [OPTIONAL]:\n-l min_contig_len: Minimum contig lenght for binning.\n\tDefault: 1500\n-g good_contigs: Percentage of 'good' contigs considered for binning\n\tdecided by connection. The greater, the more sensitive.\n\tDefault: 95\n-m min_score: Minimum score of a edge for binning (should be between\n\t1 and 99). The greater, the more specific.\n\tDefault: 60\n-e max_edges: Maximum number of edges per node. The greater, the\n\tmore sensitive.\n\tDefault: 200\n-a arguments: [Warning] Advanced arguments passed as a String.\n\tExample: -a \"--noAdd -s 100000\"\n\nUsage example: coassembly_pipeline -s 1 -N Coassembly_of_bont -D CM_BONT -S sample1 ... sampleN \n"

#PRESETS
advanced="" 
max_p=95
min_s=60
max_e=200
filter_len=1000
c2b_len=1500

#Binning type
bin_type=0

#Memory
mem_1=30
mem_4=20
mem_6=30
mem_8=30

#Number of cores
cores_1=3
cores_4=4
cores_6=3
cores_8=4

#Folders and extensions
default_dataset_folder="/shares/CIBIO-Storage/CM/scratch/data/meta/" #Needed if -f option needs to override default dataset_folder also with -i flag
#default_dataset_folder="/shares/CIBIO-Storage/CM/scratch/users/davide.golzato/fucina/assembly_on_server_example/scratch/data/meta/"
reads_folder="reads"
base_extension='fastq.bz2'

#Parallel jobs
n_parallel_jobs=1

#Dry run of the jobs?
dry_run=""               # Dry-run of the jobs (Default is no --dryrun, with -n flag --dryrun will be on)

#Assembler presets
spades_preset="--meta"
megahit_preset=""

#Command line argument control

#STEP 1: Creates folder for Co-assembly using create_symlinks.sh
#STEP 2: Run co-assembly
#STEP 3: Process co-assembly (filter and rename co-assembly contigs)
#STEP 4: Mapping for binning or co-binning
#STEP 5: Binning or co-binning
#STEP 6: Run CheckM in binning or co-binning folder
#STEP 7: Summarize CheckM qualities in binning or co-binning folder
#STEP 7: Sort bins of binning or co-binning according to their qualities

while getopts "h?d:s:l:b:g:m:nte:a:M:c:j:f:ir:A:E:N:S:D:C:L:O:" opt; do
    case "$opt" in
    h)
        printf "$header_message$help_message$steps_message"
        exit 0
        ;;
    a) 
        advanced="$OPTARG"
        ;;
    A) 
        assembler=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]')
        ;;
    E) 
        extension=$(echo "$OPTARG" | tr '[:upper:]' '[:lower:]')
        ;;
    f) 
        dataset_folder="$OPTARG/"
        ;;
    r) 
        reads_folder="$OPTARG"
        ;;
    M)
        mem_1=$OPTARG
        mem_4=$OPTARG
        mem_6=$OPTARG
        mem_8=$OPTARG
        ;;
    c)
        cores_1=$OPTARG
        cores_4=$OPTARG
        cores_6=$OPTARG
        cores_8=$OPTARG
        ;;
    j)
        n_parallel_jobs=$OPTARG
        ;;
    n)
        dry_run="--dryrun"
        ;;

    l) 
        filter_len=$OPTARG
        c2b_len=$OPTARG
        ;;
    s) 
        step=$OPTARG
        ;;
    g) 
        max_p=$OPTARG
        ;;
    m) 
        min_s=$OPTARG
        ;;
    b)
        min_bin_size=$OPTARG 
        ;;
    e) 
        max_e=$OPTARG
        ;;
    N)
        coassembly_name=$OPTARG
        ;;
    S)
        samples=($OPTARG)
        until [[ $(eval "echo \${$OPTIND}") =~ ^-.* ]] || [ -z $(eval "echo \${$OPTIND}") ]; do
            samples+=($(eval "echo \${$OPTIND}"))
            OPTIND=$((OPTIND + 1))
        done
        samples=$(IFS=" " ; echo "${samples[*]}")
        ;;
    D)
        dataset="$OPTARG"
        ;;
    O)
        assembly_dir="$OPTARG"
        ;;
    C)
        custom_directory="$OPTARG"
        ;;
    L)
        list_samples_file="$OPTARG"
        ;;
    t)
        bin_type=1
        ;;
    \?)
        printf "$help_message"
        exit 1
        ;;
    esac
done


# Handle options

if [ "$#" -lt 1 ]; then
    printf "$header_message$help_message$steps_message\n"
    echo -e "${steps_message_metagenome}\n"
    exit 1

fi
if [ -z ${step} ]; then
    printf "Co-assembly step is missing.\n\nAvailable steps:\n${steps_string}"
    exit 1
fi

if [ -z ${coassembly_name} ]; then
    printf "Dataset name is missing.\n"
    exit 1
fi

re='^[0-9]+$'
if ! [[ ${step} =~ $re ]] || [ ${step} -gt 9 ]; then
    printf "The introduced assembly step is not recognized.\n\nAvailable steps:\n${steps_string}"
    exit 1
fi


if [ ${bin_type} -eq 1 ]; then
    bin_type='cobinning'
else
    bin_type='binning'
fi

if [ ! -z ${extension} ]; then
    extension=".${extension}"
else
    extension="${base_extension}"
fi

# Handle steps

# STEP 1: manage creation of co-assembly results folder and generation of symlinks
if [ ${step} -eq 1 ]; then

    if [ ! -z ${coassembly_name} ]; then
        coassembly_name="-n ${coassembly_name}"
    fi

    if [ ! -z ${list_samples_file} ]; then
        list_samples_file=${list_samples_file}
		${scripts_dir}/create_symlinks.sh -l ${list_samples_file} ${coassembly_name} -o ${assembly_dir}
        exit 0
    fi

    if [ ! -z ${custom_directory} ]; then
		${scripts_dir}/create_symlinks.sh -c ${custom_directory}/ ${coassembly_name} -o ${assembly_dir}
        exit 0
    fi

    if [ ! -z "${samples}" ]  && [ ! -z ${dataset} ]; then

        if [ -z ${dataset_folder} ]; then
            dataset_folder=${default_dataset_folder}
        fi
		
		${scripts_dir}/create_symlinks.sh -f ${dataset_folder} -d ${dataset} -s ${samples} $coassembly_name -o ${assembly_dir}
        exit 0
    fi

    ${scripts_dir}/create_symlinks.sh
fi

if [ ${step} -eq 2 ]; then
    if [ ${assembler} == "megahit" ]; then
        var1="${assembly_dir}/${coassembly_name}" var2=${cores_1} var3=${mem_4} var4=${extension} ${scripts_dir}/megahit.sh
        exit 0
    fi

    if [ ${assembler} == "spades" ]; then
        var1="${assembly_dir}/${coassembly_name}" var2=${cores_1} var3=${mem_4} var4=${extension} var5=${spades_preset} ${scripts_dir}/spades.sh        
        exit 0
    fi

    echo "Choose an assembler between spades or megahit"
    exit 1
fi

if [ ${step} -eq 3 ]; then
    var1=${assembly_dir} var2=${coassembly_name} var3=${scripts_dir}/ var4=${filter_len} var5=${assembler} scripts_dir=${scripts_dir} ${scripts_dir}/filter_contigs.sh 
fi

if [ ${step} -eq 4 ]; then
    if [ ${bin_type} == 'binning' ]; then
        var1=${assembly_dir}  var2=${coassembly_name} var3=${cores_1} var4=${mem_4} var5=${extension} var6=${assembler}  ${scripts_dir}/bowtie2_binning.sh
    else
        samples_to_map=($(ls -d ${assembly_dir}/${coassembly_name}/tmp_reads/*fastq* | xargs -I {} basename {} | sed 's/_R.\..*//g' | sort | uniq))
        parallel -j ${n_parallel_jobs}   "var1=${assembly_dir} var2=${coassembly_name} var3={} var4=${cores_1} var5=${mem_4} var6=${extension} var7=${assembler} ${scripts_dir}/bowtie2_cobinning.sh " ::: `echo "${samples_to_map[@]}"`
    fi
fi

if [ ${step} -eq 5 ]; then
    var1="${assembly_dir}" var2="${coassembly_name}" var3="${bin_type}" var4="${c2b_len}" var5="${max_p}" var6="${min_s}" var7="${max_e}" var8="${advanced}" var9=${cores_6} var10=${assembler} ${scripts_dir}/metabat2.sh
fi

if [ ${step} -eq 6 ]; then
    var1="${assembly_dir}"  var2="${coassembly_name}"  var3="${bin_type}"  var4="${cores_1}" var5=${assembler} ${scripts_dir}/Checkm_coassembly.sh
fi

if [ ${step} -eq 7 ]; then
    var1="${assembly_dir}" var2=${coassembly_name} var3="${assembler}" var4=${bin_type} ${scripts_dir}/summarize_checkm.sh
fi

if [ ${step} -eq 8 ]; then
   var1="${assembly_dir}" var2=${coassembly_name} var3=${assembler} var4=${bin_type} var5=${scripts_dir} ${scripts_dir}/sort_bins.sh 
fi 

if [ ${step} -eq 9 ]; then
    var1="${assembly_dir}" var2=${coassembly_name} var3=${assembler} var4=${bin_type} var5=${scripts_dir} ${scripts_dir}/compress_and_remove.sh
fi
