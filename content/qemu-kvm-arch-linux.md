---
title: "Setting Up QEMU/KVM on Arch Linux/CachyOS: Virtualization That Doesn't Suck"
date: 2026-02-18T12:00:00Z
draft: false
tags: ["linux", "arch linux", "cachyos", "virtualization", "qemu", "kvm"]
description: "A straightforward guide to running virtual machines on Arch Linux with QEMU/KVM and Virt-Manager"
---

## Why QEMU/KVM?

Here's the thing: KVM is built into the Linux kernel[^1]. It's not a third-party module that might break. QEMU handles the hardware emulation[^1], KVM provides near-native performance, and Virt-Manager gives you a GUI that doesn't make you want to throw your keyboard.

## Check Your Hardware First

Before we start, make sure your CPU actually supports virtualization:

```bash
lscpu | grep Virtualization
```

You should see either:

```
Virtualization: VT-x      # Intel
Virtualization: AMD-V     # AMD
```

If you see nothing, check your BIOS/UEFI settings. Look for "Intel VT-x", "AMD-V", "SVM Mode", or something similar. It's usually disabled by default.

## Installation

On Arch or CachyOS:

```bash
sudo pacman -S qemu-full virt-manager virt-viewer dnsmasq bridge-utils libguestfs swtpm
```

What you're getting:

- **qemu-full** — The actual emulator with all features
- **virt-manager** — GUI for managing VMs (trust me, you want this)
- **virt-viewer** — Display client for VMs
- **dnsmasq** — Handles DHCP/DNS for virtual networks
- **bridge-utils** — Network bridging tools
- **libguestfs** — Tools for accessing VM disk images
- **swtpm** - TPM software emulator built on libtpms.

## Enable the Services

The libvirt daemon needs to be running[^2]:

```bash
sudo systemctl enable --now libvirtd.service
```

## QEMU backend (for VMs[^2]):
```bash
systemctl enable --now libvirtd.socket
```

For the default NAT network to work automatically:

```bash
sudo virsh net-autostart default
sudo virsh net-start default
```
The thing I had most fun debugging and why I decided to write the blog post is **specifying** If `iptables` is to be used or `nftables` in the configuration:

> **Important:** Uncomment the following in `/etc/libvirt/network.conf`:
>
> ```
> # default: #firewall_backend = "nftables"
> firewall_backend = "iptables"
> ```

## Add Yourself to the Right Groups

This lets you manage VMs without typing your password every five seconds:

```bash
sudo usermod -aG libvirt $USER
```

Log out and back in for the group changes to take effect. Or if you're impatient like me:

```bash
newgrp libvirt
```

## Using Virt-Manager

Open Virt-Manager from your application menu or run `virt-manager`. Creating a VM is straightforward:

1. Click the "Create a new virtual machine" button
2. Choose your installation media (ISO file)
3. Allocate CPU and RAM — I usually do 2 cores and 4GB for testing
4. Create a virtual disk or use an existing one
5. Click through and you're done

## Performance Tips

### Enable Hugepages (Optional)

For VMs that need serious performance, hugepages reduce memory management overhead:

```bash
# Check current hugepages
cat /proc/meminfo | grep Huge

# Enable temporarily (1024 x 2MB = 2GB for VMs)
sudo sysctl -w vm.nr_hugepages=1024
```

To make it permanent, add to `/etc/sysctl.d/40-hugepages.conf`:

```
vm.nr_hugepages = 1024
```

### CPU Pinning

If you're running a VM that needs consistent performance, you can pin virtual CPUs to physical cores. In Virt-Manager:

1. Open VM details → CPUs
2. Click "Topology" and set sockets/cores/threads manually
3. Under "CPU Pinning", assign vCPUs to specific host CPUs

### Use VirtIO Drivers

When creating VMs, use VirtIO for disk and network. It's paravirtualized, meaning the guest OS knows it's in a VM and cooperates instead of pretending to be real hardware.

For Windows guests, you'll need to load the VirtIO drivers during installation. Grab the ISO from the [Fedora project](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso)[^3].

## Quick CLI Reference

Sometimes the terminal is faster:

```bash
# List all VMs
virsh list --all

# Start a VM
virsh start vm-name

# Graceful shutdown
virsh shutdown vm-name

# Force stop (like pulling the power)
virsh destroy vm-name

# Delete a VM and its storage
virsh undefine vm-name --remove-all-storage

# Take a snapshot
virsh snapshot-create-as vm-name snapshot-name

# Revert to snapshot
virsh snapshot-revert vm-name snapshot-name
```

**Network not available**

The default network probably isn't running:

```bash
sudo virsh net-start default
```

---

That's it. You now have a proper virtualization setup that won't break every time you update your kernel. Welcome to the KVM club.

[^1]: [CachyOS Wiki - Virtualization](https://wiki.cachyos.org/virtualization/qemu_and_vmm_setup/) — Kernel-based Virtual Machine documentation

[^2]: [Arch Wiki - libvirt](https://wiki.archlinux.org/title/Libvirt) — Virtualization API and daemon configuration

[^3]: [VirtIO Windows Drivers](https://github.com/virtio-win/virtio-win-pkg-scripts) — Paravirtualized drivers for Windows guests
