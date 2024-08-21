#!/bin/sh

sample_IDs="${1}"

FILES=( $(awk '{print $1}' ./${sample_IDs}) )

for FILE in "${FILES[@]}"
do
  bsub -env XFILEX=${FILE} < run_processPEfastq.lsf
done
