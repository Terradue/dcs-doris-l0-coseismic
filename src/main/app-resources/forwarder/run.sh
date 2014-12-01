#!/bin/bash
 
# source the ciop functions (e.g. ciop-log)
source ${ciop_job_include}

# define the exit codes
SUCCESS=0
ERR_CURL=1
ERR_ADORE=2
ERR_PUBLISH=3
ERR_WRONGPROD=4

# add a trap to exit gracefully
function cleanExit ()
{
	local retval=$?
	local msg=""
	
	case "$retval" in
		$SUCCESS) msg="Processing successfully concluded";;
		$ERR_CURL) msg="Failed to retrieve the products";;
		$ERR_ADORE) msg="Failed during ADORE execution";;
		$ERR_PUBLISH) msg="Failed results publish";;
		$ERR_WRONGPROD) msg="Wrong product provided as input. Please use ASA_IMS_1P";;
		*) msg="Unknown error";;
	esac

	[ "$retval" != "0" ] && ciop-log "ERROR" "Error $retval - $msg, processing aborted" || ciop-log "INFO" "$msg"
	exit $retval
}
trap cleanExit EXIT

UUIDTMP="/tmp/`uuidgen`"
mkdir ${UUIDTMP}

/usr/bin/ciop-browseresults -r ${CIOP_WF_RUN_ID} -j node_pf_master -w | tr -d '\r' > ${UUIDTMP}/pf.master
/usr/bin/ciop-browseresults -r ${CIOP_WF_RUN_ID} -j node_pf_slave -w | tr -d '\r' > ${UUIDTMP}/pf.slave

# let's merge the results
for myresult in `cat ${UUIDTMP}/pf.slave`
do
	ciop-log "INFO" "merging $myresult with master"
	echo "$( cat ${UUIDTMP}/pf.master | tr -d '\n' )|${myresult}" > ${UUIDTMP}/pf.merge
done

# publishing results
cat ${UUIDTMP}/pf.merge | ciop-publish -s

rm -rf ${UUIDTMP}

exit 0
