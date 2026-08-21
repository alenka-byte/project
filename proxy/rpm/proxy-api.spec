Name:           proxy-api
Version:        1.0.0
Release:        1%{?dist}
Summary:        Proxy API with Redis caching
License:        MIT
URL:            https://example.com
Source0:        proxy-api-%{version}.tar.gz
BuildRoot:      %{_tmppath}/%{name}-%{version}-%{release}-root
BuildArch:      noarch
Requires:       python3 python3-pip
Requires:       valkey

%description
Proxy API service with Redis caching for user data

%prep
%setup -q

%install
mkdir -p %{buildroot}%{_bindir}
mkdir -p %{buildroot}%{_sysconfdir}/proxy-api
mkdir -p %{buildroot}%{_unitdir}

install -m 755 proxy-api-1.0.0/cache-api.py %{buildroot}%{_bindir}/proxy-api
install -m 644 proxy-api-1.0.0/config-api.yaml %{buildroot}%{_sysconfdir}/proxy-api/
install -m 644 proxy-api-1.0.0/rpm/proxy-api.service %{buildroot}%{_unitdir}/

%clean
rm -rf %{buildroot}

%post
systemctl daemon-reload
systemctl enable proxy-api.service || :
systemctl start proxy-api.service || :

%preun
systemctl stop proxy-api.service || :
systemctl disable proxy-api.service || :

%files
%{_bindir}/proxy-api
%config(noreplace) %{_sysconfdir}/proxy-api/config-api.yaml
%{_unitdir}/proxy-api.service

%changelog
* Mon Aug 19 2024 Your Name <your.email@example.com> - 1.0.0-1
- Initial package
