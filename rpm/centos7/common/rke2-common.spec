%global ARCH.placeholder

Name:    rke2-common
Version: %{rpm_version}
Release: %{rpm_release}%{?dist}
Summary: RKE2 Common

Group:   System Environment/Base
License: ASL 2.0
URL:     https://rancher.com
Source0: https://github.com/rancher/rke2/releases/download/%{rke2_version}/rke2.linux-%{ARCH}.tar.gz

BuildRequires: systemd
Requires(post): rke2-selinux >= %{rke2_policyver}
Requires: libseccomp >= 2.3
Requires: iptables

%description
The Next Generation Rancher Labs Distribution of Kubernetes

%prep
tar -xzf %SOURCE0 -C %{_builddir}

%install
install -m 755 -d %{buildroot}%{_bindir}
install -p -m 755 -t %{buildroot}%{_bindir}/ %{_builddir}/bin/rke2
install -d %{buildroot}%{_datadir}/rke2
install -p -m 644 -t %{buildroot}%{_datadir}/rke2/ %{_builddir}/share/rke2/LICENSE.txt
install -p -m 644 -t %{buildroot}%{_datadir}/rke2/ %{_builddir}/share/rke2/rke2-cis-sysctl.conf
install -d %{buildroot}%{_sysconfdir}/rancher/rke2
install -m 755 -d %{buildroot}%{_sharedstatedir}/rancher/rke2
install -m 755 -d %{buildroot}%{_localstatedir}/run/k3s

%files
%{_bindir}/rke2
%{_datadir}/rke2/LICENSE.txt
%{_datadir}/rke2/rke2-cis-sysctl.conf
%{_sysconfdir}/rancher/rke2/
%{_sharedstatedir}/rancher/rke2
%{_localstatedir}/run/k3s

%changelog
