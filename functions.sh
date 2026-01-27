#!/bin/bash

cleanup_exit () {
	echo "出现错误！正在执行清理。请再次运行脚本以安装 Waydroid。"
	
	echo -e "$current_password\n" | sudo -S pacman -R --noconfirm libglibutil libgbinder \
		python-gbinder waydroid wlroots cage wlr-randr binder_linux-dkms fakeroot debugedit \
		dkms plymouth linux-neptune-$(uname -r | cut -d "-" -f5)-headers &> /dev/null
	
	echo -e "$current_password\n" | sudo -S rm -rf ~/waydroid /var/lib/waydroid &> /dev/null
	
	echo -e "$current_password\n" | sudo -S rm /etc/sudoers.d/zzzzzzzz-waydroid /etc/modules-load.d/waydroid.conf /usr/bin/waydroid* &> /dev/null

	rm ~/Desktop/Waydroid-Updater &> /dev/null
	rm ~/Desktop/Waydroid-Toolbox &> /dev/null

	echo -e "$current_password\n" | sudo -S rm -rf ~/Android_Waydroid &> /dev/null
	echo -e "$current_password\n" | sudo -S steamos-readonly enable &> /dev/null
	
	if [ -f $PLUGIN_LOADER ]
	then
		echo "正在重新启用 Decky Loader 插件服务。"
		echo -e "$current_password\n" | sudo -S systemctl start plugin_loader.service
	fi
	
	echo "清理完成。请在 GitHub 仓库提交 Issue 或在 YT 频道 - 10MinuteSteamDeckGamer 留言。"
	exit
}

prepare_custom_image_location () {
echo -e "$current_password\n" | sudo mkdir /etc/waydroid-extra &> /dev/null
echo -e "$current_password\n" | sudo -S ln -s ~/waydroid/custom /etc/waydroid-extra/images &> /dev/null
}

download_image () {
	local src=$1
	local src_hash=$2
	local dest=$3
	local dest_zip="$dest.zip"
	local name=$4
	local hash

	echo "正在下载 $name 镜像"
	echo -e "$current_password\n" | sudo -S curl -o $dest_zip $src -L
	hash=$(sha256sum "$dest_zip" | awk '{print $1}')
	if [[ "$hash" != "$src_hash" ]]; then
		echo "$name 镜像 sha256 校验不匹配，可能下载已损坏。这可能是由于网络错误，请重试。"
		cleanup_exit
	fi

	echo "正在解压归档"
	echo -e "$current_password\n" | sudo -S unzip -o $dest -d ~/waydroid/custom
	echo -e "$current_password\n" | sudo -S rm $dest_zip
}

install_android_extras () {
	python3 -m venv $WAYDROID_SCRIPT_DIR/venv
	$WAYDROID_SCRIPT_DIR/venv/bin/pip install -r $WAYDROID_SCRIPT_DIR/requirements.txt &> /dev/null

	if [ "$Choice" == "A13_NO_GAPPS" ] || [ "$Choice" == "A13_GAPPS" ]
	then
		echo -e "$current_password\n" | sudo -S $WAYDROID_SCRIPT_DIR/venv/bin/python3 $WAYDROID_SCRIPT_DIR/main.py -a13 install {libndk,widevine}
	fi

	echo "casualsnek / aleasto waydroid_script 执行完毕。"
	echo -e "$current_password\n" | sudo -S rm -rf $WAYDROID_SCRIPT_DIR
	
	cat extras/waydroid_base.prop | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null

	if [ "$Choice" == "A13_NO_GAPPS" ] || [ "$Choice" == "A13_GAPPS" ] 
	then
		cat extras/android_spoof.prop | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null

	elif [ "$Choice" == "TV13_GAPPS" ]
	then
		cat extras/androidtv_spoof.prop | sudo tee -a /var/lib/waydroid/waydroid_base.prop > /dev/null
	fi
}

check_waydroid_init () {
	if [ $? -eq 0 ]
	then
		echo "Waydroid 初始化完成，无错误！"

	else
		echo "Waydroid 未能正确初始化。"
		echo "可能是哈希不匹配 / 下载损坏。"
		echo "也可能是 Python 问题。提交错误报告时请附带此截图！"
		echo "whereis python 输出 - $(whereis python)"
		echo "which python 输出 - $(which python)"
		echo "python 版本输出 - $(python -V)"

		cleanup_exit
	fi
}
