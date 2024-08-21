#!/bin/sh

sample_IDs="${1}"

FILES=( $(awk '{print $1}' ./${sample_IDs}) )

for FILE in "${FILES[@]}"
do
  sed "s/XFILEX/${FILE}/g" < run_processPEfastq.lsf | bsub
done
