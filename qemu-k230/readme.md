### SDK 方面的临时改动
1. sdk_gen_image_script 生成 fit 镜像不采用压缩，否则uboot 调用 bootm 会报错

2. sdk_gen_image_script 直接从src 目录获取自己改动过 dts 文件， 自定义的 dts 更加方便调试

3. makefile 的 little-core-opensbi 选项直接把spl-opensbi 和预编译的kernel 打包成 ulinux.bin, 而不是使用 k230 的 sdk kernel 。 sdk 的 kernel 还不能正确启动，大概可能是 MMU 的问题 

4. initramfs 也是自定义而不是官方的 sdk initramfs，参考 https://tinylab.org/boot-riscv-linux-kernel-with-uboot-on-qemu-virt-machine/

以下是生成代码方法
```bash
git clone https://gitee.com/mirrors/busyboxsource
cd busyboxsource
export CROSS_COMPILE="/opt/toolchain/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.0/bin/riscv64-unknown-linux-gnu-"
make defconfig
make menuconfig
# 这里启用了 Settings-->Build Options 里的 Build static binary (no shared libs) 选项
make -j $(nproc)
make install
cd ~
mkdir rootfs_temp
cd rootfs_temp
cp -r ../busyboxsource/_install/* .
mkdir -p proc sys dev etc etc/init.d tmp var/log
sudo mknod dev/console c 5 1
sudo mknod dev/null c 1 3
# rcS 脚本
cat << 'EOF' > etc/init.d/rcS
bash
#!/bin/sh

# 1. 挂载基础虚拟文件系统
mount -t proc none /proc
mount -t sysfs none /sys

# 2. 确保/dev目录存在
mkdir -p /dev

# 3. 挂载devtmpfs到/dev（解决核心错误）
mount -t devtmpfs devtmpfs /dev

# 4. 设置mdev为热插拔处理程序
echo /sbin/mdev > /proc/sys/kernel/hotplug

# 5. 扫描并创建设备节点
mdev -s

mknod /dev/null c 1 3
mknod /dev/zero c 1 5
mknod /dev/console c 5 1
EOF
chmod +x etc/init.d/rcS
find . | cpio -o --format=newc > ../rootfs.cpio
cd ..
../../little/uboot/tools/mkimage -A riscv -T ramdisk -d rootfs.cpio initrd.img
```

### 常用命令

```bash
make -j16 CROSS_COMPILE="/opt/toolchain/Xuantie-900-gcc-linux-5.10.4-glibc-x86_64-V2.6.0/bin/riscv64-unknown-linux-gnu-" ARCH=riscv k230_canmv_defconfig ## 编译官方非SDK的内核

#打包 ulinux.bin
make little-core-opensbi-clean
make little-core-opensbi

#重新编译uboot
make uboot-rebuild