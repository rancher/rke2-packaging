%global ARCH.placeholder

Name:    rke2-server
Version: %{rpm_version}
Release: %{rpm_release}%{?dist}
Summary: RKE2 Server

Group:   System Environment/Base
License: ASL 2.0
URL:     https://rancher.com
Source0: https://github.com/rancher/rke2/releases/download/%{rke2_version}/rke2.linux-%{ARCH}.tar.gz
Source1: rke2-server.env

BuildRequires: systemd
Requires(post): rke2-common = %{rpm_version}-%{rpm_release}%{?dist}

%description
The Next Generation Rancher Labs Distribution of Kubernetes

%prep
tar -xzf %SOURCE0 -C %{_builddir}
sed -e s,/usr/local/bin,%{_bindir},g \
    -e s,/usr/local/lib/systemd/system,%{_unitdir},g \
    -i.old %{_builddir}/lib/systemd/system/rke2-server.service

%install
install -m 755 -d %{buildroot}%{_unitdir}
install -m 755 -d %{buildroot}%{_sysconfdir}/sysconfig/
install -m 755 -d %{buildroot}%{_unitdir}/rke2-server.service.d/
install -p -m 644 -t %{buildroot}%{_unitdir}/ %{_builddir}/lib/systemd/system/rke2-server.service
install -p -m 644 -T %SOURCE1 %{buildroot}%{_sysconfdir}/sysconfig/rke2-server

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
%include %{changelog_path}
