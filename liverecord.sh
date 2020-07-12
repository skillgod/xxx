#!/bin/bash

NICO_ID_PSW=$(echo "${1}" | awk -F":" '{print $2}')
STREAM_PROXY_HARD=$(echo "${1}" | awk -F"," '{print $2}')
PART_URL="${2}" #频道
FORMAT="${3:-best}" #清晰度
LOOP_TIME="${4:-loop}" #是否循环
LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN="${5:-10,10,1}" ; LOOPINTERVAL=$(echo "${LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN}" | awk -F"," '{print $1}'); ENDINTERVAL=$(echo "${LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN}" | awk -F"," '{print $2}'); [[ "${ENDINTERVAL}" == "" ]] && ENDINTERVAL=${LOOPINTERVAL} ; LIVESTATUSMIN=$(echo "${LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN}" | awk -F"," '{print $3}') ; [[ "${LIVESTATUSMIN}" == "" ]] && LIVESTATUSMIN=1 #循环检测间隔,最短录制间隔,录制开始所需连续检测开播次数
DIR_LOCAL="${6:-record_video/other}" ; if [[ "${1}" != "youtube-dl" ]]; then mkdir -p "${DIR_LOCAL}"; fi #本地目录
LIVE_A_V="${7:-audio}"

[[ "${1}" == "youtube"* ]] && FULL_URL="https://www.youtube.com/channel/${PART_URL}/live"

LIVE_STATUS=0
while true; do
	while true; do
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${FULL_URL}"
		if [[ "${1}" == "youtube"* ]]; then
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
			if (wget -q -O- "${FULL_URL}" | grep "ytplayer" | grep -q '\\"isLive\\":true'); then
				let LIVE_STATUS++
			else
				LIVE_STATUS=0
			fi
			#(wget -q -O- "${FULL_URL}" | grep -q '\\"playabilityStatus\\":{\\"status\\":\\"OK\\"') && break
		fi
		
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata livestatus=${LIVE_STATUS}"
		if [[ ${LIVE_STATUS} -gt 0 ]]; then break; fi
		sleep ${LOOPINTERVAL}
	done
	
	if [[ "${1}" == "youtube"* ]]; then ID=$(wget -q -O- "${FULL_URL}" | grep -o '\\"liveStreamabilityRenderer\\":{\\"videoId\\":\\".*\\"' | head -n 1 | sed 's/\\//g' | awk -F'"' '{print $6}'); fi
	
	if [[ "${1}" == "youtube-dl" ]]; then
    		FILENAME_PREFIX=$(youtube-dl -s --get-filename --ignore-errors -f 'best[height<=480]' -o '%(uploader)s/%(upload_date)s_%(title)s' "https://www.youtube.com/watch?v=${ID}" 2>/dev/null)
    		if [[ "${LIVE_A_V}" == "audio" ]]; then
			(youtube-dl --ignore-errors --embed-thumbnail -x --audio-quality 0 -f 'best[height<=480]' -o '%(uploader)s/%(upload_date)s_%(title)s.%(ext)s' "https://www.youtube.com/watch?v=${ID}" 2>/dev/null)
		
			RECORD_PID=$! #录制进程PID
			RECORD_STOPTIME=$(( $(date +%s)+${LOOP_TIME} )) #录制结束时间戳
			RECORD_ENDTIME=$(( $(date +%s)+${ENDINTERVAL} )) #录制循环结束的最早时间
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record start pid=${RECORD_PID} looptime=${LOOP_TIME} url=${STREAM_URL}" #开始录制
			sleep 15
			kill ${RECORD_PID}
		
			rclone copy "${FILENAME_PREFIX}.jpg" onedrive:${6} -P 2>/dev/null
			rclone copy "${FILENAME_PREFIX}.m4a" onedrive:${6} -P 2>/dev/null
    		else
      			if [[ "${FORMAT}" == "best" ]]; then
        			(youtube-dl --ignore-errors -f "best" -o '%(uploader)s/%(upload_date)s_%(title)s.%(ext)s' "https://www.youtube.com/watch?v=${ID}" 2>/dev/null)
      			else
        			(youtube-dl --ignore-errors -f "best[height<=${FORMAT}]" -o '%(uploader)s/%(upload_date)s_%(title)s.%(ext)s' "https://www.youtube.com/watch?v=${ID}" 2>/dev/null)
			fi
			RECORD_PID=$! #录制进程PID
			RECORD_STOPTIME=$(( $(date +%s)+${LOOP_TIME} )) #录制结束时间戳
			RECORD_ENDTIME=$(( $(date +%s)+${ENDINTERVAL} )) #录制循环结束的最早时间
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record start pid=${RECORD_PID} looptime=${LOOP_TIME} url=${STREAM_URL}" #开始录制
			sleep 15
			kill ${RECORD_PID}
		
			rclone copy "${FILENAME_PREFIX}.mp4" onedrive:${6} -P && rm "${FILENAME_PREFIX}.mp4"
    		fi
	fi
	
	[[ "${LOOP_TIME}" == "once" ]] && break
	
	if [[ $(date +%s) -lt ${RECORD_ENDTIME} ]]; then
		RECORD_ENDREMAIN=$(( ${RECORD_ENDTIME}-$(date +%s) )) ; [[ RECORD_ENDREMAIN -lt 0 ]] && RECORD_ENDREMAIN=0 #距离应有的最早结束时间的剩余时间
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record end retry after ${RECORD_ENDREMAIN} seconds..."
		sleep ${RECORD_ENDREMAIN}
	fi
done
