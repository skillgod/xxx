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
	
	if [[ "${1}" == "youtube-dl" ]]; then
		(youtube-dl --cookies ./cookies.txt --ignore-errors --embed-thumbnail -x --audio-quality 0 -f 'best[height<=480]' -o '%(uploader)s/%(upload_date)s_%(title)s.%(ext)s' "https://www.youtube.com/watch?v=${ID}" 2>/dev/null)
	fi
	
	RECORD_PID=$! #录制进程PID
	RECORD_STOPTIME=$(( $(date +%s)+${LOOP_TIME} )) #录制结束时间戳
	RECORD_ENDTIME=$(( $(date +%s)+${ENDINTERVAL} )) #录制循环结束的最早时间
	LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record start pid=${RECORD_PID} looptime=${LOOP_TIME} url=${STREAM_URL}" #开始录制
	sleep 15
	kill ${RECORD_PID}
	
	[[ "${LOOP_TIME}" == "once" ]] && break
	
	if [[ $(date +%s) -lt ${RECORD_ENDTIME} ]]; then
		RECORD_ENDREMAIN=$(( ${RECORD_ENDTIME}-$(date +%s) )) ; [[ RECORD_ENDREMAIN -lt 0 ]] && RECORD_ENDREMAIN=0 #距离应有的最早结束时间的剩余时间
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} record end retry after ${RECORD_ENDREMAIN} seconds..."
		sleep ${RECORD_ENDREMAIN}
	fi
done
