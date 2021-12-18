#!/bin/bash
source lib/params.sh

mkdir -p build/rpm

echo "Name:       screen-sbs
Version:    ${version}
Release:    ${revision}
Summary:    screen-sbs
BuildArch:  noarch
License:    undefined
Requires:    bash, scrot, xclip, curl, xdg-utils, jq

%description
screen-sbs uploader

%prep

%build

%install
mkdir -p %{buildroot}/%{_prefix}/share/icons/
cp ../screen-sbs.png %{buildroot}/%{_prefix}/share/icons/screen-sbs.png
mkdir -p %{buildroot}/%{_bindir}
install -m 0755 ../screen.sh %{buildroot}/%{_bindir}/screen-sbs
sed -i "s/git_version/${version}-${revision}/g" %{buildroot}/%{_bindir}/screen-sbs

%files
%{_bindir}/screen-sbs
%{_prefix}/share/icons/screen-sbs.png

%changelog" \
> build/rpm/screen-sbs.spec

rpmbuild -ba --build-in-place --define "_topdir $(pwd)/build/rpm" build/rpm/screen-sbs.spec
