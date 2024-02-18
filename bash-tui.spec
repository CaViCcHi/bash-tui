Name:           bash-tui
Version:        %{?rpm_version}
Release:        %{?rpm_release}
Summary:        Bash TUI project

License:        GPL
URL:            https://github.com/yourusername/bash-tui
Source0:        bash-tui-%{tar_version}.tar.gz

Requires:       bash

%description
Bash TUI project for improved shell interface.

%prep
%setup -q -n dir_root

%build
# Add build commands here (if any)

%install
mkdir -p %{buildroot}

cp -a * %{buildroot}/

%files
%defattr(-,root,root,-)
/etc/bash-tui-colors.conf
/etc/bash-tui.conf
/etc/profile.d/00_custom_colors.sh
/etc/profile.d/01_custom_vars.sh
/etc/profile.d/20_rosterlib.sh
/etc/profile.d/10_aliases.sh
/etc/profile.d/99_commandline.sh
/usr/bin/bash-tui/harper
/usr/bin/bash-tui/ldd2tar
/usr/bin/bash-tui/netspeed
/usr/lib/bash-tui/custom_functions.sh
/usr/lib/bash-tui/svnlocal.sh
/usr/lib/bash-tui/say.sh
/usr/lib/bash-tui/bashparms.sh

%changelog
* Sat Feb 17 19:23:58 PST 2024 Matteo Bignotti <gugoll@gmail.com> - 1.0
- First release of bash-tui RPM

