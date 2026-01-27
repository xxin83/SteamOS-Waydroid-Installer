#!/bin/bash

xdpyinfo &> /dev/null
if [ $? -eq 0 ]
then
	echo "脚本正在桌面模式运行。"
else
 	echo "脚本未在桌面模式运行。"
	echo "请按照 README 的说明在桌面模式下运行脚本。再见！"
	exit
fi

if awk "BEGIN {exit ! ($STEAMOS_VERSION >= $BASE_VERSION)}"
then
	echo "检测到 SteamOS $STEAMOS_VERSION $STEAMOS_BRANCH。进入下一步。"
else
	echo "检测到 SteamOS $STEAMOS_VERSION $STEAMOS_BRANCH。这是不受支持的版本。"
	echo "请更新 SteamOS，确保其版本至少为 3.7.x。"
	exit
fi

if [ "$STEAMOS_BRANCH" == "rel" ] || [ "$STEAMOS_BRANCH" == "beta" ]
then
	echo "检测到 SteamOS $STEAMOS_BRANCH 分支。进入下一步。"
elif [ "$STEAMOS_BRANCH" == "main" ]
then
	zenity --question --title "SteamOS Waydroid 安装程序" --text \
		"警告！检测到 SteamOS $STEAMOS_BRANCH 分支。 \
		\n\n该脚本已在 SteamOS 的稳定版 (STABLE) 或测试版 (BETA) 分支上测试过。 \
		\n但脚本也可能在主开发版 (MAIN) 分支上运行。 \
		\n\n\n是否要继续安装？" --width 650 --height 75 &> /dev/null

	if [ $? -eq 1 ]
	then
		echo "用户按下否。立即退出。"
		exit
	else
		echo "用户按下是。继续运行脚本。"
		echo "已检测到 SteamOS $STEAMOS_BRANCH。"
	fi
fi

echo "正在检查 home 分区是否有足够的空闲空间"
echo "home 分区剩余 $FREE_HOME 空间。"
if [ $FREE_HOME -ge 5000000 ]
then
	echo "home 分区空间充足。"
else
	echo "home 分区空间不足！"
	echo "请确保 home 分区至少有 5GB 的空闲空间！"
	exit
fi

grep redfin /var/lib/waydroid/waydroid_base.prop &> /dev/null || grep PH7M_EU_5596 /var/lib/waydroid/waydroid_base.prop &> /dev/null
if [ $? -eq 0 ]
then
	echo "检测到重新安装。跳过 var 分区空间检测。"
else
	echo "正在检查 var 分区是否有足够的空闲空间"
	echo "var 分区剩余 $FREE_VAR 空间。"
	if [ $FREE_VAR -ge 100000 ]
	then
		echo "var 分区空间充足。"
	else
		echo "var 分区空间不足！"
		echo "请确保 var 分区至少有 100MB 的空闲空间！"
		exit
	fi
fi

if [ "$(passwd --status $(whoami) | tr -s " " | cut -d " " -f 2)" == "P" ]
then
	read -s -p "请输入当前的 sudo 密码: " current_password ; echo
	echo "正在检查 sudo 密码是否正确。"
	echo -e "$current_password\n" | sudo -S -k ls &> /dev/null

	if [ $? -eq 0 ]
	then
		echo "Sudo 密码正确！"
	else
		echo "Sudo 密码错误！请重新运行脚本并确保输入正确的 sudo 密码！"
		exit
	fi
else
	echo "Sudo 密码为空！请先设置 sudo 密码，然后重新运行脚本！"
	passwd
	exit
fi

systemctl is-active --quiet plugin_loader.service
if [ $? -eq 0 ]
then
	echo "检测到 Decky Loader！这可能会对 Waydroid 安装脚本产生影响！"
	echo "正在暂时禁用 Decky Loader 插件服务。"
	echo -e "$current_password\n" | sudo -S systemctl stop plugin_loader.service

	if [ $? -eq 0 ]
	then
		echo "Decky Loader 插件服务已成功禁用。"
		echo "待 Waydroid 安装完成后，该服务将重新启用。"
	  	echo "您也可以通过重启 Steam Deck 来重新激活 Decky Loader。"
	else
		echo "停止 Decky Loader 插件服务时出错。"
		echo "立即退出。"
		exit
	fi
fi
