# Documentation who does that?

## Installing a vm so that i won't ruin my system

- <https://ubuntu.com/download/kvm>
- <https://wiki.archlinux.org/title/QEMU>
- <https://www.qemu.org/docs/master/system/images.html>

```sh
    # https://ubuntu.com/download/kvm

    # Install kvm
    sudo apt install qemu-system-x86

    # Test kvm
    kvm-ok

    # create disk
    qemu-img create -f raw drive-1.raw 10G

    # install os on disk
    qemu-system-x86_64 -m 2G -cdrom ubuntu-22.04.1-live-server-amd64.iso  -boot order=d -drive file=drive-1.raw,format=raw

    # on vm 
     sudo apt install spice-vdagent
```
