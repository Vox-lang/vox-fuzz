Name:           vox-fuzz
Version:        0.2.0
Release:        1%{?dist}
Summary:        A fuzzer for the Vox compiler, written in Vox

License:        GPL-3.0-or-later
URL:            https://github.com/Vox-lang/vox-fuzz
Source0:        %{url}/archive/v%{version}/vox-fuzz-%{version}.tar.gz

# Compiled BY vox, like vox-libs — the compiler is a build dependency and is
# published in this same Copr project, so it resolves in the buildroot.
BuildRequires:  make
BuildRequires:  vox
BuildRequires:  nasm
BuildRequires:  binutils

# Unlike vox-libs, the compiler is ALSO a runtime dependency: fuzzing means
# invoking vox (and through it nasm/ld) on every generated program.
Requires:       vox
Requires:       nasm
Requires:       binutils

# x86_64 only, same reasoning as vox-libs and proven the hard way there:
# vox emits x86_64 NASM and links with the native ld, so no other
# architecture can build or run this. Skips, not failures.
ExclusiveArch:  x86_64

# The binary is Vox-emitted assembly with no build-id note and no debug
# sections — find-debuginfo hard-fails on it ("No build ID note found",
# caught by a local rpmbuild before this ever reached Copr). Same
# situation and same cure as the sibling packages.
%global debug_package %{nil}

%description
A fuzzer for the Vox compiler — written in Vox. It generates random valid
Vox programs, compiles them with the real compiler, supervises the
binaries natively (fork, non-blocking reap, deadline kill, raw wait
status), and records every ICE, assembler rejection, crash, or hang as a
self-contained reproducible finding.

%prep
%autosetup -n vox-fuzz-%{version}

%build
make build VOX=vox

%check
# The suite refuses to run if VOX_CORE_PATH does not exist — pass the
# buildroot's installed runtime explicitly rather than letting test.sh
# derive a wrong path from the vox binary's location.
VOX=/usr/bin/vox VOX_CORE_PATH=/usr/share/vox/coreasm ./test.sh

%install
install -D -m 0755 build/vox-fuzz %{buildroot}%{_bindir}/vox-fuzz

%files
%license LICENSE
%doc README.md
%{_bindir}/vox-fuzz

%changelog
* Tue Aug 18 2026 Josjuar Lister <josj@tegosec.com> - 0.1.0-1
- Initial packaging: build via make with the Copr-provided vox, run the
  full test suite as the gate, ship the single static binary.
