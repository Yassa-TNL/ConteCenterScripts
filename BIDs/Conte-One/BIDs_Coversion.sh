<<SKIP
subjects=`echo /dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/*/DICOMS | tr ' ' '\n' | cut -d '/' -f8 | tr '\n' ' '`

for subid in $subjects ; do

  echo 'Converting Dicoms to BIDs for '$subid
  sub=`echo $subid | cut -d '_' -f1`
  ses=`echo $subid | cut -d '_' -f2`
  Dicoms=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}/DICOMS
  Residual=/dfs2/yassalab/rjirsara/ConteCenter/Dicoms/Conte-One/${subid}/Residual
  mkdir -p $Residual

  dcm2bids -d $Dicoms -p ${sub} -s ${ses} -c \
  /dfs2/yassalab/rjirsara/ConteCenter/ConteCenterScripts/BIDs/Conte-One/config_Conte-One.json \
  -o ${Residual} --forceDcm2niix --clobber

done
SKIP
