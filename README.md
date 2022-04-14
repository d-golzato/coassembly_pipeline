# Co-assembly and Co-binning pipeline

This script is a wrapper to run the tools for co-assembling multiple metagenomic samples

# Set it up

1) Clone the repository on your machine

2) Modify the variables scripts_dir and assembly_dir in the script coassembly_pipeline.sh

    - scripts_dir: this is the path with the scripts of the pipeline, it should point to
      the folder of the cloned repository
      
    - assembly_dir: this is the folder where the co-assemblies will be stored. It is not
      necessary that it exists, it will be created in the specificied path if you have
      write permissions to that folder
      
 3) The pipeline consists of the following steps:
      
      3.1) Creation of the folder where the specific co-assembly will be stored. This 
           will use the script _create\_symlinks.sh_ to create a folder containing the
           symbolic links to the reads of the samples that you want to co-assemble.
           
           This script allows to create this folder using:
           
              - A list with the paths to the sample folders containing the paired-end libraries ( _R1.fastq_, _R2.fastq_, _UN.fastq_ )
                with the -L option
                
              - By specifying a folder with all the datasets (like _/shares/CIBIO-Storage/CM/scratch/data/meta_) with the -f option,
                the name of the dataset (like _CM\_zoe_ ) with the -D option, and the samples in that dataset (like _PS_ZY1_ _PS_ZY2_ _PS_ZY3_ )
                with the -S option (sample names need to be separated by space)
                
              - By pointing to a folder with a custom dataset you want to co-assemble (like  _/shares/CIBIO-Storage/CM/scratch/data/meta/CM_zoe1/reads_ )
                with the -C option
                 
      3.2) Co-assembly of the read samples. You can specify an assembler between metaSpades or MEGAHIT with the -A option
           You can change parameters such as the number of cores (-c option), the memory to be used (in GB with the -M option)
           and many other parameters

      3.3) Filter of small contigs. Once you generated the assembled contigs, you can filter contigs that are small and won't be
           useful for metagenomic binning. You can specify the minimum contig length with the -l option
           
      3.4) Mapping (here you decide between single binning or co-binning). You need to specificy the [-t FLAG] if you want to run
           co-binning, or not to specify it if you want to run single-binning.
           [Note: starting from this step, you need to specify the -t flag to specify if you are running the further tools on
           the single-binning or the co-binning branches]
           
      3.5) Binning or co-binning. Use Metabat2 to bin the co-assembled contigs
     
      3.6) ChecK. Compute completeness and contaminations of the bins

      3.7) Summarize CheckM output in a handy file with the completeness and contamination of all the bins in the co-assembly

      3.8) Sort bins into folders according to their qualities with:

               - HQ folder ( >= 90% Complet. AND <= 5% Cont. )
               - MQ folder ( >= 50% Complet. AND <= 5% Cont. )
               - LQ folder ( <  50% Complet. AND <= 5% Cont. )
               - CO folder ( > 5% Cont. )

      8.9) Compress bins and remove all intermediate files

 4) You can now use the MAGs in HQ and MQ folders to run downstream analyses
