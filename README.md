# SteamOS Android Waydroid Installer

一套工具被打包成一个易用脚本，经过简化和测试，以配合运行在SteamOS上的Steam Deck。
汉化安装过程，使其输出更加容易理解，增加工具箱转译层切换，能够让其应对更多使用场景，毕竟不少国内应用，在精简的转译层中运行很差。
**安装方式.**

**`克隆软件仓库`** 
```
git clone --depth=1 -b main https://github.com/xxin83/steamos-waydroid-installer
```

**`进入目录赋予权限、执行该脚本`** 
```
cd steamos-waydroid-installer
chmod +x steamos-waydroid-installer.sh
chmod +x functions.sh
chmod +x sanity-checks.sh
sudo ./steamos-waydroid-installer.sh
```

**安装操作及过程与原版相同，安装默认libndk转译层，桌面提供工具箱，可在工具箱内进行转译层切换**

