import pandas as pd
import os
import shutil
import argparse as ap
import sys

def read_params(args):
    parser = ap.ArgumentParser(description='Sort bins by quality')
    parser.add_argument('checkm_summary', type=str, help="Text file containing summary of the bin qualities")
    parser.add_argument('bins_folder', type=str, help="Folder containing bins to sort")
    return vars(parser.parse_args())

#Takes in input the coassembly_name folder in checkm, categorize bins and sort the bins into folder
# LQ, MQ and CO folders.
def qualFilter(completeness, contamination):
    if contamination <= 5.00:
        if (completeness >= 50.00 and completeness < 90.00):
            return "MQ"
        if (completeness >= 90.00):
            return "HQ"
        else:
            return "LQ"
    else:
        return "CO"

def sortBins(checkm_summary, bins_folder):
    #Absolute path to the directory with stats.tsv file in checkM parent directory
        try:
            stats_df = pd.read_csv(checkm_summary, sep="\t", usecols= [0,1,2], names =  ['bin_id', 'completeness', 'contamination'], header = None)
            stats_df.head()

            stats_df["MAG_quality"] = stats_df.apply(lambda row: qualFilter(row[1], row[2]), axis=1)

            outputFolder=bins_folder

            if ("CO" or "LQ" or "MQ" or "HQ") in os.listdir(outputFolder):
                print ("Quality folders already present")
            else:
                for dir in ["CO","LQ","MQ","HQ"]:
                    os.mkdir(os.path.join(outputFolder,dir))

            for index, row in stats_df.iterrows():
                bin_name = row["bin_id"] + ".fa"
                bin_qual = row["MAG_quality"]
                shutil.move(os.path.join(outputFolder,bin_name),os.path.join(outputFolder,bin_qual))
       
        except IOError:
            raise FileExistsError("{} file not found. Generate table with CheckM".format(checkm_summary))


if __name__ == '__main__':
    par = read_params(sys.argv)
    sortBins(par["checkm_summary"],par["bins_folder"])

