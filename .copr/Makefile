# Copr "SCM" build method entry point (build source type "make srpm").
# Copr clones the repo into a mock chroot and runs, as root, with network:
#   make -f .copr/Makefile srpm outdir="<outdir>" spec="<spec_path>"
# Same shape as vox-libs': archive HEAD, build the SRPM, done. The mock
# build of that SRPM then compiles vox-fuzz with the vox package from this
# same Copr project's buildroot. (The crates.io launcher's Rust is inert
# here — the RPM builds the real Vox binary via make.)

outdir ?= $(CURDIR)/outdir
builddir := $(shell mktemp -d)

.PHONY: srpm
srpm:
	dnf -y install --setopt=install_weak_deps=False rpm-build git

	mkdir -p "$(outdir)" "$(builddir)/SOURCES" "$(builddir)/SPECS"

	$(eval VERSION := $(shell sed -n 's/^version = "\(.*\)"/\1/p' Cargo.toml | head -1))

	git archive --prefix=vox-fuzz-$(VERSION)/ -o "$(builddir)/SOURCES/vox-fuzz-$(VERSION).tar.gz" HEAD

	cp vox-fuzz.spec "$(builddir)/SPECS/"

	rpmbuild -bs \
		--define "_topdir $(builddir)" \
		"$(builddir)/SPECS/vox-fuzz.spec"

	cp "$(builddir)"/SRPMS/*.src.rpm "$(outdir)/"
	rm -rf "$(builddir)"
