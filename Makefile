COREOS      := 44.20260419.3.1
STREAM      ?= stable

DOCKER      ?= docker
TMP         ?= /tmp

REMOTELOCATION := fsn1
REMOTEBASE     := fedora-44
REMOTESERVER   := coreos-$(COREOS)
REMOTEKEY      := $(TMP)/$(REMOTESERVER).key

ARCH        := $(shell arch)
QEMU        := qemu-system-$(ARCH)
ifeq ($(OS),Windows_NT)
  QEMU      += -accel whpx
else
  QEMU      += -accel kvm
endif

# board selection
# Allow `make hetzner` to set BOARD during parse time.
BOARD        ?= $(or $(firstword $(filter hetzner,$(MAKECMDGOALS))),qemu)
ifeq ($(BOARD),hetzner)
  ARCH       := x86_64
  FORMAT     := raw
  PLATFORM   := metal
else
  FORMAT     := qcow2
  PLATFORM   := qemu
endif

BUILDDIR    := ./build
ASSETDIR    := $(BUILDDIR)/assets
BASEIMAGE    ?= $(ASSETDIR)/fedora-coreos-$(COREOS)-$(PLATFORM).$(ARCH).$(FORMAT)
SYSTEMDISK   ?= $(BUILDDIR)/$(BOARD).$(ARCH).img
DATADISK     ?= $(BUILDDIR)/data.img

all: qemu

$(BUILDDIR)/%.ign: infra/%.bu
	mkdir -p "$(BUILDDIR)"
	$(DOCKER) run --rm -i \
		-v .:/data \
		quay.io/coreos/butane:release \
			--files-dir /data --pretty --strict "/data/$<" > "$@"

$(ASSETDIR)/fedora-coreos-%:
	mkdir -p "$(ASSETDIR)"
	$(DOCKER) run --rm -it \
		--security-opt label=disable \
		-v "$(ASSETDIR):/assets" \
		quay.io/coreos/coreos-installer:release \
			download \
				--architecture "$(ARCH)" \
				--decompress \
				--directory /assets \
				--format "$(FORMAT).xz" \
				--platform "$(PLATFORM)" \
				--stream "$(STREAM)"

$(BUILDDIR)/%.img: $(BASEIMAGE)
	[ "$(FORMAT)" = qcow2 ] && \
		qemu-img create -f qcow2 -F qcow2 -b "../$<" "$@" || \
		qemu-img convert -f raw -O raw "$<" "$@"

# Qemu targets

$(DATADISK):
	mkdir -p "$(BUILDDIR)"
	qemu-img create -f raw "$@" 1G

$(BUILDDIR)/qemu.ign: $(BUILDDIR)/config.ign

.PHONY: qemu
qemu: $(SYSTEMDISK) $(DATADISK) $(BUILDDIR)/qemu.ign
	$(QEMU) \
		-m 4096 \
		-boot c \
		-drive "if=virtio,file=$(SYSTEMDISK)" \
		-drive "if=virtio,file=$(DATADISK),format=raw" \
		-fw_cfg "name=opt/com.coreos/config,file=$(BUILDDIR)/qemu.ign" \
		-nic "user,model=virtio,hostfwd=tcp:127.0.0.1:8022-:22,hostfwd=tcp:127.0.0.1:8080-:80" \
		-chardev "vc,id=char0,logfile=$(BUILDDIR)/qemu.serial.log" \
		-serial chardev:char0

# Remote targets

$(REMOTEKEY):
	ssh-keygen -b 2048 -t rsa -f "$(REMOTEKEY)" -q -N ""
	hcloud context create "$(REMOTESERVER)"
	hcloud ssh-key create \
		--name "$(REMOTESERVER)" \
		--public-key-from-file "$(REMOTEKEY).pub"

hetzner: $(BUILDDIR)/config.ign $(REMOTEKEY)
	hcloud server create \
		--location "$(REMOTELOCATION)" \
		--type cpx22 \
		--image "$(REMOTEBASE)" \
		--name "$(REMOTESERVER)" \
		--start-after-create=false
	hcloud server enable-rescue "$(REMOTESERVER)" \
		--ssh-key "$(REMOTESERVER)"
	hcloud server poweron "$(REMOTESERVER)"
	sleep 60
	hcloud server ssh "$(REMOTESERVER)" \
		-i "$(REMOTEKEY)" \
		-o StrictHostKeyChecking=no ' \
			cat >config.ign && \
			curl -sL "https://builds.coreos.fedoraproject.org/prod/streams/stable/builds/$(COREOS)/$(ARCH)/fedora-coreos-$(COREOS)-$(PLATFORM).$(ARCH).$(FORMAT).xz" | \
				xz -d | \
				dd of=/dev/sda status=progress && \
			mount /dev/sda3 /mnt && \
			mkdir /mnt/ignition && \
			cp config.ign /mnt/ignition/ && \
			reboot \
		' < "$<"

hetzner-clean:
	hcloud ssh-key delete "$(REMOTESERVER)" || true
	hcloud context delete "$(REMOTESERVER)" || true
	rm -f "$(REMOTEKEY)"

# Clean targets

.PHONY: clean
clean:
	rm -fr "$(BUILDDIR)"/*.ign "$(BUILDDIR)"/*.img "$(BUILDDIR)"/*.log

.PHONY: clean-all
clean-all: clean
	rm -fr "$(BUILDDIR)"