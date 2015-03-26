#!/usr/bin/env bash

if [ $UID -ne 0 ]; then
	echo Non root user. Please run as root.
	exit 1;
fi

BLACK='\e[0;30m'
RED='\e[0;31m'
GREEN='\e[0;32m'
YELLOW='\e[0;33m'
BLUE='\e[0;34m'
MAGENTA='\e[0;35m'
CYAN='\e[0;36m'
WHITE='\e[0;37m'
END_COLOR='\e[0m'

# apt-repository array
REPOS=()
APTS=()

apt_add() {
	for p in $*;
	do
		APTS+=($p)
	done;
}

repo_add() {
	for p in $*;
	do
		REPOS+=($p)
	done;
}

# BASIC SETUP TOOLS
msg() {
	printf $MAGENTA'%b\n'$END_COLOR "$1" >&2
}

success() {
	echo -e "$GREEN[✔]$END_COLOR ${1}${2}"
}

error() {
	msg "$RED[✘]$END_COLOR ${1}${2}"
	exit 1
}

debug() {
	if [ "$debug_mode" -eq '1' ] && [ "$ret" -gt '1' ]; then
	  msg "An error occured in function \"${FUNCNAME[$i+1]}\" on line ${BASH_LINENO[$i+1]}, we're sorry for that."
	fi
}

program_exists() {
	local ret='0'
	type $1 >/dev/null 2>&1 || { local ret='1'; }

	# throw error on non-zero return value
	if [ ! "$ret" -eq '0' ]; then
	error "$2"
	fi
}

function_exists() {
	declare -f -F $1 > /dev/null
	return $?
}


repo_change() {
	# 기본 저장소를 다음으로 바꾸기. 빨라진다
	sed -i 's/us.archive.ubuntu.com/ftp.daum.net/' /etc/apt/sources.list
	sed -i 's/kr.archive.ubuntu.com/ftp.daum.net/' /etc/apt/sources.list
}


update() {
	msg "Ubuntu update start."
	apt-get update
	apt-get upgrade
	success "Update Complete"
}

run_all() {
	apt_add python-software-properties software-properties-common

	for p in ${REPOS[@]};
	do
		add-apt-repository -y $p
	done;

	update;

	for p in ${APTS[@]};
	do
		msg "$p Install.."
		apt-get install -y $p
	done;
	success "Complete"
}


openssh() {
	apt_add openssh-server
}

utillity() {
	# Utillity install
	apt_add cronolog vim ctags git subversion build-essential g++ curl libssl-dev sysv-rc-conf expect tmux htop rcconf mc iotop
}

# Redis install
redis() {
	apt_add redis-server
}

# Node.js install
nodejs() {
	msg "Node.js install start."
	apt-get install -y python-software-properties software-properties-common
	add-apt-repository -y  "ppa:chris-lea/node.js"
	apt-get update
	apt-get install -y nodejs
	npm install express jade stylus socket.io locally redis-commander -g
	success "Complate Node.js install"
}

# Java 8 install
java() {
	repo_add "ppa:webupd8team/java"
	apt_add oracle-java8-installer
}

# Nginx install
nginx() {
	repo_add "ppa:nginx/stable"
	apt_add nginx
}

# PHP-FPM install
phpfpm() {
	repo_add "ppa:l-mierzwa/lucid-php5"
	apt_add php5-fpm php5 php-apc php-pear php5-cli php5-common php5-curl php5-dev php5-fpm php5-gd php5-gmp php5-imap php5-ldap php5-mcrypt php5-memcache php5-memcached php5-mysql php5-odbc php5-pspell php5-recode php5-sqlite php5-sybase php5-tidy php5-xmlrpc php5-xsl php5-mongo php5-xmlrpc php5-json php5-imagick php5-redis
}

phpredis() {
	msg "phpredis install start"
	pecl install redis
	success "Install phpredis"
}

copyconf() {
	msg "Copy service conf"
	msg "Nginx"
	curl -L https://raw.github.com/gyuha/ubuntu_setting/master/conf/nginx > /tmp/nginx.conf
	cp -f /tmp/nginx.conf /etc/nginx/sites-available/default
	rm -f /tmp/nginx.conf
	service nginx restart
	msg "php-fpm"
	#curl -L https://raw.github.com/gyuha/ubuntu_setting/master/conf/php.dev.14.04.ini > /tmp/php.dev.ini
	curl -L https://raw.githubusercontent.com/gyuha/settings/master/conf/php.dev.14.04.ini > /tmp/php.dev.ini
	cp -f /tmp/php.dev.ini /etc/php5/fpm/php.ini
	rm -f /tmp/php.dev.ini
	service php5-fpm restart
	success "Copy complete"
}

# 시스템시 나오는 메시지..
motd() {
	msg "Dynamic MOTD"
	curl https://raw.github.com/gyuha/ubuntu_setting/master/conf/50-system-info > /tmp/50-system-info
	chmod +x /tmp/50-system-info
	cp -f /tmp/50-system-info /etc/update-motd.d/50-system-info
	rm -f /tmp/50-system-info
}

if [ $# -eq 0 ]; then
	msg "Select any packages.";
	exit;
fi

if [ $1 == "all" ]; then
	msg "Install all packages."
	#repo_change;
	motd;
	openssh;
	utillity;
	redis;
	nginx;
	phpfpm;
	run_all;
	nodejs;
	phpredis;
	exit;
fi

if [ $1 == "copyconf" ]; then
	copyconf;
	exit;
fi

RUN=false;
for (( i=1;$i<=$#;i=$i+1 ))
do
	function_exists ${!i} && eval ${!i} && RUN=true || msg "Can't find function..";
done
if $RUN eq true
then
	run_all;
fi
