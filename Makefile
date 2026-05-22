CONFIG      := infra/config.bu
COREOS      := fedora-coreos-44.20260419.3.1
STREAM      := stable

BUILDDIR    := build
DATADIR     := $(BUILDDIR)/data
LOCALIMAGE  := $(BUILDDIR)/$(COREOS)-qemu.x86_64.qcow2
IGNITION    := $(BUILDDIR)/config.ign
QUAYIO      ?= quay.io

REMOTEARCH  := aarch64
REMOTEIMAGE := $(BUILDDIR)/$(COREOS)-hetzner.$(REMOTEARCH).raw.xz

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

$(REMOTEIMAGE):
	mkdir -p "$(BUILDDIR)"
	podman run --rm -it \
		--security-opt label=disable \
		--pull=always \
		-v "./$(BUILDDIR)://data" -w //data \
		"$(QUAYIO)/coreos/coreos-installer:release" \
			download -s "$(STREAM)" -p hetzner -a "$(REMOTEARCH)" -C //data

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
		-nic "user,model=virtio,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080" \
		-chardev "vc,id=char0,logfile=$(BUILDDIR)/qemu-serial.log" \
		-serial chardev:char0

upload: $(REMOTEIMAGE)
	hcloud-upload-image upload \
		--architecture "$(REMOTEARCH)" \
		--compression xz \
		--image-path "$(IMAGE_NAME)" \
		--labels "os=fedora-coreos,channel=$(STREAM)" \
		--description "Fedora CoreOS ($(STREAM), $(REMOTEARCH))"

remote: $(IGNITION) upload
	hcloud server create \
		--name "$(SERVERNAME)" \
		--type "$(SERVERTYPE)" \
		--datacenter "$(DATACENTER)" \
		--image "$(IMAGEID)" \
		--ssh-key "$(SSHKEYNAME)" \
		--user-data-from-file "$(IGNITION)"

clean:
	rm -f $(IGNITION) $(LOCALIMAGE) $(REMOTEIMAGE)
