import numpy as np
import pandas as pd
import datetime
import glob
import procedures_insitu
import os

import sys
#check input parameters
if(len(sys.argv) < 5):
    print('The number of input arguments is not correct!')

#decide simulation and plot directory
#decide model and cache folder for observation
dir_swmf  = sys.argv[1]
dir_sim   = sys.argv[2]
dir_plot  = sys.argv[3]
model     = sys.argv[4]
dir_cache = sys.argv[5]

#determine the existence of the folders
for dir in [dir_swmf,dir_sim,dir_plot,dir_cache]:
    if (not os.path.isdir(dir)):
        print('The '+dir+' folder does not exist!')
#initialize preprocess
preprocess  = procedures_insitu.preprocess()
spacecrafts = ['earth','sta','stb']

#
for spacecraft in spacecrafts:
    if(spacecraft == 'earth'): 
        icme_file = dir_swmf+'/SWMFSOLAR/Events/ICME_list_ACE.csv'
    elif('st' in spacecraft ): 
        icme_file = dir_swmf+'/SWMFSOLAR/Events/ICME_list_STEREO.csv'
    else: 
        print('No ICME list found for '+spacecraft+' !')
    #find all trj files
    files=glob.glob(dir_sim+'/trj*'+spacecraft+'*')
    for filename in files:
        #read in simulation data
        data = preprocess.read_simu_data(filename)
        #get observation data
        obs_data=preprocess.get_insitu_data(spacecraft,
                data['date'].iloc[0],data['date'].iloc[-1],dir_cache)
        #get ICME list
        icme_start,icme_end = preprocess.get_icme_list(icme_file,
                data['date'].iloc[0],data['date'].iloc[-1],spacecraft)
        #plot
        preprocess.plot_data(dir_plot,data,obs_data,icme_start,icme_end,spacecraft,model)
