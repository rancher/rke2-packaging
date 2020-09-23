%global ARCH.placeholder

Name:    rke2-common
Version: %{rpm_version}
Release: %{rpm_release}%{?dist}
Summary: RKE2 Common

Group:   System Environment/Base		
License: ASL 2.0
URL:     https://rancher.com
Source0: https://github.com/rancher/rke2/releases/download/%{rke2_version}/rke2.linux-%{ARCH}

BuildRequires: systemd
Requires(post): rke2-selinux >= %{rke2_policyver}
Requires: libseccomp >= 2.3
Requires: iptables

%description
The Next Generation Rancher Labs Distribution of Kubernetes

%prep
cp -p %SOURCE0 %{_builddir}/rke2

%install
cd %{_builddir}
install -m 755 -d %{buildroot}%{_bindir}
install -p -m 755 -t %{buildroot}%{_bindir}/ rke2
install -d %{buildroot}%{_sysconfdir}/rke2
install -m 755 -d %{buildroot}%{_sharedstatedir}/rancher/rke2
install -m 755 -d %{buildroot}%{_localstatedir}/run/k3s

%files
%{_bindir}/rke2
%{_sysconfdir}/rke2/
%{_sharedstatedir}/rancher/rke2
%{_localstatedir}/run/k3s

%changelog
