#!/usr/bin/env bash

# credentials, etc. required to make the ucjeps merritt archiving pipeline work

# used to retrieve signed urls for the images in merritt's s3 bucket
export MERRITT_USER="<getfrommerritt>"
export MERRITT_PASSWORD="<getfrommerritt>"
export MERRIT_BUCKET=jepson-snowcone.uc3dev.cdlib.org

# used to submit "batches" of "jobs" to merritt ingest
export COLLECTION_USERNAME="<getfrommerritt>"
export COLLECTION_PASSWORD="<getfrommerritt>"

# our s3 bucket for transitory images
export S3BUCKET="https://cspace-merritt-in-transit-qa.s3.us-west-2.amazonaws.com"
export S3URI="s3://cspace-merritt-in-transit-qa"
export SUBMITTER="jblowe"
export MERRIT_INGEST="https://merritt-stage.cdlib.org/object/update"
export PROFILE="ucjeps_img_archive_content"

# s3 'website bucket'
WEBSITE_BUCKET="s3://ucjeps-archiving-thumbnails/qa/thumbs"

# the jobs files used by the pipeline go here (many small files)
export JOB_DIRECTORY="/cspace/merritt/jobs"

# transaction database
export SQLITE3_DB="/cspace/merritt_archive/merritt_archive.sqlite3"

# os-specific command to format output of 'time'
export TIME_COMMAND="time"
