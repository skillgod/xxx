#!/bin/bash

if [[ ! -n "${1}" ]]; then
	echo "${0} youtube|youtubeffmpeg|twitcast|twitcastffmpeg|twitcastpy|twitch|openrec|nicolv[:用户名,密码]|nicoco[:用户名,密码]|nicoch[:用户名,密码]|mirrativ|reality|17live|chaturbate|bilibili|bilibiliproxy[,代理ip:代理端口]|streamlink|m3u8 \"频道号码\" [best|其他清晰度] [loop|once|视频分段时间] [10,10,1|循环检测间隔,最短录制间隔,录制开始所需连续检测开播次数] [\"record_video/other|其他本地目录\"] [nobackup|rclone:网盘名称:|onedrive|baidupan[重试次数][keep|del]] [\"noexcept|排除转播的youtube频道号码\"] [\"noexcept|排除转播的twitcast频道号码\"] [\"noexcept|排除转播的twitch频道号码\"] [\"noexcept|排除转播的openrec频道号码\"] [\"noexcept|排除转播的nicolv频道号码\"] [\"noexcept|排除转播的nicoco频道号码\"] [\"noexcept|排除转播的nicoch频道号码\"] [\"noexcept|排除转播的mirrativ频道号码\"] [\"noexcept|排除转播的reality频道号码\"] [\"noexcept|排除转播的17live频道号码\"] [\"noexcept|排除转播的chaturbate频道号码\"] [\"noexcept|排除转播的streamlink支持的频道网址\"]"
	echo "示例：${0} bilibiliproxy,127.0.0.1:1080 \"12235923\" best,1080p60,1080p,720p,480p,360p,worst 14400 15,5,2 \"record_video/mea_bilibili\" rclone:vps:onedrivebaidupan3keep \"UCWCc8tO-uUl_7SJXIKJACMw\" \"kaguramea\" \"kagura0mea\" \"KaguraMea\" "
	echo "必要模块为curl、streamlink、ffmpeg，可选模块为livedl、python3、you-get，请将livedl文件放置于运行时目录的livedl文件夹内、请将record_twitcast.py文件放置于运行时目录的record文件夹内。"
	echo "rclone上传基于\"https://github.com/rclone/rclone\"，onedrive上传基于\"https://github.com/MoeClub/OneList/tree/master/OneDriveUploader\"，百度云上传基于\"https://github.com/iikira/BaiduPCS-Go\"，请登录后使用。"
	echo "注意使用youtube直播仅支持1080p以下的清晰度，请不要使用best和1080p60及以上的参数"
	echo "仅bilibili支持排除转播功能"
	exit 1
fi
if [[ "${1}" == "twitcast" || "${1}" == "nicolv"* || "${1}" == "nicoco"* || "${1}" == "nicoch"* ]]; then
	[[ ! -f "livedl/livedl" ]] && echo "需要livedl，请将livedl文件放置于运行时目录的livedl文件夹内"
fi
if [[ "${1}" == "twitcastpy" ]]; then
	[[ ! -f "record/record_twitcast.py" ]] && echo "需要record_twitcast.py，请将record_twitcast.py文件放置于运行时目录的record文件夹内"
fi



NICO_ID_PSW=$(echo "${1}" | awk -F":" '{print $2}')
STREAM_PROXY_HARD=$(echo "${1}" | awk -F"," '{print $2}')
PART_URL="${2}" #频道号码
FORMAT="${3:-best}" #清晰度
LOOP_TIME="${4:-loop}" #是否循环或视频分段时间
LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN="${5:-10,10,1}" ; LOOPINTERVAL=$(echo "${LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN}" | awk -F"," '{print $1}'); ENDINTERVAL=$(echo "${LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN}" | awk -F"," '{print $2}'); [[ "${ENDINTERVAL}" == "" ]] && ENDINTERVAL=${LOOPINTERVAL} ; LIVESTATUSMIN=$(echo "${LOOPINTERVAL_ENDINTERVAL_LIVESTATUSMIN}" | awk -F"," '{print $3}') ; [[ "${LIVESTATUSMIN}" == "" ]] && LIVESTATUSMIN=1 #循环检测间隔,最短录制间隔,录制开始所需连续检测开播次数
DIR_LOCAL="${6:-record_video/other}" ; if [[ "${1}" != "youtube-dl" ]]; then mkdir -p "${DIR_LOCAL}"; fi #本地目录

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
	
	if [[ "${1}" == "youtube"* ]]; then ID=$(wget -q -O- "${FULL_URL}" | grep -o '\\"liveStreamabilityRenderer\\":{\\"videoId\\":\\".*\\"' | head -n 1 | sed 's/\\//g' | awk -F'"' '{print $6}') ; FNAME="youtube_${PART_URL}_$(date +"%Y%m%d_%H%M%S")_${ID}.ts"; fi
	if [[ "${1}" == "youtubeffmpeg" ]]; then STREAM_URL=$(streamlink --stream-url "${FULL_URL}" "${FORMAT}"); fi
	
	if [[ "${1}" == "youtube-dl" ]]; then
		(youtube-dl --ignore-errors --embed-thumbnail -x --audio-quality 0 -f 'best[height<=480]' -o '%(uploader)s/%(release_date)s_%(upload_date)s_%(title)s.%(ext)s' "https://www.youtube.com/watch?v=${ID}" 2>/dev/null)
	fi
	if [[ "${1}" == "youtubeffmpeg" || "${1}" == "twitcastffmpeg" || "${1}" == "twitch" || "${1}" == "openrec" || "${1}" == "mirrativ" || "${1}" == "reality" || "${1}" == "17live" || "${1}" == "chaturbate" || "${1}" == "streamlink" || "${1}" == "m3u8" ]]; then
		(ffmpeg -user_agent "Mozilla/5.0" -i "${STREAM_URL}" -codec copy -f mpegts "${DIR_LOCAL}/${FNAME}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
	fi
	
	RECORD_PID=$! #录制进程PID
	RECORD_STOPTIME=$(( $(date +%s)+${LOOP_TIME} )) #录制结束时间戳
	RECORD_ENDTIME=$(( $(date +%s)+${ENDINTERVAL} )) #录制循环结束的最早时间
	LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record start pid=${RECORD_PID} looptime=${LOOP_TIME} url=${STREAM_URL}" #开始录制
	while true; do
		sleep 15
		PID_EXIST=$(ps aux | awk '{print $2}'| grep -w ${RECORD_PID})
		if [[ ! $PID_EXIST ]]; then
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record already stopped"
			break
		else
			if [[ "${LOOP_TIME}" != "once" ]] && [[ "${LOOP_TIME}" != "loop" ]] && [[ $(date +%s) -gt ${RECORD_STOPTIME} ]]; then #录制时间到达则终止录制
				LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} time up kill record process ${RECORD_PID}"
				kill ${RECORD_PID}
				break
			fi
		fi
	done
	
	
	
	if [[ "${1}" == "twitcast" ]]; then
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} remane livedl/${DLNAME} to ${DIR_LOCAL}/${FNAME}"
		mv "livedl/${DLNAME}" "${DIR_LOCAL}/${FNAME}"
	fi
	
	(
	if [[ "${1}" == "nicolv"* || "${1}" == "nicoco"* || "${1}" == "nicoch"* ]]; then
		if [[ -f "livedl/${DLNAME}.sqlite3" ]]; then
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} convert start livedl/${DLNAME}.sqlite3 to livedl/${DLNAME}.ts"
			livedl/livedl -d2m -conv-ext=ts "${DLNAME}.sqlite3" >> "${DIR_LOCAL}/${FNAME}.log" 2>&1
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} convert stopped remove livedl/${DLNAME}.sqlite3 and xml"
			rm "livedl/${DLNAME}.sqlite3" ; rm "livedl/${DLNAME}.xml"
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} remane livedl/${DLNAME}.ts to ${DIR_LOCAL}/${FNAME}"
			mv "livedl/${DLNAME}.ts" "${DIR_LOCAL}/${FNAME}"
		fi
		if [[ -f "livedl/${DLNAME}(TS).sqlite3" ]]; then
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} convert start livedl/${DLNAME}(TS).sqlite3 to livedl/${DLNAME}(TS).ts"
			livedl/livedl -d2m -conv-ext=ts "${DLNAME}(TS).sqlite3" >> "${DIR_LOCAL}/${FNAME}.log" 2>&1
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} convert stopped remove livedl/${DLNAME}(TS).sqlite3 and xml"
			rm "livedl/${DLNAME}(TS).sqlite3" ; rm "livedl/${DLNAME}(TS).xml"
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} remane livedl/${DLNAME}(TS).ts to ${DIR_LOCAL}/${FNAME}"
			mv "livedl/${DLNAME}(TS).ts" "${DIR_LOCAL}/${FNAME}"
		fi
	fi
	
	
	
	if [[ ! -f "${DIR_LOCAL}/${FNAME}" ]] || [[ $(ls -l "${DIR_LOCAL}/${FNAME}" | awk '{print $5}') == 0 ]]; then #判断是否无录像
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} ${DIR_LOCAL}/${FNAME} file not exist remove log"
		rm -f "${DIR_LOCAL}/${FNAME}" ; rm -f "${DIR_LOCAL}/${FNAME}.log"
	elif [[ "${1}" == "bilibili"* ]] && [[ $(ls -l "${DIR_LOCAL}/${FNAME}" | awk '{print $5}') -lt 3000000 ]]; then
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} ${DIR_LOCAL}/${FNAME} file is too small remove file and log"
		rm -f "${DIR_LOCAL}/${FNAME}" ; rm -f "${DIR_LOCAL}/${FNAME}.log"
	else
		RCLONE_FILE_RETRY=1 ; RCLONE_FILE_ERRFLAG=""
		if [[ "${BACKUP_DISK}" == *"rclone"* ]]; then
			until [[ ${RCLONE_FILE_RETRY} -gt ${BACKUP_RETRY_MAX} ]]; do
				LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME} start retry ${RCLONE_FILE_RETRY}"
				RCLONE_FILE_ERRFLAG=$(rclone copy "${DIR_LOCAL}/${FNAME}" "${DIR_RCLONE}" 2>&1)
				[[ "${RCLONE_FILE_ERRFLAG}" == "" ]] && (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME} success") && break
				let RCLONE_FILE_RETRY++
				sleep 30
			done
			[[ "${RCLONE_FILE_ERRFLAG}" == "" ]] || (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME} fail" ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME} fail" > "${DIR_LOCAL}/${FNAME}.rclonefail.log" ; echo "${RCLONE_FILE_ERRFLAG}" >> "${DIR_LOCAL}/${FNAME}.rclonefail.log")
		fi
		RCLONE_LOG_RETRY=1 ; RCLONE_LOG_ERRFLAG=""
		if [[ "${BACKUP_DISK}" == *"rclone"* ]]; then
			until [[ ${RCLONE_LOG_RETRY} -gt ${BACKUP_RETRY_MAX} ]]; do
				LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME}.log start retry ${RCLONE_LOG_RETRY}"
				RCLONE_LOG_ERRFLAG=$(rclone copy "${DIR_LOCAL}/${FNAME}.log" "${DIR_RCLONE}" 2>&1)
				[[ "${RCLONE_LOG_ERRFLAG}" == "" ]] && (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME}.log success") && break
				let RCLONE_LOG_RETRY++
				sleep 30
			done
			[[ "${RCLONE_LOG_ERRFLAG}" == "" ]] || (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME}.log fail" ; echo "${LOG_PREFIX} upload rclone ${DIR_LOCAL}/${FNAME}.log fail" > "${DIR_LOCAL}/${FNAME}.log.rclonefail.log" ; echo "${RCLONE_LOG_ERRFLAG}" >> "${DIR_LOCAL}/${FNAME}.log.rclonefail.log")
		fi
		
		ONEDRIVE_FILE_RETRY=1 ; ONEDRIVE_FILE_ERRFLAG=0
		if [[ "${BACKUP_DISK}" == *"onedrive"* ]]; then
			until [[ ${ONEDRIVE_FILE_RETRY} -gt ${BACKUP_RETRY_MAX} ]]; do
				LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME} start retry ${ONEDRIVE_FILE_RETRY}"
				ONEDRIVE_FILE_ERRLOG=$(OneDriveUploader -s "${DIR_LOCAL}/${FNAME}" -r "${DIR_ONEDRIVE}")
				ONEDRIVE_FILE_ERRFLAG=$?
				[[ "${ONEDRIVE_FILE_ERRFLAG}" == 0 ]] && (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME} success") && break
				let ONEDRIVE_FILE_RETRY++
				sleep 30
			done
			[[ "${ONEDRIVE_FILE_ERRFLAG}" == 0 ]] || (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME} fail" ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME} fail" > "${DIR_LOCAL}/${FNAME}.onedrivefail.log" ; echo "${ONEDRIVE_FILE_ERRFLAG}" >> "${DIR_LOCAL}/${FNAME}.onedrivefail.log" ; echo "${ONEDRIVE_FILE_ERRLOG}" >> "${DIR_LOCAL}/${FNAME}.onedrivefail.log")
		fi
		ONEDRIVE_LOG_RETRY=1 ; ONEDRIVE_LOG_ERRFLAG=0
		if [[ "${BACKUP_DISK}" == *"onedrive"* ]]; then
			until [[ ${ONEDRIVE_LOG_RETRY} -gt ${BACKUP_RETRY_MAX} ]]; do
				LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME}.log start retry ${ONEDRIVE_LOG_RETRY}"
				ONEDRIVE_LOG_ERRLOG=$(OneDriveUploader -s "${DIR_LOCAL}/${FNAME}.log" -r "${DIR_ONEDRIVE}")
				ONEDRIVE_LOG_ERRFLAG=$?
				[[ "${ONEDRIVE_LOG_ERRFLAG}" == 0 ]] && (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME}.log success") && break
				let ONEDRIVE_LOG_RETRY++
				sleep 30
			done
			[[ "${ONEDRIVE_LOG_ERRFLAG}" == 0 ]] || (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME}.log fail" ; echo "${LOG_PREFIX} upload onedrive ${DIR_LOCAL}/${FNAME}.log fail" > "${DIR_LOCAL}/${FNAME}.log.onedrivefail.log" ; echo "${ONEDRIVE_LOG_ERRFLAG}" >> "${DIR_LOCAL}/${FNAME}.log.onedrivefail.log" ; echo "${ONEDRIVE_LOG_ERRLOG}" >> "${DIR_LOCAL}/${FNAME}.onedrivefail.log")
		fi
		
		BAIDUPAN_FILE_RETRY=1 ; BAIDUPAN_FILE_ERRFLAG="成功"
		if [[ "${BACKUP_DISK}" == *"baidupan"* ]]; then			
			until [[ ${BAIDUPAN_FILE_RETRY} -gt ${BACKUP_RETRY_MAX} ]]; do
				LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME} start retry ${BAIDUPAN_FILE_RETRY}"
				BAIDUPAN_FILE_ERRFLAG=$(BaiduPCS-Go upload "${DIR_LOCAL}/${FNAME}" "${DIR_BAIDUPAN}")
				(echo "${BAIDUPAN_FILE_ERRFLAG}" | grep -q "成功") && (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME} success") && break
				let BAIDUPAN_FILE_RETRY++
				sleep 30
			done
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
			(echo "${BAIDUPAN_FILE_ERRFLAG}" | grep -q "成功") || (echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME} fail" ; echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME} fail" > "${DIR_LOCAL}/${FNAME}.baidupanfail.log" ; echo "${BAIDUPAN_FILE_ERRFLAG}" >> "${DIR_LOCAL}/${FNAME}.baidupanfail.log")
		fi
		BAIDUPAN_LOG_RETRY=1 ; BAIDUPAN_LOG_ERRFLAG="成功"
		if [[ "${BACKUP_DISK}" == *"baidupan"* ]]; then
			until [[ ${BAIDUPAN_LOG_RETRY} -gt ${BACKUP_RETRY_MAX} ]]; do
				LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME}.log start retry ${BAIDUPAN_LOG_RETRY}"
				BAIDUPAN_LOG_ERRFLAG=$(BaiduPCS-Go upload "${DIR_LOCAL}/${FNAME}.log" "${DIR_BAIDUPAN}")
				(echo "${BAIDUPAN_LOG_ERRFLAG}" | grep -q "成功") && (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME}.log success") && break
				let BAIDUPAN_LOG_RETRY++
				sleep 30
			done
			(echo "${BAIDUPAN_FILE_ERRFLAG}" | grep -q "成功") || (LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME}.log fail" ; echo "${LOG_PREFIX} upload baidupan ${DIR_LOCAL}/${FNAME}.log fail" > "${DIR_LOCAL}/${FNAME}.log.baidupanfail.log" ; echo "${BAIDUPAN_LOG_ERRFLAG}" >> "${DIR_LOCAL}/${FNAME}.log.baidupanfail.log")
		fi
		
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") #清除文件
		[[ "${BACKUP}" == *"keep" ]] && (echo "${LOG_PREFIX} force keep ${DIR_LOCAL}/${FNAME}" ; echo "${LOG_PREFIX} force keep ${DIR_LOCAL}/${FNAME}.log")
		[[ "${BACKUP}" == *"del" ]] && (echo "${LOG_PREFIX} force delete ${DIR_LOCAL}/${FNAME}" ; rm -f "${DIR_LOCAL}/${FNAME}" ; echo "${LOG_PREFIX} force delete ${DIR_LOCAL}/${FNAME}.log" ; rm -f "${DIR_LOCAL}/${FNAME}.log")
		[[ "${BACKUP}" == "rclone" || "${BACKUP}" == "onedrive" || "${BACKUP}" == "baidupan" || "${BACKUP}" == *[0-9] ]] && [[ "${RCLONE_FILE_ERRFLAG}" == "" ]] && [[ "${ONEDRIVE_FILE_ERRFLAG}" == 0 ]] && (echo "${BAIDUPAN_FILE_ERRFLAG}" | grep -q "成功") && (echo "${LOG_PREFIX} remove ${DIR_LOCAL}/${FNAME}" ; rm -f "${DIR_LOCAL}/${FNAME}")
		[[ "${BACKUP}" == "rclone" || "${BACKUP}" == "onedrive" || "${BACKUP}" == "baidupan" || "${BACKUP}" == *[0-9] ]] && [[ "${RCLONE_LOG_ERRFLAG}" == "" ]] && [[ "${ONEDRIVE_LOG_ERRFLAG}" == 0 ]] && (echo "${BAIDUPAN_LOG_ERRFLAG}" | grep -q "成功") && (echo "${LOG_PREFIX} remove ${DIR_LOCAL}/${FNAME}.log" ; rm -f "${DIR_LOCAL}/${FNAME}.log")
	fi
	) &
	
	
	
	[[ "${LOOP_TIME}" == "once" ]] && break
	
	if [[ $(date +%s) -lt ${RECORD_ENDTIME} ]]; then
		RECORD_ENDREMAIN=$(( ${RECORD_ENDTIME}-$(date +%s) )) ; [[ RECORD_ENDREMAIN -lt 0 ]] && RECORD_ENDREMAIN=0 #距离应有的最早结束时间的剩余时间
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record end retry after ${RECORD_ENDREMAIN} seconds..."
		sleep ${RECORD_ENDREMAIN}
	fi
done
