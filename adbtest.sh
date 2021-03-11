#!/bin/bash
##########################################################################
# AUTHOR   : DC-Melo
# MAIL     : melo.da.chor@gmail.com
# BLOG     : www.dc-melo.com
# FILE     : adb-test.sh
# CREATED  : 2020-11-14 16:23
# MODIFIED : 2020-11-14 16:23
# VERSION  : V-0.0.1.201114_a: ;
# DESCRIB  : 
# NOTICES  : 
##########################################################################
# 打印帮助信息
usage() {
cat >&1 <<-EOF
##########################################################################
# 作者    : DC-Melo 王江
# 邮件    : melo.da.chor@gmail.com
# 博客    : www.dc-melo.com
# 文件名称: adb-test.sh         
# 创建时间: 2020-11-13 21:37    
# 修改时间: 2020-11-13 21:37    
# 版本编号: V-0.0.1.201113_a: ; 
# 使用描述:                     
# 注意事项:                     
##########################################################################
请使用: $0 <option>

可使用的参数 <option> 包括:

        root            获取root，remount，等相关权限
        version         获取APK版本号，系统属性
        log             获取系统log
        screencap       截取屏幕
        CPU             获取进程CPU
        GPU             获取系统GPU
        memory          获取进程memory
        fps             获取屏幕刷新帧数
        activity        启动应用程序(默认原生界面)
        kill            杀死当前界面
        help            查看脚本使用说明
EOF
}

# 获取设备列表
do_get_devices(){
    devices_list=`adb devices -l | awk '{if($2=="device"){print $1}}'`
	echo ${devices_list}
    if [ ! -n "${devices_list}" ];then
        echo '没有找到android设备，请输入 "adb device -l" 确认adb已经打开!'
        read -p "任意键退出..." temp
        exit 
    fi
    return 0
}

# 获取root等相关权限
do_root(){
    for device in ${devices_list}
    do
        # root and remount devices
        adb -s ${device} root
        adb -s ${device} enable-verity
        adb -s ${device} remount
        adb -s ${device} shell setprop bdcarsec.pm.install 0
        adb -s ${device} shell setprop persist.bluetooth.enablenewavrcp true
		adb -s ${device} shell setprop persist.bluetooth.btsnoopenable true
        echo "root ${device}"
    done
    return 0
}

# 安装该文件夹下的apk
do_install(){
    return 0
}

# 获取版本号
do_version(){
    module_name="version"
    def_conf="wecarspeech.data.version\n
    system TUID\n
    wecar.id\n
    ro.build.fingerprint\n
    ro.build.product\n
    com.wt.\n
    com.autopai.\n
    com.tencent.\n
    com.wutong.\n
    com.wtcl.\n"
    # for every devices
    for device in ${devices_list}
    do
        # testing and save to info file
        # read -p "请输入设备(${device})项目名称:" project
        conf_file="${project}_version_config.txt"
        if [ ! -f "${conf_file}" ];then
            echo -e ${def_conf} > "${conf_file}"
            echo "创建${module_name}配置文件${conf_file}!您可以修改配置文件，提取不同包名的版本号"
        fi
        sed -i 's/^[ \t]*//;s/ //g;s/[ \t]*$//;/^[ \t]*$/d' "${conf_file}"
        info_file="${project}_${module_name}_info_"`date +%Y%m%d%H%M%S`".txt"
        report_file="${project}_${module_name}_report_"`date +%Y%m%d%H%M%S`".txt"
        # start test
        speechdata_version=`adb -s ${device} shell "cat //mnt/sdcard/tencent/wecarspeech/data/data.version"`
        TUID=`adb -s ${device} shell "settings get system TUID"`
        speechdata3_version=`adb -s ${device} shell "cat //sdcard/tencent/wecarspeech/data3/data.version"`
        wecar_id=`adb -s ${device} shell "cat //data/data/com.tencent.wecarnavi/shared_prefs/wecarbase_sp_wecar_account.xml|grep wecar_id"`
        adb -s ${device} shell "dumpsys package" | awk '
        {
            if($0 ~ /Package *\[.*/){
                find_package=0;
                package_name=$2;
            }
            if($0 ~ /versionName=.*/){
                find_package++;
                if(find_package==1){
                    printf("%s %s\n",package_name,$1); 
                }
            }
        }'                                                      >> "${info_file}"
        echo "wecarspeech.data.version=${speechdata_version}"   >> "${info_file}"
        echo "system TUID=${TUID}"                              >> "${info_file}"
        echo "wecarspeech.data3.version=${speechdata3_version}" >> "${info_file}"
        echo "wecar.id=${wecar_id}"                             >> "${info_file}"
        adb -s $device shell "cat /system/build.prop" >> "${info_file}"
        # format info_file
        sed -i 's/\[//;s/\]\ versionName//;s/^[ \t]*//;s/[ \t]*$//;/^[ \t]*$/d;/^#/d;' "${info_file}"
        # sed -i 's/\[//g' "${info_file}"
        # sed -i 's/\]\ versionName//g' "${info_file}"
        # sed -i '/^\s*$/d' "${info_file}"
        # sed -i '/^#/d' "${info_file}"

        # make test report
        echo "project: ${project}"                  >> "${report_file}"
        grep -f "${conf_file}" "${info_file}"       >> "${report_file}"
        cat ${report_file}
        echo -e "\n\n\nall other apk version and property value as below"   >> "$report_file"
        echo "===================================================="         >> "$report_file"
        cat ${info_file} >> ${report_file}
        rm ${info_file}
    done
    return 0
}

# log             获取系统log
do_log(){
    module_name="log"
    script_log='没有复制到日志请查看这个文件.txt'
    def_conf="
    /data/anr                                   \n
    /data/bootdmesg                             \n
    /data/brlink/btsnoop.log                    \n
    /data/data/com.wt.music/databases           \n
    /data/logger                                \n
    /data/media/btsnoop.log                     \n
    /data/media/mcu_log.log                     \n
    /data/misc/update_engine_log                \n
    /data/system/dropbox                        \n
    /data/tombstones                            \n
    /data/vendor/kmsgd                          \n
    /resources/mtklog                           \n
    /sdcard/btsnoop_hci.log                     \n
    /sdcard/LOG                                 \n
    /sdcard/RouteGuidance                       \n
    /sdcard/tencent/autowechat/log              \n
    /sdcard/tencent/MicroMsg/xlog               \n
    /sdcard/tencent/wecarbase/log               \n
    /sdcard/tencent/wecarnavi/glmaplog          \n
    /sdcard/tencent/wecarspeech/log             \n
    /sdcard/tencent/wecarnavi/log               \n
    /sdcard/tencent/wecarnavi/pangu             \n
    # mtk 202_ica 项目语音路径                   \n
    /storage/emulated/0/tencent/wecarspeech     \n
    /sdcard/WTLog                               \n
    /user_data/tencent/wecarnavi/reflux         \n
    # 录音文件                                  \n
    /sdcard/tencent/wecarspeech/data/dingdang   \n
    # 202微信                                   \n
    /storage/emulated/0/tencent                 \n
#    /storage/emulated/0/tencent/autowechat      \n
#    /storage/emulated/0/tencent/MicroMsg/xlog   \n
    "
    # for every devices
    for device in ${devices_list}
    do
        # testing and save to info file
        # read -p "请输入设备(${device})项目名称:" project
        conf_file="${project}_${module_name}_config.txt"
        if [ ! -f "${conf_file}" ];then
            echo -e ${def_conf} > "${conf_file}"
            echo "创建${module_name}配置文件${conf_file}!您可以修改配置文件，提取不同路径的log"
        fi
        sed -i 's/^[ \t]*//;s/ //g;s/[ \t]*$//;s/\/$//;/^[ \t]*$/d' "${conf_file}"
        info_file="${project}_${module_name}_info_"`date +%Y%m%d%H%M%S`".txt"
        report_file="${project}_${module_name}_report_"`date +%Y%m%d%H%M%S`".txt"
        # start test
        log_folder=`pwd`"/log/${project}_"`date +%Y%m%d%H%M%S`
        #log_folder=`pwd`"/log/${project}_"`date +%H%M%S`
        mkdir -p ${log_folder}
        echo "请检查以下日志，是否复制了您需要的日志文件或日志文件夹，若没有，请将您需要复制的文件路径写入${conf_file}中。若是失败警告，则说明车机里边没有这个日志文件，请检查车机。" >> "${log_folder}/${script_log}"
        echo "==============================================================================" >> "${log_folder}/${script_log}"        
        for  file  in  `cat ${conf_file}`
        do
            [[ $file =~ ^#.* ]] && echo ${file} && continue
            to_file=${file////_}
        	# short_to_file=`echo ${to_file} | cut -d '_' -f 1,2 `
        	short_to_file=`echo ${to_file} | awk -F'_' '{print $(NF-1)"_"$NF}'`
            echo "" >> "${log_folder}/${script_log}"
            if [ `adb shell "if [ -d ${file} ]; then echo 1; fi"` ]; then
                adb -s ${device} pull "/${file}/." "${log_folder}/${short_to_file}"
                echo "【完成复制】${file} 文件夹到 ${log_folder}/${short_to_file}" | tee -a "${log_folder}/${script_log}"
                echo "车机:/${file}/.中有如下文件" >> "${log_folder}/${script_log}"
                adb -s ${device} shell "find /${file}/. -type f " >> "${log_folder}/${script_log}"
            elif [ `adb shell "if [ -f ${file} ]; then echo 1; fi"` ]; then
                adb -s ${device} pull "/${file}" "${log_folder}/${short_to_file}"
                echo "【完成复制】${file} 文件到 ${short_to_file}" | tee -a "${log_folder}/${script_log}"
            else
                echo "【失败警告】${file} 车机中无该文件或文件夹,请使用adb shell ls ${file}确认" | tee -a "${log_folder}/${script_log}"
            fi
        done
        adb -s ${device} shell logcat -S -v threadtime -d > "${log_folder}/logcat-S-v_threadtime-d.log"
        adb -s ${device} shell logcat -v threadtime -d > "${log_folder}/logcat-v_threadtime-d.log"
    done
}

# log             获取系统log
do_rmlog(){
    module_name="remove_log"
    def_conf="
    /data/logger/*                                                                   \n
    /data/tombstones/*                                                               \n
    /data/system/dropbox/*                                                           \n
    /sdcard/tencent/autowechat/*                                                     \n
    /sdcard/tencent/MicroMsg/*                                                       \n
    /sdcard/tencent/wecarbase/log/*                                                  \n
    /data/vendor/hardware/audio_d/*                                                  \n
    /data/vendor/kmsgd/*                                                             \n
    /sdcard/WTLog/*                                                                  \n
    /oem/WTLog/*                                                                     \n
    /oem/amapauto9/Log/*                                                             \n
    /oem/amapauto9/data/navi/compile_v2/chn/*                                        \n
    /sdcard/tencent/wecarnavi/log/*.xlog                                             \n
    /sdcard/tencent/wecarnavi/log/*.log                                              \n
    /sdcard/tencent/wecarnavi/log/*.txt                                              \n
    /sdcard/tencent/wecarnavi/log/wutong/*.xlog                                      \n
    /sdcard/tencent/wecarnavi/data/v3/cache/*                                        \n
    /user_data/incall_log/*                                                          \n
    /sdcard/RouteGuidance                                                            \n
    /user_data/tencent/wecarnavi/reflux/*                                            \n
    /sdcard/tencent/wecarspeech/log/*                                                \n
    /sdcard/tencent/autowechat/log/*                                                 \n
    /sdcard/tencent/MicroMsg/xlog/*                                                  \n
    /sdcard/btsnoop_hci.log                                                          \n
    /data/misc/bluetooth/logs/btsnoop_hci.log                                        \n
    /data/media/btsnoop.log                                                          \n
    /data/brlink/btsnoop.log                                                         \n
    /data/anr/*                                                                      \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/*.log                         \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/location/txwatchdog*          \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/location/sensor_vdr/*         \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/location_log/*                \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/map/*.log                     \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/map/savedData/*               \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/mapbiz/*                      \n
    /user_data/tencent/com.tencent.totem.app/pangu/log/logcat/*                      \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/*.log                 \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/location/txwatchdog*  \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/location/sensor_vdr/* \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/location_log/*        \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/map/*.log             \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/map/savedData/*       \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/mapbiz/*              \n
    /sdcard/Android/data/com.tencent.totem.app/files/pangu/log/logcat/*              \n
    /sdcard/tencent/wecarnavi/log/pangu/log/*                                        \n
    /sdcard/tencent/wecarnavi/log/pangu/map/*                                        \n
    /sdcard/tencent/wecarnavi/log/pangu/mapbiz/*                                     \n
    /sdcard/tencent/wecarnavi/log/pangu/location/*                                   \n
    /sdcard/tencent/wecarnavi/pangu/location/hmm_model/*                             \n
    /sdcard/tencent/wecarnavi/pangu/location/loc_config/*                            \n
    /sdcard/tencent/wecarnavi/pangu/location/npd_online_data/*                       \n
    /sdcard/tencent/wecarnavi/pangu/log/location_log/*.log                           \n
    "
    # for every devices
    for device in ${devices_list}
    do
        # testing and save to info file
        # read -p "请输入设备(${device})项目名称:" project
        conf_file="${project}_${module_name}_config.txt"
        if [ ! -f "${conf_file}" ];then
            echo -e ${def_conf} > "${conf_file}"
            echo "创建${module_name}配置文件${conf_file}!您可以修改配置文件，提取不同路径的log"
        fi
        sed -i 's/^[ \t]*//;s/ //g;s/[ \t]*$//;s/\/$//;/^[ \t]*$/d' "${conf_file}"
        info_file="${project}_${module_name}_info_"`date +%Y%m%d%H%M%S`".txt"
        report_file="${project}_${module_name}_report_"`date +%Y%m%d%H%M%S`".txt"
        # start test
        for  file  in  `cat ${conf_file}`
        do
            [[ ${file} =~ ^#.* ]] && continue
            if [[ ${file} =~ .*"*".* ]]; then
                echo "删除表达式：${file}"
                adb -s ${device} shell "rm ${file}"
            elif [ `adb shell "if [ -d ${file} ]; then echo 1; fi"` ]; then
                echo "删除文件夹：${file}"
                adb -s ${device} shell "find ${file} ! -type d -delete"
                # adb -s ${device} shell "find ${file} ! -type d -exec rm {} \;"
            elif [ `adb shell "if [ -f ${file} ]; then echo 1; fi"` ]; then
                echo "删除文件：${file}"
                adb -s ${device} shell "rm ${file}"
            else
                echo "删除：${file}"
                adb -s ${device} shell "rm ${file}"
            fi
        done
    done
}
# screencap       截取屏幕
do_screencap(){
    for device in ${devices_list}
    do
        # adb  -s ${device} shell dumpsys window windows | grep -E 'mCurrentFocus|mFocusedApp'
        # adb shell dumpsys activity |grep "mFocusedActivity"
        # adb shell dumpsys window windows | grep -E "mCurrentFocus"| awk -F '[ /]+' '{print $5$6}'
        activity_name=`adb shell dumpsys window windows | grep -E "mCurrentFocus"| awk -F '[ /{}]+' '{print $5"_"$6}'`
        png_name=${activity_name}`date +%Y%m%d%H%M%S`.png
        xml_name=${activity_name}`date +%Y%m%d%H%M%S`.xml
        adb  -s ${device} shell "screencap -p ${device_save_path}${png_name}" && adb  -s ${device} pull  "${device_save_path}${png_name}" . &&  echo "保存screepcap -p ${png_name}"
        adb  -s ${device} shell "rm ${device_save_path}${png_name}"
        
        while [ ! -f "${xml_name}" ];do
            adb  -s ${device} shell "uiautomator dump ${device_save_path}${xml_name}" && adb -s ${device} pull "${device_save_path}${xml_name}" . &&  echo "保存uiautomator dump ${xml_name}"
        done
        sed -i 's/></>\n</g' ${xml_name}
    done
    return 0
}


# CPU             获取进程CPU
do_CPU(){
    module_name="CPU"
    def_conf="com.tencent.wecarnavi\n
    com.tencent.wecarnews\n
    com.tencent.wecarspeech\n
    com.autopai.tboxclient\n
    com.wt.media\n
    com.wt.music\n
    com.tencent.mm\n"
    # for every devices
    for device in ${devices_list}
    do
        # read -p "请输入设备(${device})项目名称:" project
        read -p "请输入设备(${device})测试时长(默认60s):" test_duration
        [ -z ${test_duration} ] && test_duration=60
        echo "设备(${device})测试时长:${test_duration}"

        conf_file="${project}_${module_name}_config.txt"
        if [ ! -f "${conf_file}" ];then
            echo -e ${def_conf} > "${conf_file}"
            echo "创建${module_name}配置文件!"
        fi
        sed -i 's/^[ \t]*//;s/ //g;s/[ \t]*$//;/^[ \t]*$/d' "${conf_file}"
        info_file="${project}_${module_name}_info_"`date +%Y%m%d%H%M%S`".txt"
        report_file="${project}_${module_name}_report_"`date +%Y%m%d%H%M%S`".txt"

        starttime=`date +'%Y-%m-%d %H:%M:%S'`
        start_seconds=$(date --date="$starttime" +%s);
        echo "test start at: ${starttime}" |tee ${info_file}
        endtime=`date +'%Y-%m-%d %H:%M:%S'`
        end_seconds=$(date --date="$endtime" +%s);
        while [ $((end_seconds-start_seconds)) -le $((test_duration)) ];do
            endtime=`date +'%Y-%m-%d %H:%M:%S'`
            end_seconds=$(date --date="$endtime" +%s);
            echo "time stamp:${endtime}" |tee -a ${info_file}
            adb -s ${device} shell " COLUMNS=201 top -n 1 -m 70 " |tee -a ${info_file} 
        done
        echo -e "test name:${test_lable}\nstart at: ${starttime}\nend at: ${endtime}\nduration(s):${test_duration}\nreport:${report_file}" |tee -a ${info_file}

        # testing and save to info file
        # read -p "请输入设备(${device})项目名称:" project
        # conf_file="${project}_${module_name}_config.txt"
        # if [ ! -f "${conf_file}" ];then
        #     echo -e ${def_conf} > "${conf_file}"
        #     echo "创建${module_name}配置文件!"
        # fi
        # sed -i 's/^[ \t]*//;s/ //g;s/[ \t]*$//;/^[ \t]*$/d' "${conf_file}"
        # read -p "请输入设备(${device})测试时长(默认60s):" test_duration
        # [ -z ${test_duration} ] && test_duration=60
        # echo -e "test name:${test_lable}\nstart at: ${starttime}\nend at: ${endtime}\nduration(s):${test_duration}\nreport:${report_file}" > ${report_file}
        # awk -f ${base_path}/awk/dumpsys2fps.awk ${info_file} >> ${report_file}
        # grep  "idle" ${info_file}| awk -f ${base_path}/awk/top2cpu.awk >> ${report_file}
        grep  "idle" ${info_file}| awk '
        BEGIN{
            # Tasks: 264 total,   1 running, 263 sleeping,   0 stopped,   0 zombie
            # Mem:   3086480k total,  2754256k used,   332224k free,   136564k buffers
            # Swap:   925940k total,    12956k used,   912984k free,  1169480k cached
            # 600%cpu 116%user   0%nice 114%sys 370%idle   0%iow   0%irq   0%sirq   0%host
            FS = "[ %]+"
            n=0;
        }
        {   
            if($2=="cpu"){
                Fre+=1;
                if(Fre<=1){
                    CPU_u_min=$3
                    CPU_u_max=$3
                    CPU_s_min=$7
                    CPU_s_max=$7
                    CPU_i_min=$9
                    CPU_i_max=$9
                }
                CPU_t_sum+=$1;
                CPU_u_sum+=$3
                CPU_u_min=(CPU_u_min<$3 ? CPU_u_min:$3)
                CPU_u_max=(CPU_u_max>$3 ? CPU_u_max:$3)
                CPU_s_sum+=$7                         
                CPU_s_min=(CPU_s_min<$7 ? CPU_s_min:$7)
                CPU_s_max=(CPU_s_max>$7 ? CPU_s_max:$7)
                CPU_i_sum+=$9                         
                CPU_i_min=(CPU_i_min<$9 ? CPU_i_min:$9)
                CPU_i_max=(CPU_i_max>$9 ? CPU_i_max:$9)
            }
        }
        END{
            CPU_t_avg = (CPU_t_sum/Fre)
            CPU_u_avg = (CPU_u_sum/Fre)
            CPU_s_avg = (CPU_s_sum/Fre)
            CPU_i_avg = (CPU_i_sum/Fre)
            CPU_a_avg = CPU_t_avg-CPU_i_avg
            CPU_a_min = CPU_t_avg-CPU_i_max
            CPU_a_max = CPU_t_avg-CPU_i_min
            printf("数据次数:%d 系统CPU总共:%d%% 系统CPU平均使用:%d%% 系统CPU最小使用:%d%% 系统CPU最大使用:%d%%\n", Fre,CPU_t_avg,CPU_a_avg,CPU_a_min,CPU_a_max)
        }' >> ${report_file}
        # grep -f ${conf_file} ${info_file} |awk -f ${base_path}/awk/top2pcpu.awk >> ${report_file}
        grep -f ${conf_file} ${info_file} |awk '
        BEGIN{
            # PID USER         PR  NI VIRT  RES  SHR S[%CPU] %MEM     TIME+ ARGS
            # 9533 u0_a0        10 -10 1.6G 213M 143M S 10.8   7.0 183:04.19 com.tencent.wecarnavi
            print "数据次数 PID 进程平均CPU(%) 进程最小CPU(%)  进程最大CPU(%) 进程平均MEM(%) 进程最小MEM(%) 进程最大MEM(%) 进程平均常驻内存(M) 进程最小常驻内存(M) 进程最大常驻内存(M) 进程名称"
        }
        {
            # $12 is process
            if($12 !~/^\s*$/){
                Fre[$12]+=1
                PID_sum[$12]+=$1
                $6=unit_exchange_M($6)
                if(Fre[$12]<=1) {
                    RES_min[$12]=$6
                    RES_max[$12]=$6
                    CPU_min[$12]=$9
                    CPU_max[$12]=$9
                    MEM_min[$12]=$10
                    MEM_max[$12]=$10
                }
                RES_sum[$12]+=$6
                RES_min[$12]=(RES_min[$12]<$6  ? RES_min[$12]:$6 )
                RES_max[$12]=(RES_max[$12]>$6  ? RES_max[$12]:$6 )
                CPU_sum[$12]+=$9
                CPU_min[$12]=(CPU_min[$12]<$9  ? CPU_min[$12]:$9 )
                CPU_max[$12]=(CPU_max[$12]>$9  ? CPU_max[$12]:$9 )
                MEM_sum[$12]+=$10
                MEM_min[$12]=(MEM_min[$12]<$10 ? MEM_min[$12]:$10)
                MEM_max[$12]=(MEM_max[$12]>$10 ? MEM_max[$12]:$10)
            }
        }
        function unit_exchange_M(tmp)
        {
            sub(",","",tmp)
            if(tmp ~ /K/){
                    sub("K","",tmp)
                    tmp=tmp/1024 }
            else if(tmp ~ /M/){
                    sub("M","",tmp)
                    tmp=tmp}
            else if(tmp ~ /G/){
                    sub("G","",tmp)
                    tmp=tmp*1024}
            else{
                    sub("B","",tmp)
                    tmp=tmp/1024/1024}
            return tmp
        } 
        END{
            for(id in Fre){
                PID_avg[id] = (PID_sum[id] / Fre[id])
                CPU_avg[id] = (CPU_sum[id] / Fre[id])
                MEM_avg[id] = (MEM_sum[id] / Fre[id])
                RES_avg[id] = (RES_sum[id] / Fre[id])
                print Fre[id] "\t" PID_avg[id] "\t" CPU_avg[id] "\t" CPU_min[id] "\t" CPU_max[id] "\t" MEM_avg[id] "\t" MEM_min[id] "\t" MEM_max[id] "\t" RES_avg[id] "\t" RES_min[id] "\t" RES_max[id] "\t" id
            }
        }' >> ${report_file}
        # awk -f ${base_path}/awk/${test_data_process} ${info_file} >> ${report_file}
        cat ${report_file}
        echo -e "\n\n\n==============================================" >> ${report_file}
        cat ${info_file} >> ${report_file}
        rm ${info_file}
    done
    return 0
}
# GPU             获取系统GPU
do_GPU(){
    module_name="GPU"
    test_tool="cat"
    test_para="//sys/kernel/debug/mali/utilization_gp_pp"
    # init test
    # for every devices
    for device in ${devices_list}
    do
        # testing and save to info file
        # read -p "请输入设备(${device})项目名称:" project
        read -p "请输入设备(${device})测试时长(默认60s):" test_duration
        [ -z ${test_duration} ] && test_duration=60
        echo "设备(${device})测试时长:${test_duration}"
        starttime=`date +'%Y-%m-%d %H:%M:%S'`
        start_seconds=$(date --date="$starttime" +%s);
        endtime=`date +'%Y-%m-%d %H:%M:%S'`
        end_seconds=$(date --date="$endtime" +%s);
        info_file="${project}_${module_name}_info_"`date +%Y%m%d%H%M%S`".txt"
        report_file="${project}_${module_name}_report_"`date +%Y%m%d%H%M%S`".txt"
        # start test
        echo "test start at: ${starttime}" > ${info_file}
        while [ $((end_seconds-start_seconds)) -le $((test_duration)) ];do
            data=`adb -s ${device} shell "cat //sys/kernel/debug/mali/utilization_gp_pp"`
            echo `date "+%Y-%m-%d %H:%M:%S"`" cat //sys/kernel/debug/mali/utilization_gp_pp ${data}"| tee -a ${info_file} 
            endtime=`date +'%Y-%m-%d %H:%M:%S'`
            end_seconds=$(date --date="$endtime" +%s);
        done
        echo "test end at: ${endtime}" >> ${info_file}

        # make test report
        echo -e "test name:${test_lable}\nstart at: ${starttime}\nend at: ${endtime}\nduration(s):${test_duration}\nreport:${report_file}" > ${report_file}
        # awk -f ${base_path}/awk/cat2gpu.awk ${info_file} >> ${report_file}
        awk '
        BEGIN{
            n=0;
        }
        {   
            if($3 ~/utilization_gp_pp/){
                Fre+=1;
                if(Fre<=1){
                    GPU_min=$4
                    GPU_max=$4
                }
                GPU_sum+=$4
                GPU_min=(GPU_min<$9 ? GPU_min:$9)
                GPU_max=(GPU_max>$9 ? GPU_max:$9)
            }
        }
        END{
                GPU_avg = (GPU_sum/Fre)
                printf("Fre:%d GPU_avg:%d GPU_min:%d  GPU_max:%d" ,Fre ,  GPU_avg  , GPU_min  ,  GPU_max)
        }' ${info_file} >> ${report_file}
        cat ${report_file}
        echo -e "\n\n\n==================================================" >> ${report_file}
        cat ${info_file} >> ${report_file}
        rm ${info_file}
    done
}

# memory          获取进程memory
do_memory(){
    module_name="memory"
    def_conf="com.tencent.wecarnavi\n
    com.tencent.wecarnews\n
    com.tencent.wecarspeech\n
    com.autopai.tboxclient\n
    com.wt.media\n
    com.wt.music\n
    com.tencent.mm\n"
    for device in ${devices_list}
    do
        # read -p "请输入设备(${device})项目名称:" project
        read -p "请输入设备(${device})测试时长(默认60s):" test_duration
        [ -z ${test_duration} ] && test_duration=60
        echo "设备(${device})测试时长:${test_duration}"

        conf_file="${project}_${module_name}_config.txt"
        if [ ! -f "${conf_file}" ];then
            echo -e ${def_conf} > "${conf_file}"
            echo "创建${module_name}配置文件!"
        fi
        sed -i 's/^[ \t]*//;s/ //g;s/[ \t]*$//;/^[ \t]*$/d' "${conf_file}"
        info_file="${project}_${module_name}_info_"`date +%Y%m%d%H%M%S`".txt"
        report_file="${project}_${module_name}_report_"`date +%Y%m%d%H%M%S`".txt"

        starttime=`date +'%Y-%m-%d %H:%M:%S'`
        start_seconds=$(date --date="$starttime" +%s);
        echo "test start at: ${starttime}" |tee ${info_file}
        endtime=`date +'%Y-%m-%d %H:%M:%S'`
        end_seconds=$(date --date="$endtime" +%s);
        while [ $((end_seconds-start_seconds)) -le $((test_duration)) ];do
            endtime=`date +'%Y-%m-%d %H:%M:%S'`
            end_seconds=$(date --date="$endtime" +%s);
            echo "time stamp:${endtime}" |tee -a ${info_file}
            adb -s ${device} shell "dumpsys -t 60 meminfo" |tee -a ${info_file} 
        done
        echo -e "test name:${test_lable}\nstart at: ${starttime}\nend at: ${endtime}\nduration(s):${test_duration}\nreport:${report_file}" |tee -a ${info_file}
        grep  "Total RAM:\|Used RAM:" ${info_file} | awk '
        BEGIN{
            # Total RAM: 3,760,880K (status moderate)
            # Used RAM: 2,628,331K (1,938,183K used pss +   690,148K kernel)
            FS = "[:()]+"
        }
        {   
            $2=unit_exchange_M($2)
            if($1 ~ /Total RAM/){
                Fre_t+=1;
                RAM_t_sum+=$2
            }
            if($1 ~ /Used RAM/){
                Fre_u+=1;
                if(Fre_u<=1){
                    RAM_u_min=$2
                    RAM_u_max=$2
                }
                RAM_u_sum+=$2;
                RAM_u_min=(RAM_u_min<$2 ? RAM_u_min:$2)
                RAM_u_max=(RAM_u_max>$2 ? RAM_u_max:$2)
            }
        }
        function unit_exchange_M(tmp)
        {
            gsub(",","",tmp)
            gsub(" ","",tmp)
            if(tmp ~ /K/){
                sub("K","",tmp)
                tmp=tmp/1024 }
            else if(tmp ~ /M/){
                sub("M","",tmp)
                tmp=tmp}
            else if(tmp ~ /G/){
                sub("G","",tmp)
                tmp=tmp*1024}
            else{
                sub("B","",tmp)
                tmp=tmp/1024/1024}
            return tmp
        } 
        END{
                RAM_t_avg = (RAM_t_sum/Fre_t)
                RAM_u_avg = (RAM_u_sum/Fre_u)
                printf("次数:%d 系统总共RAM(M):%d 系统平均使用RAM(M):%d 系统最小使用RAM(M):%d 系统最大使用RAM(M):%d \n",Fre_t,RAM_t_avg, RAM_u_avg,RAM_u_min,RAM_u_max)
        }' >> ${report_file}
        # grep -f ${conf_file} ${info_file} |awk -f ${base_path}/awk/procrank2pmemory.awk >> ${report_file}
        sed -n '/Total PSS by process/,/^\s*$/p' ${info_file} > temp.txt
        grep -f ${conf_file} temp.txt |awk '
        BEGIN{
            # 135,557K: com.tencent.wecarnavi (pid 7688 / activities)
            #  89,373K: system (pid 2037)
            FS = "[K][:][ ]"
            print "数据次数 进程平均内存(M) 进程最大内存(M)  进程最小内存(M) 进程名称"
        }
        {
            # $2 is process
            if($2 !~/^\s*$/){ # escape blank line
                Fre[$2]+=1;
                $1=unit_exchange_M($1)
                if(Fre[$2]<=1) {
                    RAM_min[$2]=$1
                    RAM_max[$2]=$1
                }
                RAM_sum[$2]+=$1
                RAM_min[$2]=(RAM_min[$2]<$1 ? RAM_min[$2]:$1)
                RAM_max[$2]=(RAM_max[$2]>$1 ? RAM_max[$2]:$1)
            }
        }
        function unit_exchange_M(tmp)
        {
            gsub(",","",tmp)
            gsub(" ","",tmp)
            if(tmp ~ /K/){
                    sub("K","",tmp)
                    tmp=tmp/1024 }
            else if(tmp ~ /M/){
                    sub("M","",tmp)
                    tmp=tmp}
            else if(tmp ~ /G/){
                    sub("G","",tmp)
                    tmp=tmp*1024}
            else if(tmp ~ /G/){
                    sub("B","",tmp)
                    tmp=tmp/1024/1024}
            else{
                    sub("k","",tmp)
                    tmp=tmp/1024}
            return tmp
        } 
        END{
            for(id in Fre){
                RAM_avg[id] = (RAM_sum[id] / Fre[id])
                print Fre[id] "\t" RAM_avg[id]  "\t" RAM_min[id] "\t" RAM_max[id] "\t" id
            }
        }' >> ${report_file}
        cat ${report_file}
        echo -e "\n\n\n==============================================" >> ${report_file}
        cat ${info_file} >> ${report_file}
        rm ${info_file}
    done
    return 0
}
# fps             获取屏幕刷新帧数
do_FPS(){
    module_name="FPS"
    for device in ${devices_list}
    do
        # testing and save to info file
        # read -p "请输入设备(${device})项目名称:" project
        activity_name=`adb shell dumpsys window windows | grep -E "mCurrentFocus"| awk -F '[ /{}]+' '{print $5"/"$6}'`
        echo "当前UI界面:$activity_name"
        read -p "请输入设备(${device})测试时长(默认10s):" test_duration
        [ -z ${test_duration} ] && test_duration=10
        echo "设备(${device})测试时长:${test_duration}"
        adb -s ${device} shell dumpsys SurfaceFlinger --latency-clear
        starttime=`date +'%Y-%m-%d %H:%M:%S'`
        start_seconds=$(date --date="$starttime" +%s);
        endtime=`date +'%Y-%m-%d %H:%M:%S'`
        end_seconds=$(date --date="$endtime" +%s);
        info_file="${project}_${module_name}_info_"`date +%Y%m%d%H%M%S`".txt"
        report_file="${project}_${module_name}_report_"`date +%Y%m%d%H%M%S`".txt"
        # start test
        echo "test start at: ${starttime}" > ${info_file}
        while [ $((end_seconds-start_seconds)) -le $((test_duration)) ];do
            data=`adb -s ${device} shell "service call SurfaceFlinger 1013"`
            echo `date +%s%N`" ${data}"| tee -a ${info_file} 
            endtime=`date +'%Y-%m-%d %H:%M:%S'`
            end_seconds=$(date --date="$endtime" +%s);
        done
        echo "test end at: ${endtime}" >> ${info_file}
        # make test report
        echo -e "test name:${module_name}\nstart at: ${starttime}\nend at: ${endtime}\nduration(s):${test_duration}\nreport:${report_file}" > ${report_file}
        # awk -f ${base_path}/awk/dumpsys2fps.awk ${info_file} >> ${report_file}
        awk 'BEGIN{
                # Result: Parcel(00076a31 '1j..') 1598382773499983243
                FS = "[ (]+"
                fps_min=60;fps_max=0;fps_avg=0;
            }
            {   
                if($2=="Result:"){
                    Fre+=1
                    if(Fre==1){
                        page_flip_count_init=strtonum("0x"$4)
                        timestamp_init=$1
                        page_flip_count_begin=strtonum("0x"$4)
                        timestamp_begin=$1
                        }
                    if(Fre>=2){
                        legacy_pages_sum=(strtonum("0x"$4)-page_flip_count_init)
                        duration_sum=($1-timestamp_init)/1000000
                        fps_avg=1000*legacy_pages_sum/duration_sum
                        legacy_pages=(strtonum("0x"$4)-page_flip_count_begin)
                        duration=($1-timestamp_begin)/1000000
                        fps_cur=1000*legacy_pages/duration
                        fps_min=(fps_min<fps_cur ? fps_min:fps_cur)
                        fps_max=(fps_max>fps_cur ? fps_max:fps_cur)
                        }
                }
            }
            END{
                print "平均FPS:",fps_avg, "最小FPS:" fps_min,"最大FPS:",fps_max,"历时(ms):",duration_sum 
            }' ${info_file} >> ${report_file}
        cat ${report_file}
        echo "\n\n\n=======================================" >> ${report_file}
        cat ${info_file} >> ${report_file}
        rm ${info_file}
    done
}

# native          进入原生界面
do_activity(){
    for device in ${devices_list}
    do
        read -p "请输入(${device})包名/活动名(默认当前桌面进程):" activity_name
        [ -z ${activity_name} ] && activity_name='com.android.settings/com.android.settings.Settings'
        echo "启动活动名：${activity_name}"
        adb -s ${device} shell "am start ${activity_name}"
        echo "进入原生界面!"
    done
}

# kill            杀死当前界面
do_kill(){
    for device in ${devices_list}
    do
        read -p "请输入(${device})进程名字(默认当前桌面进程):" process_name
        package_name=`adb shell dumpsys window windows | grep -E "mCurrentFocus"| awk -F '[ /{}]+' '{print $5}'`
        [ -z ${process_name} ] && process_name=${package_name}
        adb -s $device shell ps -ef |grep ${process_name} |awk '{print $2}'|xargs adb -s $device shell  kill -9
        echo "杀进程${process_name}成功!"
    done
}

# device_save_path="//mnt/sdcard/"
device_save_path="/data/local/tmp/"
echo "请将脚本放到D盘/E盘非空格英文目录下运行。目录路径尽量短。以防止log路径过长抓不全。"
read -p "请输入设备${device}项目名称:" project
while true
do
    if [ $# != 1 ] ; then
        cat >&1 <<-'EOF'
请选择你希望的操作:
(1 ) 获取root，remount，等相关权限
(2 ) 安装应用APK,库文件.so到系统目录(还未完成)
(3 ) 获取APK版本号，系统属性(运行后自动产生默认包名配置文件，可修改配置文件)
(4 ) 获取系统log(运行后自动产生默认log路径配置文件，可修改配置文件后在运行)
(5 ) 清除系统log
(6 ) 截取屏幕,获取屏幕当前活动布局(以当前应用程序包名和活动名命名的截屏,获取屏幕获取当前活动的布局和视图.xml)           
(7 ) 获取进程CPU(运行后自动产生默认进程名配置文件，可修改配置文件后在运行)           
(8 ) 获取系统GPU            
(9 ) 获取进程memory(运行后自动产生默认进程名配置文件，可修改配置文件后在运行)                    
(10) 获取屏幕刷新帧数FPS
(11) 启动应用程序（默认启动原生界面)           
(12) 杀死应用程序（默认当前界面程序）
(13) 查看脚本使用说明       
EOF
        read -p "(默认: 1) 请选择 [1~13]: " sel
        [ -z "$sel" ] && sel=1
        do_get_devices
        case $sel in
            1)
                do_root
                ;;
            2)
                do_root
                do_install
                ;;
            3)
                do_root
                do_version
                ;;
            4)
                do_root
                do_log
                ;;
            5)
                do_root
                do_rmlog
                ;;
            6)
                do_root
                do_screencap
                ;;
            7)
                do_root
                do_CPU
                ;;
            8)
                do_root
                do_GPU
                ;;
            9)
                do_root
                do_memory
                ;;
            10)
                do_root
                do_FPS
                ;;
            11)
                do_root
                do_activity
                ;;
            12)
                do_root
                do_kill
                ;;
            13)
                do_root
                usage
                ;;
            *)
                echo "输入有误, 请输入有效数字 1~13!"
                continue
                ;;
        esac
    else
        action=${1:-"help"}
        do_get_devices
        case "$action" in
            root|r|-r)
                do_root
                ;;
            install|i|-i)
                do_root
                do_version
                ;;
            version|v|-v)
                do_root
                do_install
                ;;
            log|l|-l)
                do_root
                do_log
                ;;
            screencap|s|-s)
                do_root
                do_screencap
                ;;
            CPU|cpu|c|-c)
                do_root
                do_CPU
                ;;
            GPU|gpu|g|-g)
                do_root
                do_GPU
                ;;
            memory|m|-m)
                do_root
                do_memory
                ;;
            FPS|fps|f|-f)
                do_root
                do_FPS
                ;;
            activity|a|-a)
                do_root
                do_activity
                ;;
            kill|k|-k)
                do_root
                do_kill
                ;;
            help|h|-h)
                do_root
                usage 0
                ;;
            *)
                do_root
                usage 1
                ;;
        esac
    fi
    read -p "是否进行其他测试[Y/n]:(默认:y): " conti
    case $conti in
        [yY][eE][sS]|[yY])
        echo " "
        ;;
        [nN][oO]|[nN])
        echo "结束测试！"
        exit 0
        ;;
        *)
        echo " "
        ;;
    esac    

done


