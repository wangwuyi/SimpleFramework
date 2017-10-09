#!/bin/sh

#unity的安装目录#
export UNITY_PATH=/Applications/Unity/Unity.app/Contents/MacOS/Unity
 
#游戏工程目录#
export PROJECT_PATH=/Users/wangwuyi/Documents/SSS/client/ThirteenWater

#生成资源目录#
export OUT_BASE_PATH=/Users/wangwuyi/Desktop/ThirteenWater

#时间#
export TIMESTAMP=`date +"%Y%m%d%H%M"`

#输出后的包名#
export GAME_NAME=SSS

#Json配置集
json_array=`cat $PROJECT_PATH/Assets/Editor/ResPack/cfg/PackInfo.json | jq 'keys'`
jsons_len=`expr ${#json_array} - 4` 
jsons=${json_array:2:${jsons_len}}
jsons=${jsons//\"/}
jsons=`echo ${jsons} | sed 's/ //g'`
OLD_IFS="$IFS" 
IFS="," 
arr=(${jsons}) 
IFS="$OLD_IFS"
length=${#arr[@]}

echo "\033[33m选择打包json配置文件名:\033[0m"
for i in "${!arr[@]}";   
do
	index=`expr ${i} + 1`
    echo "\033[32m${index}.${arr[$i]}\033[0m \c"
done
echo ""
while :
do
	read -p "Enter:" json_index
	json_index=`expr ${json_index} - 1`
	if [ $json_index -lt $length ]
	then
	   break
	fi
done
JSON_NAME=${arr[$json_index]}

# 平台Json配置
PLATFORM=`cat $PROJECT_PATH/Assets/Editor/ResPack/cfg/targets/${JSON_NAME}.json | jq '.target'`
PLATFORM=${PLATFORM//\"/}
#输出路径#
OUT_PATH=${OUT_BASE_PATH}/${JSON_NAME}
#补丁路径#
PATCH_PATH=${OUT_PATH}/Patch
TEMP_PATCH=${PATCH_PATH}/Patch_${TIMESTAMP}/

echo "\033[32m1.打包 2.打补丁 3.打包+补丁\033[0m"

while :
do
	read -p "Enter:" manner
	case $manner in
		1|2|3) break ;;
	esac
done

BuildPC(){
	echo "Unity Windows ..."
	exe=${OUT_PATH}/${GAME_NAME}/${GAME_NAME}.exe
	$UNITY_PATH -quit -batchmode -projectPath $PROJECT_PATH -logFile ${OUT_PATH}/unity.log -executeMethod BuildProject.Build ${PLATFORM} ${JSON_NAME} ${exe} ${manner} ${TEMP_PATCH}
	 
	if [[ -f "$exe" ]]; then
		cd ${OUT_PATH}
		#开始进行zip压缩#
		zip -r ${GAME_NAME}_${TIMESTAMP}.zip ${GAME_NAME}
		#删除原文件#
		rm -r ${GAME_NAME}
	else
		echo "Build FAILED !!!"
		exit
	fi
}

BuildAndroid(){
	echo "Unity Android ..."
	apk=${OUT_PATH}/${GAME_NAME}_Android_${TIMESTAMP}.apk
	$UNITY_PATH -quit -batchmode -projectPath $PROJECT_PATH -logFile ${OUT_PATH}/unity.log -executeMethod BuildProject.Build ${PLATFORM} ${JSON_NAME} ${apk} ${manner} ${TEMP_PATCH}
}

BuildIOS(){
	echo "Unity IOS ..."
	ipa=${GAME_NAME}_${TIMESTAMP}.ipa
	export_path=${OUT_PATH}/$ipa
	project_name=SSS_IOS
	project_path=${OUT_PATH}/${project_name}

	# $UNITY_PATH -quit -batchmode -projectPath $PROJECT_PATH -logFile ${OUT_PATH}/unity.log -executeMethod BuildProject.Build ${PLATFORM} ${JSON_NAME} ${project_path} ${manner} ${TEMP_PATCH}
	
	echo "Export IPA ..."
	target_name="Unity-iPhone"
	build_path="${GAME_NAME}_build/"
	cd $project_path
	rm -rf $build_path
	rm $ipa
	xcodebuild -target $target_name -sdk iphoneos -configuration Release ARCHS="armv7 armv64" CONFIGURATION_BUILD_DIR=$build_path
	xcodebuild -scheme $target_name archive -archivePath $build_path/target.xcarchive -destination generic/platform=iOS
	xcodebuild -exportArchive -archivePath $build_path/target.xcarchive -exportPath $export_path -exportOptionsPlist ${OUT_PATH}/exportOptions.plist
	rm -rf $build_path
}

if [ "$PLATFORM" == "windows" ] 
then
	BuildPC
elif [ "$PLATFORM" == "android" ]  
then
	BuildAndroid
elif [ "$PLATFORM" == "ios" ]  
then
	BuildIOS
fi

if [ $manner -eq 2 -o $manner -eq 3 ]
then
	if [ -d "$TEMP_PATCH" ]; then
		cd ${PATCH_PATH}
		#开始进行zip压缩#
		zip -r ${GAME_NAME}_PATCH_${TIMESTAMP}.zip Patch_${TIMESTAMP}
		#删除原文件#
		rm -r Patch_${TIMESTAMP}
	else
		echo "Patch FAILED !!!"
		exit
	fi
fi

#打开文件夹#
open ${OUT_PATH}