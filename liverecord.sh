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
BACKUP="${7:-nobackup}" #自动备份
BACKUP_DISK="$(echo "${BACKUP}" | awk -F":" '{print $1}')$(echo "${BACKUP}" | awk -F":" '{print $NF}')" ; DIR_RCLONE="$(echo "${BACKUP}" | awk -F":" '{print $2}'):${DIR_LOCAL}" ; DIR_ONEDRIVE="${DIR_LOCAL}" ; DIR_BAIDUPAN="${DIR_LOCAL}" #选择网盘与网盘路径
BACKUP_RETRY_MAX=$(echo "${BACKUP}" | awk -F":" '{print $NF}' | grep -o "[0-9]*") ; [[ ! -n "${BACKUP_RETRY_MAX}" ]] && BACKUP_RETRY_MAX=1 #自动备份重试次数
EXCEPT_YOUTUBE_PART_URL="${8:-noexcept}" #排除转播的频道号码
EXCEPT_TWITCAST_PART_URL="${9:-noexcept}"
EXCEPT_TWITCH_PART_URL="${10:-noexcept}"
EXCEPT_OPENREC_PART_URL="${11:-noexcept}"
EXCEPT_NICOLV_PART_URL="${12:-noexcept}"
EXCEPT_NICOCO_PART_URL="${13:-noexcept}"
EXCEPT_NICOCH_PART_URL="${14:-noexcept}"
EXCEPT_MIRRATIV_PART_URL="${15:-noexcept}"
EXCEPT_REALITY_PART_URL="${16:-noexcept}"
EXCEPT_17LIVE_PART_URL="${17:-noexcept}"
EXCEPT_CHATURBATE_PART_URL="${18:-noexcept}"
EXCEPT_STREAM_PART_URL="${19:-noexcept}"

[[ "${1}" == "youtube"* ]] && FULL_URL="https://www.youtube.com/channel/${PART_URL}/live"
[[ "${1}" == "twitcast"* ]] && FULL_URL="https://twitcasting.tv/${PART_URL}"
[[ "${1}" == "twitch" ]] && FULL_URL="https://twitch.tv/${PART_URL}"
[[ "${1}" == "openrec" ]] && FULL_URL="https://openrec.tv/user/${PART_URL}"
[[ "${1}" == "nicolv"* ]] && FULL_URL="https://live.nicovideo.jp/gate/${PART_URL}"
[[ "${1}" == "nicoco"* ]] && FULL_URL="https://com.nicovideo.jp/community/${PART_URL}"
[[ "${1}" == "nicoch"* ]] && FULL_URL="https://ch.nicovideo.jp/${PART_URL}/live"
[[ "${1}" == "mirrativ" ]] && FULL_URL="https://www.mirrativ.com/user/${PART_URL}"
[[ "${1}" == "reality" ]] && FULL_URL="reality_${PART_URL}"
[[ "${1}" == "17live" ]] && FULL_URL="https://17.live/live/${PART_URL}"
[[ "${1}" == "chaturbate" ]] && FULL_URL="https://chaturbate.com/${PART_URL}/"
[[ "${1}" == "bilibili"* ]] && FULL_URL="https://live.bilibili.com/${PART_URL}"
[[ "${1}" == "streamlink" ]] && FULL_URL="${PART_URL}"
[[ "${1}" == "m3u8" ]] && FULL_URL="${PART_URL}"

[[ "${EXCEPT_YOUTUBE_PART_URL}" == "noexcept" ]] || EXCEPT_YOUTUBE_FULL_URL="https://www.youtube.com/channel/${EXCEPT_YOUTUBE_PART_URL}/live"
[[ "${EXCEPT_TWITCAST_PART_URL}" == "noexcept" ]] || EXCEPT_TWITCAST_FULL_URL="https://twitcasting.tv/${EXCEPT_TWITCAST_PART_URL}"
[[ "${EXCEPT_TWITCH_PART_URL}" == "noexcept" ]] || EXCEPT_TWITCH_FULL_URL="https://twitch.tv/${EXCEPT_TWITCH_PART_URL}"
[[ "${EXCEPT_OPENREC_PART_URL}" == "noexcept" ]] || EXCEPT_OPENREC_FULL_URL="https://openrec.tv/user/${EXCEPT_OPENREC_PART_URL}"
[[ "${EXCEPT_NICOLV_PART_URL}" == "noexcept" ]] || EXCEPT_NICOLV_FULL_URL="https://live.nicovideo.jp/gate/${EXCEPT_NICOLV_PART_URL}"
[[ "${EXCEPT_NICOCO_PART_URL}" == "noexcept" ]] || EXCEPT_NICOCO_FULL_URL="https://com.nicovideo.jp/community/${EXCEPT_NICOCO_PART_URL}"
[[ "${EXCEPT_NICOCH_PART_URL}" == "noexcept" ]] || EXCEPT_NICOCH_FULL_URL="https://ch.nicovideo.jp/${EXCEPT_NICOCH_PART_URL}"
[[ "${EXCEPT_MIRRATIV_PART_URL}" == "noexcept" ]] || EXCEPT_MIRRATIV_FULL_URL="https://www.mirrativ.com/user/${EXCEPT_OPENREC_PART_URL}"
[[ "${EXCEPT_REALITY_PART_URL}" == "noexcept" ]] || EXCEPT_REALITY_FULL_URL="reality_${PART_URL}"
[[ "${EXCEPT_17LIVE_PART_URL}" == "noexcept" ]] || EXCEPT_17LIVE_FULL_URL="https://17.live/live/${EXCEPT_17LIVE_PART_URL}"
[[ "${EXCEPT_CHATURBATE_PART_URL}" == "noexcept" ]] || EXCEPT_CHATURBATE_FULL_URL="https://chaturbate.com/${EXCEPT_CHATURBATE_PART_URL}/"
[[ "${EXCEPT_STREAM_PART_URL}" == "noexcept" ]] || EXCEPT_STREAM_FULL_URL="${EXCEPT_STREAM_PART_URL}"



LIVE_STATUS=0
ISLIVE_YOUTUBE=0
while true; do
	while true; do
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${FULL_URL}"
		if [[ "${1}" == "youtube"* ]]; then
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata islive_youtube=${ISLIVE_YOUTUBE}"
			if [[ ${ISLIVE_YOUTUBE} -gt 0 ]]; then
				if (wget -q -O- "${FULL_URL}" | grep "ytplayer" | grep -q '\\"isLive\\":true'); then
					let LIVE_STATUS++ ; ISLIVE_YOUTUBE=3 #qualityLabel开播早下播晚会在下播时多录，isLive开播晚下播早会在开播时晚录
				else
					LIVE_STATUS=0 ; let ISLIVE_YOUTUBE--
				fi
			else
				if (wget -q -O- "${FULL_URL}" | grep -q '\\"qualityLabel\\":\\"[0-9]*p\\"'); then
					let LIVE_STATUS++ ; ISLIVE_YOUTUBE=3
				else
					LIVE_STATUS=0
				fi
			fi
			#(wget -q -O- "${FULL_URL}" | grep -q '\\"playabilityStatus\\":{\\"status\\":\\"OK\\"') && break
		fi
		if [[ "${1}" == "twitcast"* ]]; then
			if (wget -q -O- "https://twitcasting.tv/streamserver.php?target=${PART_URL}&mode=client" | grep -q '"live":true'); then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		if [[ "${1}" == "twitch" ]]; then
			STREAM_URL=$(streamlink --stream-url "${FULL_URL}" "${FORMAT}")
			if (echo "${STREAM_URL}" | grep -q ".m3u8"); then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		if [[ "${1}" == "openrec" ]]; then
			LIVE_URL=$(wget -q -O- "${FULL_URL}" | grep -o 'href="https://www.openrec.tv/live/.*" class' | head -n 1 | awk -F'"' '{print $2}')
			if [[ -n "${LIVE_URL}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		
		if [[ "${1}" == "nicolv"* ]]; then
			LIVE_URL=$(curl -s -I "https://live.nicovideo.jp/gate/${PART_URL}" | grep -o "https://live2.nicovideo.jp/watch/lv[0-9]*")
			if [[ -n "${LIVE_URL}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		if [[ "${1}" == "nicoco"* ]]; then
			LIVE_URL=$(wget -q -O- "https://com.nicovideo.jp/community/${PART_URL}" | grep -o '<a class="now_live_inner" href="https://live.nicovideo.jp/watch/lv[0-9]*' | head -n 1 | awk -F'"?' '{print $4}')
			if [[ -n "${LIVE_URL}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		if [[ "${1}" == "nicoch"* ]]; then
			LIVE_URL=$(wget -q -O- "https://ch.nicovideo.jp/${PART_URL}/live" | awk 'BEGIN{RS="<section class=";FS="\n";ORS="\n";OFS="\t"} $1 ~ /sub now/ {LIVE_POS=match($0,"https://live.nicovideo.jp/watch/lv[0-9]*");LIVE=substr($0,LIVE_POS,RLENGTH);print LIVE}' | head -n 1)
			if [[ -n "${LIVE_URL}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
			LIVE_ID=$(wget -q -O- "https://ch.nicovideo.jp/${PART_URL}" | grep -o "data-live_id=\"[0-9]*\" data-live_status=\"onair\"" | head -n 1 | awk -F'"' '{print $2}') ; LIVE_URL="https://live.nicovideo.jp/watch/lv${LIVE_ID}"
			if [[ -n "${LIVE_ID}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		
		if [[ "${1}" == "mirrativ" ]]; then
			LIVE_URL=$(wget -q -O- "https://www.mirrativ.com/api/user/profile?user_id=${PART_URL}" | grep -o '"live_id":".*"' | awk -F'"' '{print $4}')
			if [[ -n "${LIVE_URL}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		if [[ "${1}" == "reality" ]]; then
			STREAM_ID=$(curl -s -X POST "https://media-prod-dot-vlive-prod.appspot.com/api/v1/media/lives_user" | awk -v PART_URL="${PART_URL}" 'BEGIN{RS="\"StreamingServer\"";FS=",";ORS="\n";OFS="\t"} {M3U8_POS=match($0,"\"view_endpoint\":\"[^\"]*\"");M3U8=substr($0,M3U8_POS,RLENGTH) ; ID_POS=match($0,"\"vlive_id\":\"[^\"]*\"");ID=substr($0,ID_POS,RLENGTH) ; if(match($0,"\"nickname\":\"[^\"]*"PART_URL"[^\"]*\"|\"vlive_id\":\""PART_URL"\"")) print M3U8,ID}' | head -n 1)
			if [[ -n "${STREAM_ID}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		if [[ "${1}" == "17live" ]]; then
			LIVE_STATUS=$(curl -s -X POST 'http://api-dsa.17app.co/api/v1/liveStreams/getLiveStreamInfo' --data "{\"liveStreamID\": ${PART_URL}}" | grep -o '\\"closeBy\\":\\"\\"')
			if [[ -n "${LIVE_STATUS}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		if [[ "${1}" == "chaturbate" ]]; then
			LIVE_URL=$(curl -s "https://chaturbate.com/${PART_URL}/" | grep -o "https://edge[0-9]*.stream.highwebmedia.com.*/playlist.m3u8" | sed 's/\\u002D/-/g')
			if [[ -n "${LIVE_URL}" ]]; then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		
		if [[ "${1}" == "streamlink" ]]; then
			STREAM_URL=$(streamlink --stream-url "${FULL_URL}" "${FORMAT}")
			if (echo "${STREAM_URL}" | grep -Eq ".m3u8|.flv|rtmp:|The stream specified cannot be translated to a URL"); then let LIVE_STATUS++; else LIVE_STATUS=0; fi
		fi
		
		if [[ "${1}" == "bilibili"* ]]; then
			if (wget -q -O- "https://api.live.bilibili.com/room/v1/Room/get_info?room_id=${PART_URL}" | grep -q '"live_status":1'); then
				if [[ "${EXCEPT_YOUTUBE_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_YOUTUBE_FULL_URL}" #检测排除直播
					(wget -q -O- "${EXCEPT_YOUTUBE_FULL_URL}" | grep -q '\\"qualityLabel\\":\\"[0-9]*p\\"') && echo "${LOG_PREFIX} restream from ${EXCEPT_YOUTUBE_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_TWITCAST_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_TWITCAST_FULL_URL}"
					(wget -q -O- "https://twitcasting.tv/streamserver.php?target=${EXCEPT_TWITCAST_PART_URL}&mode=client" | grep -q '"live":true') && echo "${LOG_PREFIX} restream from ${EXCEPT_TWITCAST_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_TWITCH_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_TWITCH_FULL_URL}"
					EXCEPT_TWITCH_STREAM_URL=$(streamlink --stream-url "${EXCEPT_TWITCH_FULL_URL}" "${FORMAT}")
					(echo "${EXCEPT_TWITCH_STREAM_URL}" | grep -q ".m3u8") && echo "${LOG_PREFIX} restream from ${EXCEPT_TWITCH_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_OPENREC_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]")
					echo "${LOG_PREFIX} metadata ${EXCEPT_OPENREC_FULL_URL}"
					EXCEPT_OPENREC_LIVE_URL=$(wget -q -O- "${EXCEPT_OPENREC_FULL_URL}" | grep -o 'href="https://www.openrec.tv/live/.*" class' | head -n 1 | awk -F'"' '{print $2}')
					[[ -n "${EXCEPT_OPENREC_LIVE_URL}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_OPENREC_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				
				if [[ "${EXCEPT_NICOLV_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_NICOLV_FULL_URL}"
					EXCEPT_NICOLV_LIVE_URL=$(curl -s -I "https://live.nicovideo.jp/gate/${EXCEPT_NICOLV_PART_URL}" | grep -o "https://live2.nicovideo.jp/watch/lv[0-9]*")
					[[ -n "${EXCEPT_NICOLV_LIVE_URL}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_NICOLV_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_NICOCO_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_NICOCO_FULL_URL}"
					EXCEPT_NICOCO_LIVE_URL=$(wget -q -O- "https://com.nicovideo.jp/community/${EXCEPT_NICOCO_PART_URL}" | grep -o '<a class="now_live_inner" href="https://live.nicovideo.jp/watch/lv[0-9]*' | head -n 1 | awk -F'"?' '{print $4}')
					[[ -n "${EXCEPT_NICOCO_LIVE_URL}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_NICOCO_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_NICOCH_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_NICOCH_FULL_URL}"
					EXCEPT_NICOCH_LIVE_URL=$(wget -q -O- "https://ch.nicovideo.jp/${EXCEPT_NICOCH_PART_URL}/live" | awk 'BEGIN{RS="<section class=";FS="\n";ORS="\n";OFS="\t"} $1 ~ /sub now/ {LIVE_POS=match($0,"https://live.nicovideo.jp/watch/lv[0-9]*");LIVE=substr($0,LIVE_POS,RLENGTH);print LIVE}' | head -n 1)
					[[ -n "${EXCEPT_NICOCH_LIVE_URL}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_NICOCH_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
					EXCEPT_NICOCH_LIVE_ID=$(wget -q -O- "https://ch.nicovideo.jp/${EXCEPT_NICOCH_PART_URL}" | grep -o "data-live_id=\"[0-9]*\" data-live_status=\"onair\"" | head -n 1 | awk -F'"' '{print $2}') ; LIVE_URL="https://live.nicovideo.jp/watch/lv${LIVE_ID}"
					[[ -n "${EXCEPT_NICOCH_LIVE_ID}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_NICOCH_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				
				if [[ "${EXCEPT_MIRRATIV_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_MIRRATIV_FULL_URL}"
					EXCEPT_MIRRATIV_LIVE_URL=$(wget -q -O- "https://www.mirrativ.com/api/user/profile?user_id=${EXCEPT_MIRRATIV_PART_URL}" | grep -o '"live_id":".*"' | awk -F'"' '{print $4}')
					[[ -n "${EXCEPT_MIRRATIV_LIVE_URL}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_MIRRATIV_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_REALITY_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_REALITY_FULL_URL}"
					EXCEPT_REALITY_STREAM_URL=$(curl -s -X POST "https://media-prod-dot-vlive-prod.appspot.com/api/v1/media/lives_user" | awk -v PART_URL="${EXCEPT_REALITY_PART_URL}" 'BEGIN{RS="\"StreamingServer\"";FS=",";ORS="\n";OFS="\t"} {M3U8_POS=match($0,"\"view_endpoint\":\"[^\"]*\"");M3U8=substr($0,M3U8_POS,RLENGTH) ;ID_POS=match($0,"\"vlive_id\":\"[^\"]*\"");ID=substr($0,ID_POS,RLENGTH);if(match($0,"\"nickname\":\"[^\"]*"PART_URL"[^\"]*\"|\"vlive_id\":\""PART_URL"\"")) print M3U8,ID}' | head -n 1)
					[[ -n "${EXCEPT_REALITY_STREAM_URL}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_REALITY_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_17LIVE_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_17LIVE_FULL_URL}"
					EXCEPT_17LIVE_LIVE_STATUS=$(curl -s -X POST 'http://api-dsa.17app.co/api/v1/liveStreams/getLiveStreamInfo' --data "{\"liveStreamID\": ${EXCEPT_17LIVE_PART_URL}}" | grep -o '\\"closeBy\\":\\"\\"')
					[[ -n "${EXCEPT_17LIVE_LIVE_STATUS}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_17LIVE_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_CHATURBATE_PART_URL}" != "noexcept" ]]; then
					EXCEPT_CHATURBATE_LIVE_URL=$(curl -s "https://chaturbate.com/${EXCEPT_CHATURBATE_PART_URL}/" | grep -o "https://edge[0-9]*.stream.highwebmedia.com.*/playlist.m3u8" | sed 's/\\u002D/-/g')
					[[ -n "${EXCEPT_CHATURBATE_LIVE_URL}" ]] && echo "${LOG_PREFIX} restream from ${EXCEPT_CHATURBATE_FULL_URL} retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				if [[ "${EXCEPT_STREAM_PART_URL}" != "noexcept" ]]; then
					LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata ${EXCEPT_STREAM_FULL_URL}"
					EXCEPT_STREAM_STREAM_URL=$(streamlink --stream-url "${EXCEPT_STREAM_FULL_URL}" "${FORMAT}")
					(echo "${EXCEPT_STREAM_STREAM_URL}" | grep -Eq ".m3u8|.flv|rtmp:|The stream specified cannot be translated to a URL") && echo "${LOG_PREFIX} restream from ${EXCEPT_STREAM_FULL_URL}. retry after ${LOOPINTERVAL} seconds..." && sleep ${LOOPINTERVAL} && continue
				fi
				
				let LIVE_STATUS++
			else
				LIVE_STATUS=0
			fi
		fi
		
		if [[ "${1}" == "m3u8" ]]; then
			break
		fi
		
		LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} metadata livestatus=${LIVE_STATUS}"
		[[ ! ${LIVE_STATUS} -lt ${LIVESTATUSMIN} ]] && break #连续检测到直播才进行录制
		sleep ${LOOPINTERVAL}
	done
	
	
	
	if [[ "${1}" == "youtube"* ]]; then ID=$(wget -q -O- "${FULL_URL}" | grep -o '\\"liveStreamabilityRenderer\\":{\\"videoId\\":\\".*\\"' | head -n 1 | sed 's/\\//g' | awk -F'"' '{print $6}') ; FNAME="youtube_${PART_URL}_$(date +"%Y%m%d_%H%M%S")_${ID}.ts"; fi
	if [[ "${1}" == "youtubeffmpeg" ]]; then STREAM_URL=$(streamlink --stream-url "${FULL_URL}" "${FORMAT}"); fi
	if [[ "${1}" == "twitcast"* ]]; then ID=$(wget -q -O- "https://twitcasting.tv/streamserver.php?target=${PART_URL}&mode=client" | grep -o '"id":[0-9]*' | awk -F':' '{print $2}') ; DLNAME="${PART_URL/:/：}_${ID}.ts" ; FNAME="twitcast_${PART_URL/:/：}_$(date +"%Y%m%d_%H%M%S")_${ID}.ts"; fi
	if [[ "${1}" == "twitcastffmpeg" ]]; then STREAM_URL=$(wget -q -O- "https://twitcasting.tv/${PART_URL}/metastream.m3u8?mode=source" | grep ".m3u8" | head -n 1); fi
	if [[ "${1}" == "twitcastpy" ]]; then STREAM_URL="wss://$(wget -q -O- "https://twitcasting.tv/streamserver.php?target=${PART_URL}&mode=client" | grep -o '"fmp4":{"host":"[^"]*"' | awk -F'"' '{print $6}')/ws.app/stream/${ID}/fmp4/bd/1/1500?mode=source"; fi
	if [[ "${1}" == "twitch" ]]; then FNAME="twitch_${PART_URL}_$(date +"%Y%m%d_%H%M%S").ts"; fi
	if [[ "${1}" == "openrec" ]]; then STREAM_URL=$(streamlink --stream-url "${LIVE_URL}" "${FORMAT}") ; FNAME="openrec_${PART_URL}_$(date +"%Y%m%d_%H%M%S").ts"; fi
	
	if [[ "${1}" == "nico"* ]]; then ID=$(echo ${LIVE_URL} | grep -o "lv[0-9]*") ; DLNAME="niconico_${PART_URL}_$(date +"%Y%m%d_%H%M%S")_${ID}" ; FNAME="niconico_${PART_URL}_$(date +"%Y%m%d_%H%M%S")_${ID}.ts"; fi
	
	if [[ "${1}" == "mirrativ" ]]; then STREAM_URL=$(wget -q -O- "https://www.mirrativ.com/api/live/live?live_id=${LIVE_URL}" | grep -o '"streaming_url_hls":".*m3u8"' | awk -F'"' '{print $4}') ; FNAME="mirrativ_${PART_URL}_$(date +"%Y%m%d_%H%M%S").ts"; fi
	if [[ "${1}" == "reality" ]]; then ID=$(echo ${STREAM_ID} | awk -F'"' '{print $8}') ; STREAM_URL=$(echo ${STREAM_ID} | awk -F'"' '{print $4}') ; FNAME="reality_${ID}_$(date +"%Y%m%d_%H%M%S").ts"; fi
	if [[ "${1}" == "17live" ]]; then STREAM_URL=$(curl -s -X POST 'http://api-dsa.17app.co/api/v1/liveStreams/getLiveStreamInfo' --data "{\"liveStreamID\": ${PART_URL}}" | grep -o '\\"webUrl\\":\\"[^\\]*' | awk -F'\"' '{print $4}') ; FNAME="17live_${PART_URL}_$(date +"%Y%m%d_%H%M%S").ts"; fi
	if [[ "${1}" == "chaturbate" ]]; then STREAM_URL="${LIVE_URL/playlist.m3u8/}$(curl -s "${LIVE_URL}" | tail -n 1)" ; FNAME="chaturbate_${PART_URL}_$(date +"%Y%m%d_%H%M%S").ts"; fi
	if [[ "${1}" == "streamlink" ]]; then FNAME="stream_$(date +"%Y%m%d_%H%M%S").ts"; fi

	if [[ "${1}" == "bilibili"* ]]; then DLNAME="bilibili_${PART_URL}_$(date +"%Y%m%d_%H%M%S")" ; FNAME="bilibili_${PART_URL}_$(date +"%Y%m%d_%H%M%S").flv"; fi
	if [[ "${1}" == "bilibiliproxy"* ]]; then
		if [[ -n "${STREAM_PROXY_HARD}" ]]; then
			STREAM_PROXY="${STREAM_PROXY_HARD}"
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} proxy ${STREAM_PROXY}"
		else
			STREAM_PROXY=$(curl -s "http://http.tiqu.alicdns.com/getip3?num=1&type=1&pro=&city=0&yys=0&port=1&time=2&ts=0&ys=0&cs=0&lb=4&sb=0&pb=4&mr=1&regions=&gm=4")
			#STREAM_PROXY=$(curl -s "http://ip.11jsq.com/index.php/api/entry?method=proxyServer.generate_api_url&packid=0&fa=0&fetch_key=&groupid=0&qty=1&time=3&pro=&city=&port=1&format=txt&ss=3&css=&dt=1&specialTxt=3&specialJson=&usertype=14") #可替换为任意代理获取方法
			LOG_PREFIX=$(date +"[%Y-%m-%d %H:%M:%S]") ; echo "${LOG_PREFIX} proxy renew ${STREAM_PROXY}"
		fi
	fi
	#STREAM_URL=$(wget -q -O- "https://api.live.bilibili.com/room/v1/Room/playUrl?cid=${PART_URL}&qn=10000&platform=web" | grep -o "\"url\":\"[^\"]*\"" | head -n 1 | awk -F"\"" '{print $4}' | sed 's/\\u0026/\&/g'); fi
	#STREAM_URL=$(curl -s --proxy ${STREAM_PROXY} "https://api.live.bilibili.com/room/v1/Room/playUrl?cid=${PART_URL}&qn=10000&platform=web" | grep -o "\"url\":\"[^\"]*\"" | grep "https://txy.live-play.acgvideo.com\|https://js.live-play.acgvideo.com\|https://ws.live-play.acgvideo.com" | head -n 1 | awk -F"\"" '{print $4}' | sed 's/\\u0026/\&/g')
	
	if [[ "${1}" == "m3u8" ]]; then STREAM_URL="${FULL_URL}" ; FNAME="m3u8_$(date +"%Y%m%d_%H%M%S").ts"; fi
	
	
	
	if [[ "${1}" == "youtube" ]]; then
		if [[ ${ISLIVE_YOUTUBE_BEFORE} -gt 0 ]]; then
			(streamlink --loglevel trace -o "${DIR_LOCAL}/${FNAME}" "https://www.youtube.com/watch?v=${ID}" "${FORMAT}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
		else
			(streamlink --loglevel trace --hls-live-restart -o "${DIR_LOCAL}/${FNAME}" "https://www.youtube.com/watch?v=${ID}" "${FORMAT}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
		fi
	fi
	if [[ "${1}" == "youtube-dl" ]]; then
		(youtube-dl --ignore-errors --embed-thumbnail -x --audio-quality 0 -f 'best[height<=480]' -o '%(uploader)s/%(release_date)s_%(upload_date)s_%(title)s.%(ext)s' "https://www.youtube.com/watch?v=${ID}" 2>/dev/null)
	fi
	if [[ "${1}" == "twitcast" ]]; then
		(livedl/livedl -tcas "${PART_URL}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
	fi
	if [[ "${1}" == "twitcastpy" ]]; then
		(python3 record/record_twitcast.py "${STREAM_URL}" "${DIR_LOCAL}/${FNAME}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
	fi
	
	if [[ "${1}" == "nico"* ]]; then
		if [[ -n "${NICO_ID_PSW}" ]]; then
			(livedl/livedl -nico-login-only=on -nico-login "${NICO_ID_PSW}" -nico-force-reservation=on -nico-limit-bw 0 -nico-format "${DLNAME}" -nico "${LIVE_URL}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
		else
			(livedl/livedl -nico-login-only=off -nico-force-reservation=on -nico-limit-bw 0 -nico-format "${DLNAME}" -nico "${LIVE_URL}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
		fi
	fi
	
	if [[ "${1}" == "bilibili" ]]; then
		(you-get --debug -O "${DIR_LOCAL}/${DLNAME}" "${FULL_URL}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
	fi
	if [[ "${1}" == "bilibiliproxy"* ]]; then
		(you-get --debug --http-proxy "${STREAM_PROXY}" -O "${DIR_LOCAL}/${DLNAME}" "${FULL_URL}" > "${DIR_LOCAL}/${FNAME}.log" 2>&1) &
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
