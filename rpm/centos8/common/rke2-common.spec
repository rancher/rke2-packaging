%global ARCH.placeholder
%global __os_install_post %{nil}
%global require_kernel_extra 0
%if 0%{?rhel} >= 10
%global require_kernel_extra 1
%endif

Name:    rke2-common
Version: %{rpm_version}
Release: %{rpm_release}%{?dist}
Summary: RKE2 Common
Vendor:     SUSE LLC
Packager:   SUSE LLC <https://www.suse.com/>

Group:   System Environment/Base
License: ASL 2.0
URL:     https://rancher.com
Source0: https://github.com/rancher/rke2/releases/download/%{rke2_version}/rke2.linux-%{ARCH}.tar.gz
Source1: 80-rke2.rules

BuildRequires: systemd
Requires(post): rke2-selinux >= %{rke2_policyver}
Requires: iptables
%if %{require_kernel_extra}
Requires: kernel-modules-extra%{?_isa}
%endif

%description
The Next Generation Rancher Labs Distribution of Kubernetes

%prep
tar -xzf %SOURCE0 -C %{_builddir}
cp %SOURCE1 %{_builddir}

%install
install -m 755 -d %{buildroot}%{_bindir}
install -p -m 755 -t %{buildroot}%{_bindir}/ %{_builddir}/bin/rke2
install -d %{buildroot}%{_datadir}/rke2
install -p -m 644 -t %{buildroot}%{_datadir}/rke2/ %{_builddir}/share/rke2/LICENSE.txt
install -p -m 644 -t %{buildroot}%{_datadir}/rke2/ %{_builddir}/share/rke2/rke2-cis-sysctl.conf
install -d %{buildroot}%{_sysconfdir}/rancher/rke2
install -m 755 -d %{buildroot}%{_sharedstatedir}/rancher/rke2
install -m 755 -d %{buildroot}%{_localstatedir}/run/k3s
install -m 755 -t %{buildroot}%{_bindir}/ %{_builddir}/bin/rke2-killall.sh
install -m 755 -t %{buildroot}%{_bindir}/ %{_builddir}/bin/rke2-uninstall.sh
install -d -m 755 %{buildroot}%{_sysconfdir}/fapolicyd/rules.d
install -m 644 -t %{buildroot}%{_sysconfdir}/fapolicyd/rules.d/ %{_builddir}/80-rke2.rules

%files
%{_bindir}/rke2
%{_datadir}/rke2/LICENSE.txt
%{_datadir}/rke2/rke2-cis-sysctl.conf
%{_sysconfdir}/rancher/rke2/
%{_sharedstatedir}/rancher/rke2
%{_localstatedir}/run/k3s
%{_bindir}/rke2-killall.sh
%{_bindir}/rke2-uninstall.sh
%{_sysconfdir}/fapolicyd/rules.d/80-rke2.rules

%changelog
%include %{changelog_path}

%preun
if [ $1 -eq 0 ]; then
    INSTALL_RKE2_ROOT=%{_prefix} /usr/bin/rke2-killall.sh
fi
