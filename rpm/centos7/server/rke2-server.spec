Name:    rke2-server
Version: %{rpm_version}
Release: %{rpm_release}%{?dist}
Summary: RKE2 Server

Group:   System Environment/Base		
License: ASL 2.0
URL:     https://rancher.com
Source0: rke2-server.service
Source1: rke2-server.env

BuildRequires: systemd
Requires(post): rke2-common = %{rpm_version}-%{rpm_release}%{?dist}

%description
The Next Generation Rancher Labs Distribution of Kubernetes

%prep
cp -p %SOURCE0 %{_builddir}/
cp -p %SOURCE1 %{_builddir}/

%install
cd %{_builddir}
install -m 755 -d %{buildroot}%{_unitdir}
install -m 755 -d %{buildroot}%{_sysconfdir}/sysconfig/
install -m 755 -d %{buildroot}%{_unitdir}/rke2-server.service.d/
install -p -m 644 -t %{buildroot}%{_unitdir}/ rke2-server.service
install -p -m 644 -T rke2-server.env %{buildroot}%{_sysconfdir}/sysconfig/rke2-server

%files
%{_unitdir}/rke2-server.service
%config(noreplace) %{_sysconfdir}/sysconfig/rke2-server

%post
%systemd_post rke2-server.service

%preun
%systemd_preun rke2-server.service

%postun
%systemd_postun_with_restart rke2-server.service

%changelog
