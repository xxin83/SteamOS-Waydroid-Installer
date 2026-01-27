#!/bin/bash

clear

echo "ryanrudolf 开发的 SteamOS Waydroid 安装脚本"
echo "https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer"
echo "YT - 10MinuteSteamDeckGamer"
sleep 2

SCRIPT_VERSION_SHA="爱折腾的老家伙汉化修改"
STEAMOS_VERSION=$(cat /etc/os-release | grep -i version_id | cut -d "=" -f2 | cut -d "." -f1-2)
BASE_VERSION=3.7
STEAMOS_BRANCH=$(steamos-select-branch -c)
WORKING_DIR=$(pwd)
LOGFILE=$WORKING_DIR/logfile
BINDER_AUR=https://aur.archlinux.org/binder_linux-dkms.git
BINDER_GITHUB=https://github.com/archlinux/aur.git
BINDER_DIR=$(mktemp -d)/aur_binder
WAYDROID_SCRIPT=https://github.com/casualsnek/waydroid_script.git
WAYDROID_SCRIPT_DIR=$(mktemp -d)/waydroid_script
FREE_HOME=$(df /home --output=avail | tail -n1)
FREE_VAR=$(df /var --output=avail | tail -n1)

ANDROID13_TV_IMG=https://github.com/supechicken/waydroid-androidtv-build/releases/download/20250811/lineage-20.0-20250811-UNOFFICIAL-WayDroidATV_x86_64.zip
ANDROID13_TV_IMG_HASH=0c6cb5f3ccc7edab105d800363c2fe6b457f77f793f04e3fddc6175c0665a2d4

echo "脚本版本: $SCRIPT_VERSION_SHA"

source functions.sh
source sanity-checks.sh

mkdir -p ~/AUR/waydroid &> /dev/null

echo "正在克隆 casualsnek / aleasto waydroid_script 仓库和 binder 内核模块源码。"
echo "这可能需要几分钟，取决于网速。"
echo "如果进度过慢，请按 (CTL-C) 取消并重新运行脚本。"

git clone --depth=1 $WAYDROID_SCRIPT $WAYDROID_SCRIPT_DIR &> /dev/null && \
git clone $BINDER_AUR $BINDER_DIR &> /dev/null
if [[ $? -ne 0 ]]; then
	echo "AUR 仓库失败，正在切换至 GitHub 镜像。"
	git clone --branch binder_linux-dkms --single-branch $BINDER_GITHUB $BINDER_DIR &> /dev/null
fi

if [[ $? -eq 0 ]]
then
	echo "仓库克隆成功！正在进入下一步。"
else
	echo "克隆仓库出错！"
	rm -rf $WAYDROID_SCRIPT_DIR
	cleanup_exit
fi

echo "正在通过 steamos-devmode 解锁 SteamOS 并初始化密钥环。这可能需要一段时间。"
echo "*** steamos-devmode ***" &> $LOGFILE
echo -e "$current_password\n" | sudo -S steamos-devmode enable --no-prompt &>> $LOGFILE

if [ $? -eq 0 ]
then
	echo "pacman 密钥环已初始化！"
else
	echo "初始化密钥环出错！"
	cleanup_exit
fi

if awk "BEGIN {exit ! ($STEAMOS_VERSION == $BASE_VERSION)}"
then

	echo "正在安装构建 binder 模块所需的软件包。这可能需要一段时间。"
	echo "*** pacman install dependencies for binder ***" &>> $LOGFILE
	echo -e "$current_password\n" | sudo -S pacman -S --noconfirm fakeroot debugedit dkms plymouth \
	linux-neptune-$(uname -r | cut -d "-" -f5)-headers --overwrite "*" &>> $LOGFILE

	if [ $? -eq 0 ]
	then
		echo "安装 binder 构建依赖包完成，未发现错误。"
	else
		echo "安装过程中出现错误。"
		echo "执行清理，再见！"
		cleanup_exit
		exit
	fi

	echo "正在从源码编译并安装 binder 模块。这可能需要一段时间。"
	echo "*** build and install binder from source ***" &>> $LOGFILE
	cd $BINDER_DIR && makepkg -f &>> $LOGFILE && \
		echo -e "$current_password\n" | sudo -S pacman -U --noconfirm binder_linux-dkms*.zst &>> $LOGFILE && \
		echo -e "$current_password\n" | sudo -S modprobe binder_linux device=binder,hwbinder,vndbinder &>> $LOGFILE

	if [ $? -eq 0 ]	
	then
		echo "编译 binder 模块完成，无错误。Binder 模块已加载。"
	else
		echo "编译过程中出现错误。"
		echo "执行清理，再见！"
		cleanup_exit
		exit
	fi

	echo "正在安装 pacman 仓库中的其他软件包。"
	echo -e "$current_password\n" | sudo -S pacman -S --noconfirm wlroots cage wlr-randr &>> $LOGFILE

	if [ $? -eq 0 ]
	then
		echo "cage 已安装！"
	else
		echo "安装 cage 出错。请再次运行脚本。"
		cleanup_exit
	fi

	cd $WORKING_DIR
	echo -e "$current_password\n" | sudo -S cp extras/waydroid_binder.conf /etc/modules-load.d/waydroid_binder.conf
	echo -e "$current_password\n" | sudo -S cp extras/options-waydroid_binder.conf /etc/modprobe.d/waydroid_binder.conf

elif awk "BEGIN {exit ! ($STEAMOS_VERSION > $BASE_VERSION)}"
then

	echo "正在安装 pacman 仓库中的其他软件包。"
	echo -e "$current_password\n" | sudo -S pacman -S --noconfirm cage wlr-randr &>> $LOGFILE

	if [ $? -eq 0 ]
	then
		echo "cage 已安装！"
	else
		echo "安装 cage 出错。请再次运行脚本。"
		cleanup_exit
	fi
fi

echo "正在安装预编译的 Waydroid 软件包。这可能需要一段时间。"
echo "*** pacman install waydroid packages ***" &>> $LOGFILE
cd $WORKING_DIR
echo -e "$current_password\n" | sudo -S pacman -U --noconfirm waydroid/libgbinder*.zst waydroid/libglibutil*.zst \
	waydroid/python-gbinder*.zst waydroid/waydroid*.zst &>> $LOGFILE && \

if [ $? -eq 0 ]
then
	echo "Waydroid 已安装！"
	echo -e "$current_password\n" | sudo -S systemctl disable waydroid-container.service
else
	echo "安装 Waydroid 出错。请再次运行脚本。"
	cleanup_exit
fi

echo -e "$current_password\n" | sudo -S systemctl start firewalld
echo -e "$current_password\n" | sudo -S firewall-cmd --zone=trusted --add-interface=waydroid0 &> /dev/null
echo -e "$current_password\n" | sudo -S firewall-cmd --zone=trusted --add-port={53,67}/udp &> /dev/null
echo -e "$current_password\n" | sudo -S firewall-cmd --zone=trusted --add-forward &> /dev/null
echo -e "$current_password\n" | sudo -S firewall-cmd --runtime-to-permanent &> /dev/null
echo -e "$current_password\n" | sudo -S systemctl stop firewalld

mkdir ~/Android_Waydroid &> /dev/null

echo -e "$current_password\n" | sudo -S cp extras/waydroid-startup-scripts /usr/bin/waydroid-startup-scripts
echo -e "$current_password\n" | sudo -S cp extras/waydroid-shutdown-scripts /usr/bin/waydroid-shutdown-scripts
echo -e "$current_password\n" | sudo -S chmod +x /usr/bin/waydroid-startup-scripts /usr/bin/waydroid-shutdown-scripts

echo -e "$current_password\n" | sudo -S cp extras/zzzzzzzz-waydroid /etc/sudoers.d/zzzzzzzz-waydroid
echo -e "$current_password\n" | sudo -S chown root:root /etc/sudoers.d/zzzzzzzz-waydroid

cp extras/Android_Waydroid_Cage.sh extras/Waydroid-Toolbox.sh extras/Waydroid-Updater.sh ~/Android_Waydroid
chmod +x ~/Android_Waydroid/*.sh

mkdir -p ~/.local/share/kio/servicemenus
cp extras/open_as_root.desktop ~/.local/share/kio/servicemenus
chmod +x ~/.local/share/kio/servicemenus/open_as_root.desktop

ln -s ~/Android_Waydroid/Waydroid-Toolbox.sh ~/Desktop/Waydroid-Toolbox &> /dev/null
ln -s ~/Android_Waydroid/Waydroid-Updater.sh ~/Desktop/Waydroid-Updater &> /dev/null

grep redfin /var/lib/waydroid/waydroid_base.prop &> /dev/null || grep PH7M_EU_5596 /var/lib/waydroid/waydroid_base.prop &> /dev/null
if [ $? -eq 0 ]
then
	echo "检测到重新安装。确保软链接已就绪！"
	if [ ! -d /etc/waydroid-extra ]
	then
		echo -e "$current_password\n" | sudo -S mkdir /etc/waydroid-extra
		echo -e "$current_password\n" | sudo -S ln -s ~/waydroid/custom /etc/waydroid-extra/images &> /dev/null
	fi

	echo -e "$current_password\n" | sudo -S steamos-readonly enable
	echo "Waydroid 已成功安装！"
else
	echo "正在从 sourceforge 下载 Waydroid 镜像。"
	echo "这可能需要几秒钟到几分钟，具体取决于网络连接和镜像源速度。"
	echo "如果下载速度过慢，请按 (CTL-C) 取消并重新运行脚本。"

	mkdir -p ~/waydroid/{images,custom,cache_http,host-permissions,lxc,overlay,overlay_rw,rootfs}
	echo -e "$current_password\n" | sudo mkdir /var/lib/waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S ln -s ~/waydroid/images /var/lib/waydroid/images &> /dev/null
	echo -e "$current_password\n" | sudo -S ln -s ~/waydroid/cache_http /var/lib/waydroid/cache_http &> /dev/null

	echo -e "$current_password\n" | sudo -S mkdir -p /var/lib/waydroid/overlay/system/usr/keylayout
	echo -e "$current_password\n" | sudo -S cp extras/Vendor_28de_Product_11ff.kl /var/lib/waydroid/overlay/system/usr/keylayout/

	echo -e "$current_password\n" | sudo -S mkdir -p /var/lib/waydroid/overlay/system/etc/init
	echo -e "$current_password\n" | sudo -S cp extras/audio.rc /var/lib/waydroid/overlay/system/etc/init/

	echo -e "$current_password\n" | sudo -S wget https://raw.githubusercontent.com/StevenBlack/hosts/master/alternates/fakenews-gambling-porn/hosts \
		       -O /var/lib/waydroid/overlay/system/etc/hosts

	Choice=$(zenity --width 1040 --height 320 --list --radiolist --multiple \
		--title "SteamOS Waydroid 安装程序 - https://github.com/ryanrudolfoba/SteamOS-Waydroid-Installer"\
		--column "选择一项" \
		--column "选项" \
		--column="描述 - 请仔细阅读！"\
		TRUE A13_GAPPS "下载官方 Android 13 镜像（含 Google Play 商店）。"\
		FALSE A13_NO_GAPPS "下载官方 Android 13 镜像（不含 Google Play 商店）。"\
		FALSE TV13_GAPPS "下载非官方 Android 13 TV 镜像（含 Google Play 商店）- 感谢 SupeChicken666 提供镜像！" \
		FALSE EXIT "***** 退出此脚本 *****")

		if [ $? -eq 1 ] || [ "$Choice" == "EXIT" ]
		then
			echo "用户按下取消 / 退出。再见！"
			cleanup_exit

		elif [ "$Choice" == "A13_GAPPS" ]
		then
			echo "正在初始化 Waydroid。"
			echo -e "$current_password\n" | sudo -S waydroid init -s GAPPS
			check_waydroid_init

		elif [ "$Choice" == "A13_NO_GAPPS" ]
		then
			echo "正在初始化 Waydroid。"
			echo -e "$current_password\n" | sudo -S waydroid init
			check_waydroid_init

		elif [ "$Choice" == "TV13_GAPPS" ]
		then
			prepare_custom_image_location
			download_image $ANDROID13_TV_IMG $ANDROID13_TV_IMG_HASH ~/waydroid/custom/android13tv "Android 13 TV"

			echo "正在应用 Leanback 键盘修复。"
			echo -e "$current_password\n" | sudo -S cp extras/ATV-Generic.kl /var/lib/waydroid/overlay/system/usr/keylayout/Generic.kl

			echo "正在初始化 Waydroid。"
 			echo -e "$current_password\n" | sudo -S waydroid init
			check_waydroid_init
			
		fi
	
	echo "安装 libndk、widevine 和指纹伪装。"
	install_android_extras

	echo -e $PASSWORD\n | sudo -S sed -i "s/ro.hardware.gralloc=.*/ro.hardware.gralloc=minigbm_gbm_mesa/g" /var/lib/waydroid/waydroid_base.prop

	echo "正在添加快捷方式到游戏模式。请稍候..."

	logged_in_user=$(whoami)
	logged_in_home=$(eval echo "~$logged_in_user")
	launcher_script="${logged_in_home}/Android_Waydroid/Android_Waydroid_Cage.sh"
	icon_path="/usr/share/icons/hicolor/512x512/apps/waydroid.png"

	if [ -f "$launcher_script" ]; then
		chmod +x "$launcher_script"
	else
		echo "错误：未找到启动脚本 '$launcher_script'。"
	fi

	TMP_DESKTOP="/tmp/waydroid-temp.desktop"
	cat > "$TMP_DESKTOP" << EOF
[Desktop Entry]
Name=Waydroid
Exec=${launcher_script}
Path=${logged_in_home}/Android_Waydroid
Type=Application
Terminal=false
Icon=application-default-icon
EOF

	chmod +x "$TMP_DESKTOP"
	steamos-add-to-steam "$TMP_DESKTOP"
	sleep 3
	rm -f "$TMP_DESKTOP"
	echo "Waydroid 快捷方式已添加到游戏模式。"
	
	python3 extras/icon.py
	
	steamos-add-to-steam /usr/bin/steamos-nested-desktop  &> /dev/null
	sleep 3
	echo "steamos-nested-desktop 快捷方式已添加到游戏模式。"

	echo -e "$current_password\n" | sudo -S steamos-readonly enable
	echo "Waydroid 已成功安装！"
fi

if zenity --question --text="是否要返回游戏模式？"; then
	qdbus org.kde.Shutdown /Shutdown org.kde.Shutdown.logout
fi
