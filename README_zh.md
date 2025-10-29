# IAX ![GitHub License](https://img.shields.io/github/license/fflq/iax)

**其他语言版本: [English](README.md), [中文](README_zh.md).**

IAX CSI工具支持： 
* Intel AX200/201/210/211、Intel 5300
* IEEE 802.11a/g/n/ac/ax，Non-HT/HT/VHT/HE
* STA、AP、Monitor、Injector模式
* 20/40/80/160MHz

# 安装
## 前提
1. 目前针对Intel AX网卡的CSI功能是基于Linux 5.15.x内核（API规范）。测试中使用过内核匹配的Ubuntu 20.04/22.04系统，比如22.04.5默认内核6.8就不符合。有的发行版要在``Advanced Options for Ubuntu``启动项中选择5.15.x内核。推荐使用Ubuntu 22.04.0/1.
2. 移植的Intel 5300 CSI Tool功能是基于Linux 5.15.69内核的iwldvm驱动。
3. 安装依赖过程需要确保网络连接正常。

## 安装命令
主要是依赖安装、驱动编译更新及固件更新，因此耗时较长。
```shell
$ cd iwlwifi
$ sudo ./setup.sh
```

# 使用
主要包括以下步骤：
1. 配置，配置网卡模式和CSI参数。
2. 监听CSI，获取来自驱动的CSI数据（C++/Python）。
3. 解析CSI，解析CSI头信息和矩阵数据（Matlab/Python）。

## 配置
配置主要分为两个步骤：  
1. 配置网卡STA/AP/Monitor/Injector模式，具体如STA模式下需连接AP、Monitor模式下需设置监听信道及带宽。
2. 设置CSI参数并开启CSI功能，如过滤MAC、间隔时间、注入包类型等。

### STA模式
在STA模式下，IAX与一个AP进行关联，CSI是基于下行数据包进行测量的，而不需要对AP端做任何修改，如下图所示。
CSI数据的类型取决于接收到的数据包的类型。例如，当连接到一个IEEE 802.11ac VHT 80𝑀𝐻𝑧的AP时，我们可以从数据包中获取VHT 80𝑀𝐻𝑧的CSI，而从控制包中接收到Non-HT 20𝑀𝐻𝑧的CSI数据。

<!--
![IAX STA Mode](res/iax-sta.png)
-->
<div align="center">
<img src="res/iax-sta.png" width="60%" title="IAX STA Mode"/>
</div>

如下所示，IAX将`wlp8s0`网卡连接到WiFi，并开启CSI功能。
```shell
$ cd tools
$ sudo ./connect-wifi.sh wlp8s0 wifi wifi-passwd # 或手动连接WiFi
$ sudo ./iaxcsi-activate.sh
```

### AP模式
IAX开启AP模式时，可在为关联客户端提供通信服务的同时，从上行数据包中获取CSI数据，如下图所示。
期间不需要对客户端进行任何修改，获取的CSI数据类型类似STA模式。

<div align="center">
<img src="res/iax-ap.png" width="40%" title="IAX AP Mode"/>
</div>

如下所示，IAX在`wlp8s0`网卡上建立AP热点后，开启CSI功能。
其中[create_ap](https://github.com/oblique/create_ap)需要自行安装。
```shell
$ cd tools
$ sudo create_ap --ieee80211n -c 2 wlp8s0 eth0 wifi wifi-passpd # 或其他方式开启AP热点
$ sudo ./iaxcsi-activate.sh
```

### Monitor模式
在AP模式下，IAX只能获取已连接客户端的CSI数据。与之相比，Monitor模式下IAX可以通过监听周围环境的无线流量来获取CSI，如下图所示。
这里的Monitor模式，类似于以太网中的混杂模式，但是在无信通信中需要处于相同信道上。

<div align="center">
<img src="res/iax-monitor.png" width="40%" title="IAX Monitor Mode"/>
</div>

如下所示，IAX在`wlp8s0`网卡上监听信道40，160MHz带宽的CSI。
```shell
$ cd tools
$ sudo ./iaxcsi-set-monitor.sh wlp8s0 40 HE160
```

### Injector模式
Injector模式是Monitor模式的一种，但不同于Monitor模式的只读操作，其是向信道写入数据。
通过在Injector模式下注入自定义协议、带宽等属性的数据包，可用于测试和评估无线网络的性能。

配置上与Monitor模式类似，但需要额外的数据包注入操作，如下所示。
```shell
$ cd injection
$ sudo ./setup.sh # 仅首次运行
$ sudo ./inject.sh 网卡 包数 间隔微秒 # 默认按照5300 MAC，可修改脚本
$ # sudo ./inject.sh wlp8s0mon0 100 1000
```
由于Injector注入端不会获取CSI，因此不需进行其他步骤。而接收端需使用Monitor模式进行数据接收。

## 监听CSI数据
在配置完成后，当接收到符合条件的数据包时，用户层进程会接收到来自驱动的CSI数据。
### C++
可指定监听的网卡及保存文件路径，网络功能是可选项，如下所示。注释例子表示监听`wlp8s0mon0`的CSI，保存到本地文件，并发送到指定TCP服务端。
```shell
$ cd csi/iaxcsi/cpp
$ sudo ./setup.sh # 仅首次运行
$ sudo ./iaxcsi 网卡 保存文件 [TCP服务器地址，如127.0.0.1:12345]
$ # sudo ./iaxcsi wlp8s0mon0 /tmp/iax.csi 127.0.0.1:12345
```
### Python
TODO

## CSI解析
在收到来自驱动的CSI数据后，以下将进行CSI头信息和矩阵的解析。
### Matlab
1. 读取文件中的CSI：
    ```matlab
    > envs %添加依赖路径
    > iaxcsi("iax.csi").read()
    ```
2. 开启TCP服务实时接收CSI：
    ```matlab
    > envs
    > h = iaxcsi("tcp-server:0.0.0.0:12345");
    > st = h.read_next();
    > st = h.read_next();
    ```
    ```matlab
    > envs
    > h = iaxcsi("tcp-server:0.0.0.0:12345");
    > h.set("read_count", 100);
    > sts = h.read();
    ```
`iaxcsi(args)`的`args`可为：
1. CSI文件路径，如`./iax.csi`。
2. 网络地址，如`tcp-server:0.0.0.0:12345`表示将作为TCP服务端接收CSI数据。同理还有“tcp-client”，“udp-server”，“udp-client”。

`h=iaxcsi(args)`返回的对象可提供操作：
1. `read_st(buf)`，可根据`buf`返回CSI数据。
2. `read_next()`，可逐次返回CSI数据。
3. `read()`，返回所有CSI数据。
4. `set("key", val [, "key2", val2])`，设置参数，如对于网络地址，可在`read`前`h.set("read_count", 100, "read_time", 10)`来设置读取次数和超时。

### Python
TODO

## 完整例子
### 监听信道40上VHT80的CSI
```shell
$ sudo ./tools/iaxcsi-set-monitor.sh wlp8s0 40 VHT80
$ sudo ./csi/iaxcsi/cpp/iaxcsi wlp8s0mon0 /tmp/iax.csi
```
```matlab
> envs
> sts = iaxcsi("/tmp/iax.csi").read();
```
### 实时监听信道40上VHT80的CSI
```matlab
> envs
> h = iaxcsi("tcp-server:0.0.0.0:12345").set("read_count", 100);
> sts = h.read();
```
```shell
$ sudo ./tools/iaxcsi-set-monitor.sh wlp8s0 40 VHT80
$ sudo ./csi/iaxcsi/cpp/iaxcsi wlp8s0mon0 /tmp/iax.csi 127.0.0.1:12345
```
## 恢复
恢复原始的驱动和固件。
```shell
$ cd iwlwifi
$ sudo ./restore.sh
```

# 其他
## 脚本说明
### Intel AX CSI参数配置 
```shell
$ cd tools
$ sudo ./iaxcsi-activate.sh [CHN_TYPE] [INTERVAL_US] [MACS]
$ # sudo ./iaxcsi-activate.sh VHT40- 1000 00:16:ea:12:34:56 00:16:ea:12:34:57
```
`CHN_TYPE`为信道类型，如VHT40-，HE160等。`INTERVAL_US`为间隔时间，单位微秒。`MACS`为过滤MAC地址。还有些不常修改的参数可在脚本中进行修改，如Injector模式下的天线选择。

例子表示监听，MAC地址为“00:16:ea:12:34:56”或“00:16:ea:12:34:57”，信道带宽为40MHz，获取间隔为1000us的CSI数据。而若为Injector模式，则还指定了注入的数据包为VHT类型。

### Intel AX监听设置
```shell
$ cd tools
$ sudo ./iaxcsi-set-monitor.sh WLAN CHN CHN_TYPE [INTERVAL_US] [MACS]
$ # sudo ./iaxcsi-set-monitor.sh wlp8s0 40 HE160
```
`WLAN`为网口接口，如`wlp8s0`。`CHN`为信道号。其余类似`iaxcsi-activate.sh`。部分不常修改参数可在脚本中修改，如接收CSI数量。
`wlp8s0`生成的监听网口名如`wlp8s0mon0`。

若针对的是5300用的`00:16:ea:12:34:56` MAC地址，则可用`iaxcsi-set-injector.sh`代替上面的`iaxcsi-set-monitor.sh`。

## 其他说明
* Intel AX210/211支持6G下CSI。
* Intel AX201的固件尚未包含，使用系统自带的尚不明确。（暂无设备调试）
* 注入数据包的天线选择可在`iaxcsi-activate.sh`中修改。
* `incsi`对应Intel 5300 CSI功能，使用类似。

# FAQ
## 重新配置
很多问题可通过重新配置来解决。
```shell
$ cd iwlwifi
$ sudo ./setup.sh
```
## 失败检查
在激活失败时可查看`dmesg`检查，可能原因包括： 
1. 内核版本不对应（非5.15.x），可通过`uname -r`检查。
2. 安装过程失败。

## 数据接收错误
在cpp程序运行中，返回-28、-31或别的错误，可能原因：
1. 未使用sudo运行。
2. 存储的目标文件权限问题。

# 技术支持
## Intelligent Perception Lab
<a href="https://ustc-ip-lab.github.io/">![SEEMOO logo](https://ustc-ip-lab.github.io/media/logo_hua1e91360984d470552124c70967b3097_101197_0x70_resize_lanczos_3.png)</a>
