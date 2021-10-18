#!/usr/bin/env python3

from ftplib import FTP
import gzip
import shutil
import math
import sys
import datetime as dt

def download_ADAPT_magnetogram(timeIn, NameTypeMap='fixed'):
    '''
    This routine reads the date and type infomration from the command 
    line and download the corresponding ADAPT map.
    '''

    if NameTypeMap == 'fixed':
        StrTypeMap = '0'
    elif NameTypeMap == 'central':
        StrTypeMap = '1'
    else:
        raise ValueError('Unrecognized type of ADAPT map: '+NameTypeMap)

    # ADAPT maps only contains the hours for even numbers
    if timeIn.hour%2 != 0:
        timeIn.hour = floor(timeIn.hour/2)*2
        print('Warning: Hour must be an even number. '
              +'The entered hour value is changed to ', timeIn.hour)

    # Go to the the ADAPT ftp server
    ftp=FTP('gong2.nso.edu')
    ftp.login()
    
    # Only ADAPT GONG is considered
    ftp.cwd('adapt/maps/gong')

    # Go to the specific year
    try:
        ftp.cwd(str(timeIn.year))
    except:
        sys.exit('******************************************************************\n' 
                 + 'Year not found on the ftp server: '+str(timeIn.year) + '.\n'
                 + 'Check ftp://gong2.nso.edu/adapt/maps/gong in the corresponding \n'
                 + 'year to see whether it provides a map.\n'
                 + '******************************************************************\n')

    # Only consider the public (4) Carrington Fixed (0) GONG (3) ADAPT maps
    patten = 'adapt4'+StrTypeMap+'3*' + str(timeIn.year).zfill(4) + \
        str(timeIn.month).zfill(2) + str(timeIn.day).zfill(2)     + \
        str(timeIn.hour).zfill(2)  + '*'
    
    filenames = ftp.nlst(patten)

    timeMap = timeIn
    
    if len(filenames) < 1:
        iTry = 0
        timeLocal = timeIn
        while True:
            iTry += 1
            timeLocal   = timeLocal + dt.timedelta(hours=-1)
            pattenLocal = 'adapt4'+StrTypeMap+'3*' + str(timeLocal.year).zfill(4) + \
                str(timeLocal.month).zfill(2) + str(timeLocal.day).zfill(2)       + \
                str(timeLocal.hour).zfill(2)  + '*'
            if timeLocal.year != timeIn.year:
                ftp=FTP('gong2.nso.edu')
                ftp.login()
                ftp.cwd('adapt/maps/gong')
                try:
                    ftp.cwd(str(timeLocal.year))
                except:
                    sys.exit('******************************************************************\n'
                             + 'Year not found on the ftp server: '+str(timeLocal.year) + '.\n'
                             + 'Check ftp://gong2.nso.edu/adapt/maps/gong in the corresponding \n'
                             + 'year to see whether it provides a map.\n'
                             + '******************************************************************\n')
            filenames = ftp.nlst(pattenLocal)
            if len(filenames) > 0:
                timeMap = timeLocal
                print('Warning: cannot find the specific year/month/day/hour.')
                print('         But a map is found at '+ timeLocal.strftime("%Y-%m-%dT%H:00:00"))
                break
            if iTry > 1000:
                sys.exit('******************************************************************\n'
                         + 'Could not find any map with the specific time including prior 1000 \n'
                         + 'hours. Check ftp://gong2.nso.edu/adapt/maps/gong in the \n'
                         + 'corresponding year/month/day to see whether it provides a map.\n'
                         + '******************************************************************\n')
    
    for ifile, filename in enumerate(filenames):
        # open the file locally
        fhandle=open(filename, 'wb')
        
        # try to download the magnetogram
        try:
            ftp.retrbinary('RETR '+ filename, fhandle.write)
        except:
            sys.exit('Cannot download '+filename)
        
        # close the file
        fhandle.close()

        #unzip the file
        if '.gz' in filename:
            filename_unzip = 'adapt_' + timeMap.strftime('%Y%m%d%H') + '.fits'
            with gzip.open(filename, 'rb') as s_file, \
                open(filename_unzip, 'wb') as d_file:
                    shutil.copyfileobj(s_file, d_file, 65536)
            filenames[ifile]=filename_unzip
    
    ftp.quit()

    return filenames

if __name__ == '__main__':

    yyyy = int(input('Enter year: ' ))
    mm   = int(input('Enter month: '))
    dd   = int(input('Enter day: '  ))
    hh   = int(input('Enter hour: ' ))

    StrTime = str(yyyy).zfill(4)+'-'+str(mm).zfill(2)+'-' \
        +str(dd).zfill(2)+'T'+str(hh).zfill(2)

    timeIn = dt.datetime.strptime(StrTime,"%Y-%m-%dT%H")

    NameTypeMap = input('Type of ADAPT maps: fixed or central?  ')

    download_ADAPT_magnetogram(timeIn,NameTypeMap)
