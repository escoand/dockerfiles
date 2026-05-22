CONFIG      := infra/config.bu
COREOS      := 44.20260419.3.1
STREAM      := stable

BUILDDIR    := build
DATADIR     := $(BUILDDIR)/data
LOCALIMAGE  := $(BUILDDIR)/fedora-coreos-$(COREOS)-qemu.x86_64.qcow2
IGNITION    := $(BUILDDIR)/config.ign
QUAYIO      ?= quay.io

REMOTELOCATION := fsn1
REMOTEBASE     := fedora-44
REMOTERESCUER  := coreos-rescue
REMOTEIMAGE    := coreos-snapshot
REMOTEARCH     := x86_64
REMOTEKEY      := /tmp/$(REMOTERESCUER).key

.PHONY: all local upload remote clean

all: local

$(LOCALIMAGE):
	mkdir -p "$(BUILDDIR)"
	podman run --rm -it \
		--security-opt label=disable \
		--pull=always \
		-v ."/$(BUILDDIR)://data" -w //data \
		$(QUAYIO)/coreos/coreos-installer:release \
			download -s "$(STREAM)" -p qemu -f qcow2.xz -C //data

$(IGNITION): $(CONFIG)
	mkdir -p "$(BUILDDIR)"
	podman run --rm -i \
		-v .://data -w //data \
		"$(QUAYIO)/coreos/butane:release" \
			--files-dir //data --pretty --strict "//data/$(CONFIG)" > $@

local: $(IGNITION) $(LOCALIMAGE)
	mkdir -p "$(DATADIR)"
	kvm \
		-snapshot \
		-m 4096 \
		-boot c \
		-drive "if=virtio,file=$(LOCALIMAGE)" \
		-drive "if=virtio,file=fat:ro:$(DATADIR)" \
		-fw_cfg "name=opt/com.coreos/config,file=$(IGNITION)" \
		-nic "user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:80" \
		-chardev "vc,id=char0,logfile=$(BUILDDIR)/qemu-serial.log" \
		-serial chardev:char0

remote-setup: $(REMOTEKEY)
	ssh-keygen -b 2048 -t rsa -f "$(REMOTEKEY)" -q -N ""
	hcloud context create --token-from-env "$(REMOTERESCUER)"
	hcloud ssh-key create \
		--name "$(REMOTERESCUER)" \
		--public-key-from-file "$(REMOTEKEY).pub"

remote-image: $(IGNITION) remote-setup
	hcloud server create \
		--location "$(REMOTELOCATION)" \
		--type cpx22 \
		--image "$(REMOTEBASE)" \
		--name "$(REMOTERESCUER)" \
		--start-after-create=false
	hcloud server enable-rescue "$(REMOTERESCUER)" \
		--ssh-key "$(REMOTERESCUER)"
	hcloud server poweron "$(REMOTERESCUER)"
	sleep 60
	hcloud server ssh "$(REMOTERESCUER)" \
		-i "$(REMOTEKEY)" \
		-o StrictHostKeyChecking=no ' \
			cat >config.ign && \
			curl -sL "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/$(COREOS)/$(REMOTEARCH)/fedora-coreos-$(COREOS)-hetzner.$(REMOTEARCH).raw.xz" | \
				xz -d | \
				dd of=/dev/sda status=progress && \
			mount /dev/sda3 /mnt && \
			mkdir /mnt/ignition && \
			cp config.ign /mnt/ignition/ && \
			umount /mnt \
		' < "$(IGNITION)"
	hcloud server poweroff
	hcloud server create-image \
		--description "$(REMOTEIMAGE)" \
		--type snapshot "$(REMOTERESCUER)"
	hcloud image list | grep "$(REMOTEIMAGE)"

remote:
	hcloud server create \
		--location "$(REMOTELOCATION)" \
		--name "$(SERVERNAME)" \
		--type "$(SERVERTYPE)" \
		--image "$(IMAGEID)" \
		--ssh-key "$(SSHKEYNAME)" \
		--user-data-from-file "$(IGNITION)"

remote-clean:
	hcloud server delete "$(REMOTERESCUER)" || true
	hcloud ssh-key delete "$(REMOTERESCUER)" || true
	hcloud context delete "$(REMOTERESCUER)" || true
	rm -f "$(REMOTEKEY)"

clean:
	rm -f $(IGNITION) $(LOCALIMAGE) $(REMOTEIMAGE)
