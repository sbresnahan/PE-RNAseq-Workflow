#!/bin/sh

sample_IDs="${1}"
DIR_LOGS="${2}"

FILES=( $(awk '{print $1}' ./${sample_IDs}) )

for FILE in "${FILES[@]}"
do
  bsub -env XFILEX=${FILE} \
    -o ${DIR_LOGS}/${FILE}.logo \
    -e ${DIR_LOGS}/${FILE}.loge \
    < run_processPEfastq.lsf
done
