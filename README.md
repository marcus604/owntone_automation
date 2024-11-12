# Owntone Server Automation
This project provides terraform and ansible resources to fully automate the setup of an [Owntone server](https://github.com/owntone/owntone-server). **The configuration is designed specifically to capture line-in audio from a source, like a record player, and stream it to any compatible AirPlay device.**

This was built around my own hardware and setup but many things are set by variables so it should be adaptable for your own hardware and setup. Feel free to open an issue if there is something that doesnt work or is not needed and I can parameterize it. 

## Prequisities

* Some sort of linux machine (ie VM, Container, Baremetal)
* USB Audio Capture Card that supports linux
* A source audio device you'd like to airplay (ie record player)
* At least one airplay device (ie homepod, apple tv)
* Ansible installed on your local machine
* (Optional) Terraform installed on your local machine if you want to use the provided terraform files to provision your VM
* SSH Keys
* A copy of the repo on your local machine; `git clone https://github.com/marcus604/owntone_automation`

### How to get the map id for your usb audio capture device

1. Plug the usb audio capture device into a supported linux machine (doesnt need to be the one you will end up deploying Owntone too)
2. List usb devices 
    ```
    lsusb
    ```
3. You will get a list of all usb devices detected
    ```
    owntone@owntone:~$ lsusb
    Bus 001 Device 001: ID 1d6b:0002 Linux Foundation 2.0 root hub
    Bus 001 Device 002: ID 534d:0021 MacroSilicon MS210x Video Grabber [EasierCAP]
    Bus 002 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    Bus 002 Device 002: ID 0627:0001 Adomax Technology Co., Ltd QEMU Tablet
    Bus 003 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    Bus 004 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    Bus 005 Device 001: ID 1d6b:0001 Linux Foundation 1.1 root hub
    ```
4. Your device may have a different description, if you can't determine which it is then unplug and run `lsusb` to compare the outputs
5. Grab the map ID's, in the above its `534d:0021`




## Terraform/Proxmox Setup - Skip to the Ansible setup if you arent using proxmox or dont want to use terraform to generate the VM and its required resources

1. Populate the `proxmox.tfvars` file with your environment details. Follow the [terraform docs for the bpg proxmox provider](https://registry.terraform.io/providers/bpg/proxmox/latest/docs) for more in depth details
    1. **Note** Many proxmox api calls including mapping a usb device to a VM require you to be root, so make sure you are authenticating the provider using the root account.
2. Initialize your terraform
    
    ```
    terraform init
    ```
3. Apply the terraform
    ```
    terraform apply -var-file=proxmox.tfvars
    ```
4. Resources provisioned
    1. `proxmox_virtual_environment_vm` - Virtual machine to run Owntone
    2. `proxmox_virtual_environment_hardware_mapping_usb` - Usb audio capture card that will be passed to the VM
    3. `proxmox_virtual_environment_download_file` - Latest cloud image of Ubuntu 24.04
    4. `proxmox_virtual_environment_file` - Cloud-init config which creates an ansible user and updates the OS
5. Get the IP address of the VM from your router or using a network scanning app on your phone

Note that the cloud-init runs a update of all packages and finishes with a restart so if you ssh into it quickly you may get booted out when it does that restart.

## Ansible Overview

This ansible playbook will 
* Install necessary packages for owntone
* Ensure the usb audio device is identified by configuring snd-usb-audio to load on boot
* Create necessary owntone directories and FIFOs (used for the piped audio)
* Install and configure Owntone to load on boot
* Install service to always pipe audio to Owntone on boot


### Owntone Installation
Downloads and installs Owntone from source. This step prepares Owntone to run with minimal extras.

### Configuration File Setup
Copies a custom Owntone settings file to `/etc/owntone.conf` with specific configurations for this setup. This file tells Owntone how to handle and monitor audio. You may edit this for your own setup

### Systemd Services Setup
- Creates a background service `play_audio_in.service` to continuously capture audio and send it to Owntone.
- Makes sure `play_audio_in.service` and Owntone are set to automatically start whenever the system boots up and to restart if they stop unexpectedly.

### Audio Configuration
- Adds the `snd-usb-audio` module to load at boot, ensuring audio input devices are recognized.
- Creates necessary directory structures for audio files and a FIFO file, which is used to pipe audio data into Owntone.

## Ansible Setup

At this point you should have a VM/container/host that you can SSH into with the `ansible` user with the ssh key you provided and the audio capture card should be detectable which you can test using the `lsusb` command

1.  Populate your `host_vars/owntone` file with the IP address of your host and the ssh key(s)
2. Update the `roles/owntone/files/owntone.conf` for your environment
    1. `pipe_sample_rate` - If your audio is slow/fast/garbled you likely need to update this for your card. Check your cards hardware parameters `cat card<NUM>/pcm0c/sub0/hw_params`
    2. Check the [Owntone Docs](https://owntone.github.io/owntone-server/configuration/) for all available settings


## Ansible Usage

The default run waits for cloud-init tasks to be done. If you are not using cloud-init then set `no_cloud=true`.

### Example Commands

- **Run with cloud-init tasks**:
    ```bash
    ansible-playbook -i inventory owntone-site.yml
    ```

- **Skip cloud-init tasks**:
    ```bash
    ansible-playbook -i inventory owntone-site.yml -e "no_cloud=true"
    ```

# Troubleshooting Guide

If you're having trouble getting your setup to work, here are some steps to help you troubleshoot common issues.

---

## 1. Check USB Audio Device Detection

Ensure your USB audio device is recognized by the system:

```bash
lsusb
```

- Look for your device’s **Vendor ID** and **Product ID** in the output.
- If your device doesn’t appear, try reconnecting it or using a different USB port.

## 2. Verify Device Visibility for Owntone User

Check that the `owntone` user has access to the audio device:

```bash
sudo -u owntone arecord -l
```

- This command lists available audio capture devices for the `owntone` user.
- Confirm that your device is listed. If it’s not, verify the `owntone` user has appropriate permissions or check for device driver issues.

## 3. Test Owntone Audio Playback

To make sure Owntone can play audio, upload a test audio file to your Owntone media directory:

1. Copy an audio file (e.g., `.mp3`, `.wav`) to your Owntone directory, usually located at `/srv/music`.
2. Access the Owntone web interface or app and check if the uploaded file is visible.
3. Try playing the file on an AirPlay device to ensure audio output is working.

---

## Additional Checks

If issues persist, consider reviewing system logs or using commands like `dmesg` to check for USB device errors or `systemctl status owntone` to review Owntone’s service logs.

If you think its a playbook related issue by all means open an issue or even better a PR 😀

---

# Usage

1. Browse to either `https://owntone.local:3689` or use your Owntone servers ip `https://<IP_ADDRESS>:3689`
2. Navigate to `Settings` and select `Remotes and Outputs` 
3. From your list of your airplay supported devices select one or more to play to. You may require to enter in a passcode depending on your device
4. Start playing from your audio in device and enjoy 😀
5. (Optional) For iOS users I recommend adding a home screen shortcut for your instance directly to http://owntone.local:3689/#/settings/remotes-outputs. 



