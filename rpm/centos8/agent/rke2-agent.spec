%global ARCH.placeholder

Name:    rke2-agent
Version: %{rpm_version}
Release: %{rpm_release}%{?dist}
Summary: RKE2 Agent

Group:   System Environment/Base
License: ASL 2.0
URL:     https://rancher.com
Source0: https://github.com/rancher/rke2/releases/download/%{rke2_version}/rke2.linux-%{ARCH}.tar.gz
Source1: rke2-agent.env

BuildRequires: systemd
Requires(post): rke2-common = %{rpm_version}-%{rpm_release}%{?dist}

%description
The Next Generation Rancher Labs Distribution of Kubernetes

%prep
tar -xzf %SOURCE0 -C %{_builddir}
sed -e s,/usr/local/bin,%{_bindir},g \
    -e s,/usr/local/lib/systemd/system,%{_unitdir},g \
    -i.old %{_builddir}/lib/systemd/system/rke2-agent.service

%install
install -m 755 -d %{buildroot}%{_unitdir}
install -m 755 -d %{buildroot}%{_sysconfdir}/sysconfig/
install -m 755 -d %{buildroot}%{_unitdir}/rke2-agent.service.d/
install -p -m 644 -t %{buildroot}%{_unitdir}/ %{_builddir}/lib/systemd/system/rke2-agent.service
install -p -m 644 -T %SOURCE1 %{buildroot}%{_sysconfdir}/sysconfig/rke2-agent

%files
%{_unitdir}/rke2-agent.service
%config(noreplace) %{_sysconfdir}/sysconfig/rke2-agent

%post
%systemd_post rke2-agent.service

%preun
%systemd_preun rke2-agent.service

%postun
%systemd_postun_with_restart rke2-agent.service

%changelog
%include %{changelog_path}
