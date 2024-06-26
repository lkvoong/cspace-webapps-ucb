#!/bin/bash

# these better be here!
source ~/.profile
source ${HOME}/venv/bin/activate

# three arguments required:
#
# postblob.sh tenant jobnumber configfilewithoutcfgextension
#
# e.g.
# time /var/www/ucjeps/uploadmedia/postblob.sh ucjeps 2015-11-10-09-09-09 ucjeps_Uploadmedia_Dev

TENANT=$1
RUNDIR="/var/www/${TENANT}/uploadmedia"
UPLOADSCRIPT="$RUNDIR/uploadMedia.py"

CONFIGDIR="/var/www/${TENANT}/config"
MEDIACONFIG="$CONFIGDIR/$3"

# this should be the fully qualified name of the input file, up to ".step1.csv"
JOB=$2
IMGDIR=$(dirname $2)

# claim this job...by renaming the input file
mv $JOB.step1.csv $JOB.inprogress.csv
INPUTFILE=$JOB.inprogress.csv
OUTPUTFILE=$JOB.step3.csv
LOGDIR=$IMGDIR
TRACELOG="$JOB.trace.log"

MERRITT_ARCHIVE_QUEUE=/cspace/merritt/jobs

rm -f $OUTPUTFILE
rm -f $JOB.archive.csv

TRACE=2

function trace()
{
   tdate=`date "+%Y-%m-%d %H:%M:%S"`
   [ "$TRACE" -eq 1 ] && echo "TRACE: $1"
   [ "$TRACE" -eq 2 ] && echo "TRACE: [$JOB : $tdate ] $1" >> $TRACELOG
   echo "$1"
}

trace "**** START OF RUN ******************** `date` **************************"
trace "output file: $OUTPUTFILE"

if [ ! -f "$INPUTFILE" ]
then
    trace "Missing input file: $INPUTFILE"
    exit
else
    trace "input file: $INPUTFILE"
fi
trace ">>>>>>>>>>>>>>> Starting Blob, Media, and Relation record creation process: `date` "
# handle .CR2 files: convert them to TIFs and JPGs, and upload then upload the JPGs 'as usual'
# save the TIFs back into s3 for ingestion into Merritt
# first, get a list of all the CR2s in the job
CR2FILE=$(mktemp /tmp/ucjeps-bmu-temp.XXXXXX)
grep -i '\.CR2' $INPUTFILE | cut -f1 -d"|" > ${CR2FILE}
# convert them all
for CR2 in `cat ${CR2FILE}`
  do
    FNAME_ONLY=$(echo "$CR2" | sed "s/\.CR2//i")
    # fetch the CR2 from S3
    echo "${RUNDIR}/cps3.sh \"$CR2\" ucjeps from" >> $TRACELOG
    ${RUNDIR}/cps3.sh "$CR2" ucjeps from >> $TRACELOG 2>&1
    # make a jpg and a tif for each cr2
    /usr/bin/nice -n +15 ${RUNDIR}/convertCR2.sh "/tmp/${CR2}" "${IMGDIR}" "bmu" >> $TRACELOG 2>&1
    # put the converted file back into S3
    for FORMAT in JPG TIF
    do
      echo "${RUNDIR}/cps3.sh \"${FNAME_ONLY}.${FORMAT}\" ucjeps to" >> $TRACELOG
      ${RUNDIR}/cps3.sh "${FNAME_ONLY}.${FORMAT}" ucjeps to >> $TRACELOG 2>&1
    done
    echo "${CR2/CR2/TIF}" >> $JOB.archive.csv
    # clean up
    rm "/tmp/${CR2}"
    rm "/tmp/${FNAME_ONLY}.*.jpg"
    ${RUNDIR}/cps3.sh "${FNAME_ONLY}.exifdata.txt" ucjeps to >> $TRACELOG 2>&1
done
# change the file names in the bmu job file so that it will upload the JPGs
perl -i -pe 's/\.CR2/.JPG/i' $INPUTFILE
# copy the 'archive file' to the input queue for the merritt archiving system
MERRITT_ARCHIVE_FILENAME=`basename $JOB.archive.csv`
MERRITT_ARCHIVE_FILENAME=${MERRITT_ARCHIVE_FILENAME/archive/input}
cp $JOB.archive.csv ${MERRITT_ARCHIVE_QUEUE}/bmu-${MERRITT_ARCHIVE_FILENAME}

trace "python $UPLOADSCRIPT $INPUTFILE $MEDIACONFIG >> $TRACELOG"
python $UPLOADSCRIPT $INPUTFILE $MEDIACONFIG >> $TRACELOG 2>&1
trace "Media record and relations created."

rm ${CR2FILE}
mv $INPUTFILE $JOB.original.csv
mv $JOB.step3.csv $JOB.processed.csv

trace "**** END OF RUN ******************** `date` **************************"
