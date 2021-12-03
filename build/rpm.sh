#!/bin/bash
source lib/params.sh

mkdir rpm

echo "Name:       screen-sbs
Version:    ${version}
Release:    ${revision}
Summary:    screen-sbs
BuildArch:  noarch
License:    undefined
Requires:    scrot, xclip, curl

%description
screen-sbs uploader

%prep

%build

%install
mkdir -p %{buildroot}/%{_bindir}
install -m 0755 ../screen.sh %{buildroot}/%{_bindir}/screen-sbs

%files
%{_bindir}/screen-sbs

%changelog" \
> rpm/screen-sbs.spec

rpmbuild -ba --build-in-place --define "_topdir $(pwd)/rpm" rpm/screen-sbs.spec
