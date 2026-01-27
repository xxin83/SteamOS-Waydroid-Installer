#!/bin/bash

SCRIPT_VERSION_SHA="爱折腾的老家伙汉化修改"

PASSWORD=$(zenity --password --title "sudo 密码认证")
echo -e "$PASSWORD\n" | sudo -S ls &> /dev/null
if [ $? -ne 0 ]
then
	echo "sudo 密码错误！" | \
		zenity --text-info --title "Waydroid 工具箱" --width 400 --height 200
	exit
fi

cleanup_var_space() {
    echo -e "$PASSWORD\n" | sudo -S pacman -Scc --noconfirm &> /dev/null
    echo -e "$PASSWORD\n" | sudo -S journalctl --vacuum-time=1s &> /dev/null
}

while true
do
Choice=$(zenity --width 850 --height 450 --list --radiolist --multiple --title "Waydroid 工具箱 - $SCRIPT_VERSION_SHA"\
	--column "选择" \
	--column "选项" \
	--column="描述"\
	FALSE TRANSLATION "安装/切换转译层 (支持 Houdini 空间优化)"\
	FALSE ADBLOCK "禁用或更新广告屏蔽 hosts 文件"\
	FALSE AUDIO "启用或禁用自定义音频修复"\
	FALSE SERVICE "启动或停止 Waydroid 容器服务"\
	FALSE GPU "更改 GPU 配置 - GBM 或 MINIGBM"\
	FALSE LAUNCHER "添加 Waydroid 启动器到游戏模式"\
	FALSE NETWORK "重新初始化网络配置 (修复 WIFI 不可用)"\
	FALSE UNINSTALL "卸载 Waydroid 并还原更改"\
	TRUE EXIT "***** 退出 Waydroid 工具箱 *****")

if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
then
	exit

elif [ "$Choice" == "TRANSLATION" ]
then
	TRANS_CHOICE=$(zenity --width 600 --height 300 --list --radiolist --title "转译层管理" \
		--column "选择" --column "模式" --column "描述" \
		FALSE HOUDINI "安装 libhoudini (自动重定向至 /home 防止空间不足)" \
		FALSE NDK "安装 libndk (轻量级，常规安装)" \
		FALSE REMOVE "卸载所有转译层并还原路径" \
		TRUE MENU "***** 返回主菜单 *****")

	if [ "$TRANS_CHOICE" == "HOUDINI" ] || [ "$TRANS_CHOICE" == "NDK" ]; then
		(
		echo "10" ; echo "# 正在初始化环境..."
		cleanup_var_space
		echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable &> /dev/null

		if [ "$TRANS_CHOICE" == "HOUDINI" ]; then
			echo "20" ; echo "# 正在为 Houdini 优化空间布局..."
			mkdir -p ~/waydroid/var_lib_overlay
			echo -e "$PASSWORD\n" | sudo -S systemctl stop waydroid-container &> /dev/null
			if [ ! -L /var/lib/waydroid/overlay ]; then
				echo -e "$PASSWORD\n" | sudo -S cp -a /var/lib/waydroid/overlay/. ~/waydroid/var_lib_overlay/ &> /dev/null
				echo -e "$PASSWORD\n" | sudo -S rm -rf /var/lib/waydroid/overlay
				echo -e "$PASSWORD\n" | sudo -S ln -s /home/deck/waydroid/var_lib_overlay /var/lib/waydroid/overlay
			fi
		fi

		echo "40" ; echo "# 正在下载转译层工具..."
		WS_TMP=$(mktemp -d)/waydroid_script
		git clone --depth=1 https://github.com/casualsnek/waydroid_script.git $WS_TMP &> /dev/null
		python3 -m venv $WS_TMP/venv &> /dev/null
		$WS_TMP/venv/bin/pip install -r $WS_TMP/requirements.txt &> /dev/null

		echo "60" ; echo "# 正在清理旧转译层..."
		echo -e "$PASSWORD\n" | sudo -S $WS_TMP/venv/bin/python3 $WS_TMP/main.py uninstall libhoudini &> /dev/null
		echo -e "$PASSWORD\n" | sudo -S $WS_TMP/venv/bin/python3 $WS_TMP/main.py uninstall libndk &> /dev/null

		LAYER_CMD="libndk"
		[ "$TRANS_CHOICE" == "HOUDINI" ] && LAYER_CMD="libhoudini"
		echo "80" ; echo "# 正在下载并安装 $LAYER_CMD (请保持网络畅通)..."
		echo -e "$PASSWORD\n" | sudo -S $WS_TMP/venv/bin/python3 $WS_TMP/main.py install $LAYER_CMD

		echo "100" ; echo "# 安装完成！"
		rm -rf $WS_TMP
		) | zenity --progress --title "正在处理转译层" --text "准备开始..." --percentage=0 --auto-close --width=400

		zenity --info --text "转译层 $TRANS_CHOICE 处理完成！\n请重启 Waydroid。" --width 350

	elif [ "$TRANS_CHOICE" == "REMOVE" ]; then
		(
		echo "50" ; echo "# 正在卸载转译层..."
		WS_TMP=$(mktemp -d)/waydroid_script
		git clone --depth=1 https://github.com/casualsnek/waydroid_script.git $WS_TMP &> /dev/null
		echo -e "$PASSWORD\n" | sudo -S python3 $WS_TMP/main.py uninstall libhoudini &> /dev/null
		echo -e "$PASSWORD\n" | sudo -S python3 $WS_TMP/main.py uninstall libndk &> /dev/null
		rm -rf $WS_TMP
		echo "100" ; echo "# 卸载完成。"
		) | zenity --progress --title "清理中" --text "正在操作..." --percentage=0 --auto-close --width=400
		zenity --info --text "转译层已成功卸载。" --width 300
	fi

elif [ "$Choice" == "NETWORK" ]
then
	echo -e "$PASSWORD\n" | sudo -S systemctl start firewalld
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --remove-interface=waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --remove-port=53/udp &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --remove-port=67/udp &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --remove-forward &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --runtime-to-permanent &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --add-interface=waydroid0 &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --add-port=53/udp &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --add-port=67/udp &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --zone=trusted --add-forward &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S firewall-cmd --runtime-to-permanent &> /dev/null
	echo -e "$PASSWORD\n" | sudo -S systemctl stop firewalld
  	zenity --warning --title "Waydroid 工具箱" --text "网络配置已重置！" --width 350

elif [ "$Choice" == "ADBLOCK" ]
then
ADBLOCK_Choice=$(zenity --width 600 --height 250 --list --radiolist --multiple --title "广告屏蔽管理" --column "选择" \
	--column "选项" --column="描述"\
	FALSE DISABLE "禁用自定义广告屏蔽"\
	FALSE ENABLE "启用自定义广告屏蔽"\
	FALSE UPDATE "更新并启用广告屏蔽"\
	TRUE MENU "***** 返回主菜单 *****")
	if [ "$ADBLOCK_Choice" == "DISABLE" ]; then
		echo -e "$PASSWORD\n" | sudo -S mv /var/lib/waydroid/overlay/system/etc/hosts /var/lib/waydroid/overlay/system/etc/hosts.disable &> /dev/null
		zenity --info --text "广告屏蔽已禁用。" --width 300
	elif [ "$ADBLOCK_Choice" == "ENABLE" ]; then
		echo -e "$PASSWORD\n" | sudo -S mv /var/lib/waydroid/overlay/system/etc/hosts.disable /var/lib/waydroid/overlay/system/etc/hosts &> /dev/null
		zenity --info --text "广告屏蔽已启用。" --width 300
	elif [ "$ADBLOCK_Choice" == "UPDATE" ]; then
		echo -e "$PASSWORD\n" | sudo -S rm /var/lib/waydroid/overlay/system/etc/hosts.disable &> /dev/null
		echo -e "$PASSWORD\n" | sudo -S wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts -O /var/lib/waydroid/overlay/system/etc/hosts
		zenity --info --text "广告屏蔽已更新。" --width 300
	fi

elif [ "$Choice" == "GPU" ]
then
GPU_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple --title "GPU 配置" --column "选择" --column "选项" --column="描述"\
	FALSE GBM "使用 GBM 配置"\
	FALSE MINIGBM "使用 MINIGBM 配置 (默认)"\
	TRUE MENU "***** 返回主菜单 *****")
	if [ "$GPU_Choice" == "GBM" ]; then
		echo -e "$PASSWORD\n" | sudo -S sed -i "s/ro.hardware.gralloc=.*/ro.hardware.gralloc=gbm/g" /var/lib/waydroid/waydroid_base.prop
		zenity --info --text "已切换至 GBM。" --width 300
	elif [ "$GPU_Choice" == "MINIGBM" ]; then
		echo -e "$PASSWORD\n" | sudo -S sed -i "s/ro.hardware.gralloc=.*/ro.hardware.gralloc=minigbm_gbm_mesa/g" /var/lib/waydroid/waydroid_base.prop
		zenity --info --text "已切换至 MINIGBM。" --width 300
	fi

elif [ "$Choice" == "AUDIO" ]
then
AUDIO_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple --title "音频配置" --column "选择" --column "选项" --column="描述"\
	FALSE DISABLE "禁用音频优化"\
	FALSE ENABLE "启用音频优化 (降低延迟)"\
	TRUE MENU "***** 返回主菜单 *****")
	if [ "$AUDIO_Choice" == "DISABLE" ]; then
		echo -e "$PASSWORD\n" | sudo -S mv /var/lib/waydroid/overlay/system/etc/init/audio.rc /var/lib/waydroid/overlay/system/etc/init/audio.rc.disable &> /dev/null
		zenity --info --text "音频优化已禁用。" --width 300
	elif [ "$AUDIO_Choice" == "ENABLE" ]; then
		echo -e "$PASSWORD\n" | sudo -S mv /var/lib/waydroid/overlay/system/etc/init/audio.rc.disable /var/lib/waydroid/overlay/system/etc/init/audio.rc &> /dev/null
		zenity --info --text "音频优化已启用。" --width 300
	fi

elif [ "$Choice" == "SERVICE" ]
then
SERVICE_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple --title "服务管理" --column "选择" --column "选项" --column="描述"\
	FALSE START "启动 Waydroid 服务"\
	FALSE STOP "停止 Waydroid 服务"\
	TRUE MENU "***** 返回主菜单 *****")
	if [ "$SERVICE_Choice" == "START" ]; then
		echo -e "$PASSWORD\n" | sudo -S waydroid-container-start &> /dev/null
		waydroid session start &
		zenity --info --text "服务已启动。" --width 300
	elif [ "$SERVICE_Choice" == "STOP" ]; then
		waydroid session stop &> /dev/null
		echo -e "$PASSWORD\n" | sudo -S waydroid-container-stop &> /dev/null
		pkill kwallet
		zenity --info --text "服务已停止。" --width 300
	fi

elif [ "$Choice" == "LAUNCHER" ]
then
	steamos-add-to-steam /home/deck/Android_Waydroid/Android_Waydroid_Cage.sh
	sleep 2
	zenity --info --text "启动器已添加到 Steam。" --width 300

elif [ "$Choice" == "UNINSTALL" ]
then
UNINSTALL_Choice=$(zenity --width 600 --height 220 --list --radiolist --multiple --title "卸载选项" --column "选择" --column "选项" --column="描述"\
	FALSE WAYDROID "仅卸载 Waydroid (保留用户数据)"\
	FALSE FULL "完全卸载 (删除所有数据)"\
	TRUE MENU "***** 返回主菜单 *****")
	if [ "$UNINSTALL_Choice" == "WAYDROID" ] || [ "$UNINSTALL_Choice" == "FULL" ]; then
		echo -e "$PASSWORD\n" | sudo -S steamos-readonly disable
		echo -e "$PASSWORD\n" | sudo -S systemctl stop waydroid-container
		echo -e "$PASSWORD\n" | sudo -S pacman -R --noconfirm binder_linux-dkms fakeroot debugedit dkms plymouth libglibutil libgbinder python-gbinder waydroid wlroots cage wlr-randr
		echo -e "$PASSWORD\n" | sudo -S rm -rf ~/waydroid /var/lib/waydroid /usr/lib/waydroid /etc/waydroid-extra ~/AUR
		echo -e "$PASSWORD\n" | sudo -S rm /etc/sudoers.d/zzzzzzzz-waydroid /etc/modules-load.d/waydroid_binder.conf /etc/modprobe.d/waydroid_binder.conf /usr/bin/waydroid-startup-scripts /usr/bin/waydroid-shutdown-scripts
		rm ~/Desktop/Waydroid-Toolbox
		[ "$UNINSTALL_Choice" == "FULL" ] && rm -rf ~/.local/share/waydroid ~/.local/share/applications/waydroid* ~/Android_Waydroid/ ~/Desktop/Waydroid-Updater
		echo -e "$PASSWORD\n" | sudo -S steamos-readonly enable
		zenity --info --text "卸载完成。" --width 300
		exit
	fi
fi
done
