<h1 align="center">Local Windows on Docker<br />
<div align="center">
<a href="https://github.com/dockur/windows"><img src="./.github/logo.png" title="Logo" style="max-width:100%;" width="128" /></a>
</div>
<div align="center">
 
</div></h1>

Local Windows inside a Docker container.

## Usage 🐳

### Building the Image

```bash
docker build -t windows-local:latest .
```

### Preparing Golden Image (First Time)

Mount your Windows ISO and let it install automatically:

```bash
docker run -it --rm \
  --name prepare-windows \
  --device=/dev/kvm \
  --cap-add NET_ADMIN \
  --mount type=bind,source=/path/to/windows.iso,target=/custom.iso \
  -v /path/to/storage:/storage \
  -p 8006:8006 \
  -e RAM_SIZE=4G \
  -e CPU_CORES=2 \
  -e DISK_SIZE=64G \
  --stop-timeout 120 \
  windows-local:latest
```

The container will automatically:
- Install Windows with automated configuration
- Create a golden image in `/storage`
- Exit when preparation is complete

### Running from Golden Image

After preparation, start Windows from the saved golden image:

```bash
docker run -it --rm \
  --name windows \
  --device=/dev/kvm \
  --cap-add NET_ADMIN \
  -v /path/to/storage:/storage \
  -p 8006:8006 \
  -p 3389:3389 \
  -e RAM_SIZE=8G \
  -e CPU_CORES=4 \
  --stop-timeout 120 \
  windows-local:latest
```

Access the desktop via browser at http://localhost:8006

### Custom Installation with OEM Scripts

You can provide custom installation scripts that run after installation:

```bash
docker run -it --rm \
  --name prepare-windows \
  --device=/dev/kvm \
  --cap-add NET_ADMIN \
  --mount type=bind,source=/path/to/windows.iso,target=/custom.iso \
  --mount type=bind,source=/path/to/oem,target=/oem \
  -v /path/to/storage:/storage \
  -p 8006:8006 \
  --stop-timeout 120 \
  windows-local:latest
```

Create an `/oem/install.bat` script that will execute after installation:

```batch
@echo off
REM Example OEM installation script

REM Install additional software
echo Installing additional packages...

REM Configure system
echo Custom setup complete!
```

## Compatibility ⚙️

| **Product**  | **Platform**   | |
|---|---|---|
| Docker Engine | Linux| ✅ |
| Docker Desktop | Linux | ❌ |
| Docker Desktop | macOS | ❌ |
| Docker Desktop | Windows 11 | ✅ |
| Docker Desktop | Windows 10 | ❌ |

## FAQ 💬

### How do I use it?

  **Download Windows 11 Enterprise ISO:**

  1. Visit [Microsoft Evaluation Center](https://info.microsoft.com/ww-landing-windows-11-enterprise.html)
  2. Accept the Terms of Service
  3. Download **Windows 11 Enterprise Evaluation (90-day trial, English, United States)** ISO file [~6GB]

  **Then follow these steps:**
  
  - Start the container and connect to [port 8006](http://localhost:8006) using your web browser.

  - Sit back and relax while the magic happens, the whole installation will be performed fully automatic.

  - Once you see the desktop, your Windows installation is ready for use.
  
  Enjoy your brand new machine, and don't forget to star this repo!

### How do I select the Windows language?

  By default, the English version of Windows will be downloaded. But you can specify an alternative language using the `LANGUAGE` environment variable:

  ```bash
  -e LANGUAGE="French"
  ```
  
  You can choose between: 🇦🇪 Arabic, 🇧🇬 Bulgarian, 🇨🇳 Chinese, 🇭🇷 Croatian, 🇨🇿 Czech, 🇩🇰 Danish, 🇳🇱 Dutch, 🇬🇧 English, 🇪🇪 Estionian, 🇫🇮 Finnish, 🇫🇷 French, 🇩🇪 German, 🇬🇷 Greek, 🇮🇱 Hebrew, 🇭🇺 Hungarian, 🇮🇹 Italian, 🇯🇵 Japanese, 🇰🇷 Korean, 🇱🇻 Latvian, 🇱🇹 Lithuanian, 🇳🇴 Norwegian, 🇵🇱 Polish, 🇵🇹 Portuguese, 🇷🇴 Romanian, 🇷🇺 Russian, 🇷🇸 Serbian, 🇸🇰 Slovak, 🇸🇮 Slovenian, 🇪🇸 Spanish, 🇸🇪 Swedish, 🇹🇭 Thai, 🇹🇷 Turkish and 🇺🇦 Ukrainian.

### How do I select the keyboard layout?

  If you want to use a keyboard layout or locale that is not the default for your selected language, you can specify the `KEYBOARD` and `REGION` variables with a culture code:

  ```bash
  -e REGION="en-US" \
  -e KEYBOARD="en-US"
  ```

> [!NOTE]  
>  Changing these values will have no effect after the installation has been performed already. Use the control panel inside Windows in that case.

### How do I change the storage location?

  To change the storage location, modify the volume mount:

  ```bash
  -v /custom/storage/path:/storage
  ```

### How do I change the size of the disk?

  To expand the default size of 64 GB, set the `DISK_SIZE` environment variable:

  ```bash
  -e DISK_SIZE="256G"
  ```
  
> [!TIP]
> This can also be used to resize the existing disk to a larger capacity without any data loss.

### How do I share files with the host?

  Open 'File Explorer' and click on the 'Network' section, you will see a computer called `host.lan`. Double-click it and it will show a folder called `Data`, which can be bound to any folder on your host:

  ```bash
  -v /home/user/example:/data
  ```

  The example folder `/home/user/example` will be available as ` \\host.lan\Data`.
  
> [!TIP]
> You can map this path to a drive letter in Windows, for easier access.

### How do I run a script after installation?

  To run your own script after installation, you can create a file called `install.bat` and place it in a folder together with any additional files it needs (software to be installed for example). Then bind that folder:

  ```bash
  --mount type=bind,source=/home/user/example,target=/oem
  ```

  The example folder `/home/user/example` will be copied to `C:\OEM` during installation and the containing `install.bat` will be executed during the last step.

  See the [Custom Installation with OEM Scripts](#custom-installation-with-oem-scripts) section above for a complete example.

### How do I change the amount of CPU or RAM?

  By default, the container will be allowed to use a maximum of 2 CPU cores and 4 GB of RAM.

  If you want to adjust this, specify the desired amount:

  ```bash
  -e RAM_SIZE="8G" \
  -e CPU_CORES="4"
  ```

### How do I configure the username and password?

  By default, a user called `Docker` is created during the installation, with an empty password.

  If you want to use different credentials, specify them:

  ```bash
  -e USERNAME="bill" \
  -e PASSWORD="gates"
  ```

### How do I select the Windows language?

  By default, the English version of Windows will be downloaded. But you can specify an alternative language using the `LANGUAGE` environment variable:

  ```bash
  -e LANGUAGE="French"
  ```
  
  You can choose between: 🇦🇪 Arabic, 🇧🇬 Bulgarian, 🇨🇳 Chinese, 🇭🇷 Croatian, 🇨🇿 Czech, 🇩🇰 Danish, 🇳🇱 Dutch, 🇬🇧 English, 🇪🇪 Estonian, 🇫🇮 Finnish, 🇫🇷 French, 🇩🇪 German, 🇬🇷 Greek, 🇮🇱 Hebrew, 🇭🇺 Hungarian, 🇮🇹 Italian, 🇯🇵 Japanese, 🇰🇷 Korean, 🇱🇻 Latvian, 🇱🇹 Lithuanian, 🇳🇴 Norwegian, 🇵🇱 Polish, 🇵🇹 Portuguese, 🇷🇴 Romanian, 🇷🇺 Russian, 🇷🇸 Serbian, 🇸🇰 Slovak, 🇸🇮 Slovenian, 🇪🇸 Spanish, 🇸🇪 Swedish, 🇹🇭 Thai, 🇹🇷 Turkish and 🇺🇦 Ukrainian.

### How do I select the keyboard layout?

  If you want to use a keyboard layout or locale that is not the default for your selected language, you can specify the `KEYBOARD` and `REGION` variables with a culture code:

  ```bash
  -e REGION="en-US" \
  -e KEYBOARD="en-US"
  ```

> [!NOTE]  
>  Changing these values will have no effect after the installation has been performed already. Use the control panel inside Windows in that case.
>

### How do I connect using RDP?

  The web-viewer is mainly meant to be used during installation, as its picture quality is low, and it has no audio or clipboard for example.

  So for a better experience you can connect using any Microsoft Remote Desktop client to the IP of the container, using the username `Docker` and by leaving the password empty.

### How do I assign an individual IP address to the container?

  By default, the container uses bridge networking, which shares the IP address with the host. 

  If you want to assign an individual IP address to the container, you can create a macvlan network as follows:

  ```bash
  docker network create -d macvlan \
      --subnet=192.168.0.0/24 \
      --gateway=192.168.0.1 \
      --ip-range=192.168.0.100/28 \
      -o parent=eth0 vlan
  ```
  
  Be sure to modify these values to match your local subnet. 

  Once you have created the network, add the network configuration to your run command:

  ```bash
  docker run -it --rm \
    --name windows \
    --network vlan \
    --ip 192.168.0.100 \
    ...
  ```
 
  An added benefit of this approach is that you won't have to perform any port mapping anymore, since all ports will be exposed by default.

> [!IMPORTANT]  
> This IP address won't be accessible from the Docker host due to the design of macvlan, which doesn't permit communication between the two. If this is a concern, you need to create a [second macvlan](https://blog.oddbit.com/post/2018-03-12-using-docker-macvlan-networks/#host-access) as a workaround.

### How can Windows acquire an IP address from my router?

  After configuring the container for [macvlan](#how-do-i-assign-an-individual-ip-address-to-the-container), it is possible for Windows to become part of your home network by requesting an IP from your router, just like a real PC.

  To enable this mode, add the following to your run command:

  ```bash
  -e DHCP="Y" \
  --device=/dev/vhost-net \
  --device-cgroup-rule='c *:* rwm'
  ```

> [!NOTE]  
> In this mode, the container and Windows will each have their own separate IPs.

### How do I add multiple disks?

  To create additional disks, add the following to your run command:

  ```bash
  -e DISK2_SIZE="32G" \
  -e DISK3_SIZE="64G" \
  -v /home/example:/storage2 \
  -v /mnt/data/example:/storage3
  ```

### How do I pass-through a disk?

  It is possible to pass-through disk devices directly:

  ```bash
  --device=/dev/sdb:/disk1 \
  --device=/dev/sdc:/disk2
  ```

  Use `/disk1` if you want it to become your main drive (which will be formatted during installation), and use `/disk2` and higher to add them as secondary drives (which will stay untouched).

### How do I pass-through a USB device?

  To pass-through a USB device, first lookup its vendor and product id via the `lsusb` command, then add them to your run command:

  ```bash
  -e ARGUMENTS="-device usb-host,vendorid=0x1234,productid=0x1234" \
  --device=/dev/bus/usb
  ```

> [!IMPORTANT]
> If the device is a USB disk drive, please wait until after the installation is completed before connecting it. Otherwise the installation may fail, as the order of the disks can get rearranged.

### How do I verify if my system supports KVM?

  Only Linux and Windows 11 support KVM virtualization, macOS and Windows 10 do not unfortunately.
  
  You can run the following commands in Linux to check your system:

  ```bash
  sudo apt install cpu-checker
  sudo kvm-ok
  ```

  If you receive an error from `kvm-ok` indicating that KVM cannot be used, please check whether:

  - the virtualization extensions (`Intel VT-x` or `AMD SVM`) are enabled in your BIOS.

  - you enabled "nested virtualization" if you are running the container inside a virtual machine.

  - you are not using a cloud provider, as most of them do not allow nested virtualization for their VPS's.

  If you didn't receive any error from `kvm-ok` at all, but the container still complains that `/dev/kvm` is missing, try adding `--privileged` to your `run` command to rule out any permission issue.
  