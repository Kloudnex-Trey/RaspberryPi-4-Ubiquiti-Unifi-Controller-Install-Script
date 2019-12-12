#!/bin/bash

# UniFi Let's Encrypt script.
# Version  | 1.2.7
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
YELLOW='\033[1;33m'
GRAY='\033[0;37m'
WHITE='\033[1;37m'
GRAY_R='\033[39m'
WHITE_R='\033[39m'
RED='\033[1;31m' # Light Red.
GREEN='\033[1;32m' # Light Green.
BOLD='\e[1m'

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Start Checks                                                                                          #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Check for root (SUDO).
if [[ "$EUID" -ne 0 ]]; then
  clear
  clear
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
  echo -e "${WHITE_R}#${RESET} The script need to be run as root..."
  echo ""
  echo ""
  echo -e "${WHITE_R}#${RESET} For Ubuntu based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} sudo -i"
  echo ""
  echo -e "${WHITE_R}#${RESET} For Debian based systems run the command below to login as root"
  echo -e "${GREEN}#${RESET} su"
  echo ""
  echo ""
  exit 1
fi

while [ -n "$1" ]; do
  case "$1" in
  -install_script) install_script=true;;
  -v6) run_ipv6=true;;
  -dns) prefer_dns_challenge=true;;
  esac
  shift
done

abort() {
  echo ""
  echo ""
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
  echo -e "${WHITE_R}#${RESET} An error occurred. Aborting script..."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  echo ""
  echo ""
  exit 1
}

header() {
  clear
  echo -e "${GREEN}#########################################################################${RESET}"
  echo ""
}

header_red() {
  clear
  echo -e "${RED}#########################################################################${RESET}"
  echo ""
}

cancel_script() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} Cancelling the script!"
  echo ""
  echo ""
  exit 0
}

start_script() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} Starting the script!"
  echo -e "${WHITE_R}#${RESET} Thank you for using AmazedMender16's Easy Let's Encrypt Script!"
  echo ""
  sleep 2
}
start_script

# Get distro.
if [[ -z "$(command -v lsb_release)" ]]; then
  if [[ -f "/etc/os-release" ]]; then
    if [[ -n "$(grep VERSION_CODENAME /etc/os-release)" ]]; then
      os_codename=$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="' | tr A-Z a-z)
    elif [[ -z "$(grep VERSION_CODENAME /etc/os-release)" ]]; then
      os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr A-Z a-z)
      if [[ -z ${os_codename} ]]; then
        os_codename=$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print $3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g' | tr A-Z a-z)
      fi
    fi
  fi
else
  os_codename=$(lsb_release -cs | tr A-Z a-z)
  if [[ $os_codename == 'n/a' ]]; then
    os_codename=$(lsb_release -is | tr A-Z a-z)
    if [[ $os_codename == 'parrot' ]]; then
      os_codename='buster'
    fi
  fi
fi

if [[ $(echo $PATH | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  PATH=$PATH:/usr/sbin
fi

if ! [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|cosmic|disco|eoan|jessie|stretch|continuum|buster|bullseye) ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} This script is not made for your OS.."
  echo -e "${WHITE_R}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums if you believe this is an error."
  echo -e ""
  echo -e "OS_CODENAME = ${os_codename}"
  echo -e ""
  echo -e ""
  exit 1
fi

script_online_version_dots=$(curl https://get.glennr.nl/unifi/extra/unifi-lets-encrypt.sh -s | grep "# Version" | head -n 1 | awk '{print $4}')
script_local_version_dots=$(grep "# Version" $0 | head -n 1 | awk '{print $4}')
script_online_version=$(echo "${script_online_version_dots}" | sed 's/\.//g')
script_local_version=$(echo "${script_local_version_dots}" | sed 's/\.//g')

# Script version check.
if [[ ${script_online_version::3} -gt ${script_local_version::3} ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
  echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy Let's Encrypt Script.."
  echo ""
  echo ""
  sleep 3
  rm -rf $0 2> /dev/null
  rm -rf unifi-lets-encrypt.sh 2> /dev/null
  wget https://get.glennr.nl/unifi/extra/unifi-lets-encrypt.sh; chmod +x unifi-lets-encrypt.sh; sudo ./unifi-lets-encrypt.sh; exit 0
fi

required_service=no
if [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
  required_service=yes
fi
if [[ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
  required_service=yes
fi
if [[ $(dpkg-query -W -f='${Status}' unifi-talk 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
  required_service=yes
fi
if [[ $(dpkg-query -W -f='${Status}' unifi-led 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
  required_service=yes
fi
if [[ $(dpkg-query -W -f='${Status}' uas-led 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
  required_service=yes
fi
if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then
  required_service=yes
fi
if dpkg -l | grep -iq "\bUAS\b\|UniFi Application Server"; then
  required_service=yes
fi
if dpkg -l | grep -iq 'docker'; then
  if docker container ls | grep -iq 'ubnt/eot'; then
    required_service=yes
  fi
fi
if [[ ${required_service} == 'no' ]]; then
  echo -e "${RED}#${RESET} Please install one of the following controllers first, then retry this script again!"
  echo -e "${RED}-${RESET} UniFi Network Controller ( SDN )"
  echo -e "${RED}-${RESET} UniFi Video NVR"
  echo -e "${RED}-${RESET} UniFi LED Controller"
  echo ""
  echo ""
  exit 1
fi

# Check if UniFi is already installed.
unifi_status=$(service unifi status | grep -i 'Active:' | awk '{print $2}')
if [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
  if [[ ${unifi_status} == 'inactive' ]]; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} UniFi is not active ( running ), starting the controller now."
    service unifi start
    unifi_status=$(service unifi status | grep -i 'Active:' | awk '{print $2}')
    if [[ ${unifi_status} == 'active' ]]; then
      echo -e "${GREEN}#${RESET} Successfully started the UniFi Network Controller!"
      sleep 2
    else
      echo -e "${RED}#${RESET} Failed to start the UniFi Network Controller!"
      echo -e "${RED}#${RESET} Please check the logs in '/usr/lib/unifi/logs/'"
      sleep 2
    fi
  fi
fi

if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then
  eus_dir='/srv/EUS'
else
  eus_dir='/usr/lib/EUS'
fi

mkdir -p ${eus_dir}/logs

if [[ ${run_ipv6} == 'true' ]]; then
  dig_option='AAAA'
  curl_option='-6'
else
  dig_option='A'
  curl_option='-4'
fi

certbot_auto_permission_check() {
  if [[ -f "${eus_dir}/certbot-auto" || -s "${eus_dir}/certbot-auto" ]]; then
    if [[ $(stat -c "%a" "${eus_dir}/certbot-auto") != "755" ]]; then
      chmod 0755 ${eus_dir}/certbot-auto
    fi
    if [[ $(stat -c "%U" "${eus_dir}/certbot-auto") != "root" ]] ; then
      chown root ${eus_dir}/certbot-auto
    fi
  fi
}

download_certbot_auto() {
  curl -s https://dl.eff.org/certbot-auto -o ${eus_dir}/certbot-auto
  chown root ${eus_dir}/certbot-auto
  chmod 0755 ${eus_dir}/certbot-auto
  downloaded_certbot=true
  certbot_auto_permission_check
  if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then abort; fi
}

remove_certbot() {
  if [[ $(dpkg-query -W -f='${Status}' certbot 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
    apt-get remove certbot -y
    apt-get autoremove -y
    apt-get autoclean -y
  fi
}

if [[ $os_codename == "jessie" ]]; then
  clear
  header_red
  echo -e "${RED}#${RESET} Your certbot version is to old, we will switch to certbot-auto..\n\n"
  remove_certbot
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

certbot_repositories() {
  if [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/certbot/certbot/ubuntu xenial main") -eq 0 ]]; then
      echo deb http://ppa.launchpad.net/certbot/certbot/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/certbot/certbot/ubuntu bionic main") -eq 0 ]]; then
      echo deb http://ppa.launchpad.net/certbot/certbot/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  elif [[ $os_codename == "cosmic" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/certbot/certbot/ubuntu cosmic main") -eq 0 ]]; then
      echo deb http://ppa.launchpad.net/certbot/certbot/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
#  elif [[ $os_codename == "disco" ]]; then
  elif [[ $os_codename =~ (disco|eoan) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/certbot/certbot/ubuntu disco main") -eq 0 ]]; then
      echo deb http://ppa.launchpad.net/certbot/certbot/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
#  elif [[ $os_codename == "eoan" ]]; then
#    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ppa.launchpad.net/certbot/certbot/ubuntu eoan main") -eq 0 ]]; then
#      echo deb http://ppa.launchpad.net/certbot/certbot/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
#      certbot_repository_add_key=true
#    fi
  elif [[ $os_codename =~ (stretch|continuum) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  elif [[ $os_codename == "buster" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  elif [[ $os_codename == "bullseye" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      certbot_repository_add_key=true
    fi
  fi
  if [[ ${certbot_repository_add_key} == 'true' ]]; then
    if [ ! -z "$http_proxy" ]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys 8C47BE8E75BCA694
    elif [ -f /etc/apt/apt.conf ]; then
      apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
      if [[ apt_http_proxy ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 8C47BE8E75BCA694
      fi
    else
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8C47BE8E75BCA694
    fi
  fi
  apt-get update
  apt-get install certbot -y || abort
}

check_certbot_version() {
  certbot_version=$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\b" | awk '{print $2}' | cut -d'.' -f2)
  if [[ ${certbot_version} -lt '27' ]]; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} Making sure your certbot version is on the latest release.\n\n"
    certbot_repositories
    certbot_version=$(dpkg -l | grep ^"ii" | awk '{print $2,$3}' | grep "^certbot\b" | awk '{print $2}' | cut -d'.' -f2)
    if [[ ${certbot_version} -lt '27' ]]; then
      clear
      header_red
      echo -e "${RED}#${RESET} Your certbot version is to old, we will switch to certbot-auto..\n\n"
      remove_certbot
      download_certbot_auto
    fi
  fi
}

install_required_packages() {
  sleep 2
  installing_required_package=yes
  clear
  header
  echo -e "${WHITE_R}#${RESET} Installing required packages.."
  echo ""
  echo ""
  sleep 2
}

if [[ $os_codename == "jessie" ]]; then
  if [[ $os_codename == "jessie" ]]; then
    if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then download_certbot_auto; fi
    if [[ ! -f "${eus_dir}/certbot-auto" || ! -s "${eus_dir}/certbot-auto" ]]; then abort; fi
  fi
else
  if [[ $(dpkg-query -W -f='${Status}' certbot 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
    if [[ ${installing_required_package} != 'yes' ]]; then
      install_required_packages
      apt-get update
    fi
    apt-get install certbot -y
    if [[ $? > 0 ]]; then
      certbot_repositories
    fi
    check_certbot_version
  else
    check_certbot_version
  fi
fi
if [[ $(dpkg-query -W -f='${Status}' dnsutils 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
  if [[ ${installing_required_package} != 'yes' ]]; then
    install_required_packages
    apt-get update
  fi
  apt-get install dnsutils -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "eoan" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "bullseye" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install dnsutils -y || abort
  fi
fi

if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  if [[ ${installing_required_package} != 'yes' ]]; then
    install_required_packages
    apt-get update
  fi
  apt-get install curl -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu trusty-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "eoan" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.debian.org/debian-security jessie/updates main") -eq 0 ]]; then
        echo deb http://security.debian.org/debian-security jessie/updates main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "bullseye" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install curl -y || abort
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

certbot_auto_install_run() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} Running script in certbot-auto mode, installing more required packages..."
  echo -e "${WHITE_R}#${RESET} This may take a while, depending on the device."
  echo -e "${WHITE_R}#${RESET} certbot-auto verbose log is saved here: ${eus_dir}/logs/certbot_auto_install.log"
  echo ""
  echo ""
  sleep 2
  if [[ $os_codename =~ (jessie) ]]; then
    echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list
    apt-get update -o Acquire::Check-Valid-Until=false
    apt-get install -t jessie-backports libssl-dev -y || abort
    sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
  fi
  certbot_auto_permission_check
  ${eus_dir}/certbot-auto --non-interactive --install-only --verbose 2>>${eus_dir}/logs/certbot_auto_install.log || abort
  if [[ -f ${eus_dir}/logs/certbot_auto_install.log ]]; then
    certbot_auto_install_log_size=$(du -sc ${eus_dir}/logs/certbot_auto_install.log | grep total$ | awk '{print $1}')
    if [[ ${certbot_auto_install_log_size} -gt '50' ]]; then
      tail -n100 ${eus_dir}/logs/certbot_auto_install.log &> ${eus_dir}/logs/certbot_auto_install_tmp.log
      cp ${eus_dir}/logs/certbot_auto_install_tmp.log ${eus_dir}/logs/certbot_auto_install.log && rm -rf ${eus_dir}/logs/certbot_auto_install_tmp.log
    fi
  fi
}

if [[ $os_codename =~ (jessie) || ${downloaded_certbot} == 'true' ]]; then
  certbot="${eus_dir}/certbot-auto"
  certbot_auto=true
else
  certbot="certbot"
fi

manual_fqdn='no'
run_uck_scripts='no'
renewal_option="--keep-until-expiring"
external_dns_server=''

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Script                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

delete_certs_question() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} What would you like to do with the old certificates?"
  echo ""
  echo ""
  echo -e " [   ${WHITE_R}1${RESET}   ]  |  Keep last 3 certificates. ( default )"
  echo -e " [   ${WHITE_R}2${RESET}   ]  |  Keep all certificates."
  echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cancel script."
  echo ""
  echo ""
  read -p $'Your choice | \033[39m' choice
  case "$choice" in
     1|"") old_certificates=last_three;;
     2) ;;
     3) cancel_script;;
	 *) 
        clear
        header_red
        echo -e "${WHITE_R}#${RESET} '${choice}' is not a valid option..." && sleep 2
        delete_certs_question;;
  esac
}

time_date=$(date +%Y%m%d_%H%M)

timezone() {
  if ! [[ -f ${eus_dir}/timezone_correct ]]; then
    if [[ -f /etc/timezone && -s /etc/timezone ]]; then
      time_zone=$(cat /etc/timezone | awk '{print $1}')
    else
      time_zone=$(timedatectl | grep -i "time zone" | awk '{print $3}')
    fi
    clear
    header
    echo -e "${WHITE_R}#${RESET} Your timezone is set to '${time_zone}'."
    echo ""
    read -p $'\033[39m#\033[0m Is your timezone correct? (Y/n) ' yes_no
    case "${yes_no}" in
       [Yy]*|"") touch ${eus_dir}/timezone_correct;;
       [Nn]*|*)
          clear
          header
          echo -e "${WHITE_R}#${RESET} Let's change your timezone!" && sleep 3; mkdir -p /tmp/EUS/
          dpkg-reconfigure tzdata && clear
          if [[ -f /etc/timezone && -s /etc/timezone ]]; then
            time_zone=$(cat /etc/timezone | awk '{print $1}')
          else
            time_zone=$(timedatectl | grep -i "time zone" | awk '{print $3}')
          fi
          rm -rf /tmp/EUS/timezone 2> /dev/null
          clear
          header
          read -p $'\033[39m#\033[0m Your timezone is now set to "'${time_zone}'", is that correct? (Y/n) ' yes_no
          case "${yes_no}" in
             [Yy]*|"") touch ${eus_dir}/timezone_correct;;
             [Nn]*|*) timezone;;
          esac;;
    esac
  fi
}

domain_name() {
  if [[ ${manual_fqdn} == 'no' ]]; then
    if [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
      server_fqdn=$(mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" | grep '"hostname"' | awk '{print $3}' | sed 's/[",]//g')
    else
      if [[ -f ${eus_dir}/server_fqdn ]]; then
        server_fqdn=$(cat ${eus_dir}/server_fqdn | head -n1)
      else
        server_fqdn='unifi.yourdomain.com'
      fi
      no_unifi=yes
    fi
    current_server_fqdn="$server_fqdn"
  fi
  clear
  header
  echo -e "${WHITE_R}#${RESET} Your FQDN is set to '${server_fqdn}'"
  echo ""
  read -p $'\033[39m#\033[0m Is the domain name/FQDN above correct? (Y/n) ' yes_no
  case "${yes_no}" in
     [Yy]*|"") le_resolve;;
     [Nn]*|*) le_manual_fqdn;;
  esac
}

le_resolve() {
  clear
  header
  server_fqdn=$(echo ${server_fqdn} | tr A-Z a-z)
  echo -e "${WHITE_R}#${RESET} Trying to resolve '${server_fqdn}'"
  if [[ ${manual_server_ip} == 'true' ]]; then
    server_ip=$(cat ${eus_dir}/server_ip | head -n1)
  else
    server_ip=$(curl -s ${curl_option} https://ip.glennr.nl/)
  fi
  domain_record=$(dig +short ${dig_option} ${server_fqdn} ${external_dns_server} &>> ${eus_dir}/domain_records)
  if grep -xq ${server_ip} ${eus_dir}/domain_records; then
    domain_record=${server_ip}
  fi
  rm -rf ${eus_dir}/domain_records 2> /dev/null
  sleep 3
  if [[ ${server_ip} != ${domain_record} ]]; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} '${server_fqdn}' does not resolve to '${server_ip}'"
    echo -e "${WHITE_R}#${RESET} Please make an A record pointing to your server's ip."
    echo -e "${WHITE_R}#${RESET} If you are using Cloudflare, please disable the orange cloud."
    echo ""
    echo -e "${GREEN}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} Please take an option below."
    echo ""
    echo -e " [   ${WHITE_R}1${RESET}   ]  |  Try to resolve your FQDN again. ( default )"
    echo -e " [   ${WHITE_R}2${RESET}   ]  |  Resolve with a external DNS server."
    if [[ ${manual_server_ip} == 'true' ]]; then
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Manually set the server IP. ( for users with multiple IP addresses )"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Automatically get server IP."
      echo -e " [   ${WHITE_R}5${RESET}   ]  |  Cancel Script."
    else
      echo -e " [   ${WHITE_R}3${RESET}   ]  |  Manually set the server IP. ( for users with multiple IP addresses )"
      echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cancel Script."
    fi
    echo ""
    echo ""
    echo ""
    read -p $'Your choice | \033[39m' le_resolve_question
    case "${le_resolve_question}" in
       1*|"") le_manual_fqdn;;
       2*) 
          clear
          header
          echo -e "${WHITE_R}#${RESET} What external DNS server would you like to use?"
          echo ""
          if [[ ${run_ipv6} == 'true' ]]; then
            echo -e " [   ${WHITE_R}1${RESET}   ]  |  Google DNS      ( 2001:4860:4860::8888 )"
            echo -e " [   ${WHITE_R}2${RESET}   ]  |  Google DNS      ( 2001:4860:4860::8844 )"
            echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cloudflare DNS  ( 2606:4700:4700::1111 )"
            echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cloudflare DNS  ( 2606:4700:4700::1001 )"
            echo -e " [   ${WHITE_R}5${RESET}   ]  |  GlennR DNS      ( 2001:41d0:701:1100::f0 )"
          else
            echo -e " [   ${WHITE_R}1${RESET}   ]  |  Google DNS      ( 8.8.8.8 )"
            echo -e " [   ${WHITE_R}2${RESET}   ]  |  Google DNS      ( 8.8.4.4 )"
            echo -e " [   ${WHITE_R}3${RESET}   ]  |  Cloudflare DNS  ( 1.1.1.1 )"
            echo -e " [   ${WHITE_R}4${RESET}   ]  |  Cloudflare DNS  ( 1.0.0.1 )"
            echo -e " [   ${WHITE_R}5${RESET}   ]  |  GlennR DNS      ( 54.37.72.75 )"
          fi
          echo -e " [   ${WHITE_R}6${RESET}   ]  |  Don't use external DNS servers."
          echo -e " [   ${WHITE_R}7${RESET}   ]  |  Cancel script"
          echo ""
          echo ""
          echo ""
          read -p $'Your choice | \033[39m' le_resolve_question
          case "${le_resolve_question}" in
             1*|"") if [[ ${run_ipv6} == 'true' ]]; then external_dns_server='@2001:4860:4860::8888' && le_resolve; else external_dns_server='@8.8.8.8' && le_resolve; fi;;
             2*) if [[ ${run_ipv6} == 'true' ]]; then external_dns_server='@2001:4860:4860::8844' && le_resolve; else external_dns_server='@8.8.4.4' && le_resolve; fi;;
             3*) if [[ ${run_ipv6} == 'true' ]]; then external_dns_server='@2606:4700:4700::1111' && le_resolve; else external_dns_server='@1.1.1.1' && le_resolve; fi;;
             4*) if [[ ${run_ipv6} == 'true' ]]; then external_dns_server='@2606:4700:4700::1001' && le_resolve; else external_dns_server='@1.0.0.1' && le_resolve; fi;;
             5*) if [[ ${run_ipv6} == 'true' ]]; then external_dns_server='@2001:41d0:701:1100::f0' && le_resolve; else external_dns_server='@54.37.72.75' && le_resolve; fi;;
             6*) le_resolve;;
             7*) cancel_script;;
             *) unknwon_option;;
          esac;;
       3*|"") le_manual_server_ip;;
       4*) if [[ ${manual_server_ip} == 'true' ]]; then rm -rf ${eus_dir}/server_fqdn; manual_server_ip=false; le_resolve; else cancel_script; fi;;
       5*) if [[ ${manual_server_ip} == 'true' ]]; then cancel_script; else unknwon_option; fi;;
       *) unknwon_option;;
    esac
  else
    echo -e "${WHITE_R}#${RESET} '${server_fqdn}' resolved correctly!"
    le_resolve_success=true
    if [[ ${install_script} == 'true' ]]; then echo "${server_fqdn}" &> ${eus_dir}/server_fqdn_install; fi
    sleep 3
    if [[ ${manual_fqdn} == 'true' && ${run_ipv6} != 'true' ]] && [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
      clear
      header
      echo -e "${WHITE_R}#${RESET} Your current controller FQDN is set to '${current_server_fqdn}' in the settings.."
      echo -e "${WHITE_R}#${RESET} Would you like to change it to '${server_fqdn}'?"
      echo ""
      echo ""
      read -p $'\033[39m#\033[0m Would you like to apply the change? (Y/n) ' yes_no
      case "$yes_no" in
         [Yy]*|"")
            if ! mongo --quiet --port 27117 ace --eval "db.getCollection('setting').find({}).forEach(printjson);" | grep -iq "override_inform_host.* true"; then
              if mongo --quiet --port 27117 ace --eval 'db.setting.update({"hostname":"'${current_server_fqdn}'"}, {$set: {"hostname":"'${server_fqdn}'"}})' | grep -iq '"nModified".*:.*1'; then
                clear
                header
                echo -e "${GREEN}#${RESET} Successfully changed the Controller Hostname to '${server_fqdn}'"
                sleep 3
              fi
            fi;;
         [Nn]*) ;;
      esac
    fi
  fi
}

unknwon_option() {
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} '${le_resolve_question}' is not a valid option..." && sleep 2
  le_resolve
}

le_manual_server_ip() {
  manual_server_ip=true
  clear
  header
  echo -e "${WHITE_R}#${RESET} Please enter your Server/WAN IP below."
  read -p $'\033[39m#\033[0m ' server_ip
  if [[ -f ${eus_dir}/server_ip ]]; then rm -rf ${eus_dir}/server_ip &> /dev/null; fi
  echo $server_ip >> ${eus_dir}/server_ip
  le_resolve
}

le_manual_fqdn() {
  manual_fqdn=true
  clear
  header
  echo -e "${WHITE_R}#${RESET} Please enter the FQDN of your controller below."
  read -p $'\033[39m#\033[0m ' server_fqdn
  if [[ ${no_unifi} == 'yes' ]]; then
    if [[ -f ${eus_dir}/server_fqdn ]]; then rm -rf ${eus_dir}/server_fqdn &> /dev/null; fi
    echo $server_fqdn >> ${eus_dir}/server_fqdn
  fi
  le_resolve
}

le_email() {
  clear
  header
  read -p $'\033[39m#\033[0m Do you want to setup a email address for renewal notifications? (Y/n) ' yes_no
  case "$yes_no" in
     [Yy]*|"")
        clear
        header
        echo -e "${WHITE_R}#${RESET} Please enter the email address below."
        read -p $'\033[39m#\033[0m ' le_user_mail
        email="--email ${le_user_mail}";;
     [Nn]*|*)
        email="--register-unsafely-without-email";;
  esac
}

le_pre_hook() {
  if ! [[ -d /etc/letsencrypt/renewal-hooks/pre/ ]]; then
    mkdir -p /etc/letsencrypt/renewal-hooks/pre/
  fi
  tee /etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh &>/dev/null <<EOF
#!/bin/bash
rm -rf ${eus_dir}/le_http_service 2> /dev/null
if [[ \${log_date} != 'true' ]]; then
  echo -e "\n------- \$(date +%F-%R) -------\n" &>> ${eus_dir}/logs/http_service.log
  log_date=true
fi
netstat -tulpn | grep ":80 " | awk '{print \$7}' | sed 's/[0-9]*\///' | sed 's/://' &>> ${eus_dir}/le_http_service_temp
awk '!a[\$0]++' ${eus_dir}/le_http_service_temp >> ${eus_dir}/le_http_service && rm -rf ${eus_dir}/le_http_service_temp
le_http_service=\$(tr '\r\n' ' ' < ${eus_dir}/le_http_service)
for service in \${le_http_service[@]}; do
  echo " '\${service}' is running on port 80." &>> ${eus_dir}/logs/http_service.log
  service \${service} stop 2> /dev/null && echo " Successfully stopped '\${service}'." &>> ${eus_dir}/logs/http_service.log
  echo "\${service}" &>> ${eus_dir}/le_stopped_http_service
done;
if dpkg -l | grep -iq '\bUAS\b\|UniFi Application Server'; then
  service uas stop
  echo "uas" &>> ${eus_dir}/le_stopped_http_service
fi
rm -rf ${eus_dir}/le_http_service 2> /dev/null
if dpkg -l ufw | grep -q "^ii"; then
  if ufw status verbose | awk '/^Status:/{print \$2}' | grep -xq "active"; then
    if ! ufw status verbose | grep "^80\b\|^80/tcp\b" | grep -iq "ALLOW IN"; then
      ufw allow 80 &> /dev/null && echo -e " Port 80 is now set to 'ALLOW IN'." &>> ${eus_dir}/logs/http_service.log
      touch ${eus_dir}/ufw_add_http
    fi
  fi
fi
EOF
  chmod +x /etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh
}

le_post_hook() {
  if ! [[ -d /etc/letsencrypt/renewal-hooks/post/ ]]; then
    mkdir -p /etc/letsencrypt/renewal-hooks/post/
  fi
  tee /etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh &>/dev/null <<EOF
#!/bin/bash
old_certificates="${old_certificates}"
if [[ -f ${eus_dir}/le_stopped_http_service ]]; then
  mv ${eus_dir}/le_stopped_http_service ${eus_dir}/le_stopped_http_service_temp
  awk '!a[\$0]++' ${eus_dir}/le_stopped_http_service_temp >> ${eus_dir}/le_stopped_http_service && rm -rf ${eus_dir}/le_stopped_http_service_temp
  le_http_service=\$(tr '\r\n' ' ' < ${eus_dir}/le_stopped_http_service)
  for service in \${le_http_service[@]}; do
    service \${service} start 2> /dev/null
  done;
  rm -rf ${eus_dir}/le_stopped_http_service* 2> /dev/null
fi
if [[ -f ${eus_dir}/ufw_add_http ]]; then
  ufw delete allow 80 &> /dev/null
  rm -rf ${eus_dir}/ufw_add_http 2> /dev/null
fi
server_fqdn="${server_fqdn}"
if ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log &>/dev/null; then
  last_le_log=\$(ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log | tail -n1)
  le_var=\$(cat \${last_le_log} | grep -i "/etc/letsencrypt/live/${server_fqdn}" | awk '{print \$1}' | head -n1 | sed 's/\/etc\/letsencrypt\/live\///g' | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
fi
if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem && -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
  if ! md5sum -c /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem.md5 &>${eus_dir}/logs/lets_encrypt_import_\$(date +%Y%m%d).log; then
    echo -e "\n------- \$(date +%F-%R) -------\n" &>> ${eus_dir}/logs/lets_encrypt_import_\$(date +%Y%m%d).log
    md5sum /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem >/etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem.md5 &>> ${eus_dir}/logs/lets_encrypt_import_\$(date +%Y%m%d).log
    if [[ \$(dpkg-query -W -f='\${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      mkdir -p ${eus_dir}/network/keystore_backups && cp /usr/lib/unifi/data/keystore ${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)
      openssl pkcs12 -export -inkey /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem -in /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem -out /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12 -name unifi -password pass:aircontrolenterprise &>> ${eus_dir}/logs/lets_encrypt_import_\$(date +%Y%m%d).log
      keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> ${eus_dir}/logs/lets_encrypt_import_\$(date +%Y%m%d).log
      keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12 -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> ${eus_dir}/logs/lets_encrypt_import_\$(date +%Y%m%d).log
      service unifi restart
    fi
    if [[ -f ${eus_dir}/cloudkey/cloudkey_management_ui ]]; then
      mkdir -p ${eus_dir}/cloudkey/certs_backups
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.key_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cp /etc/ssl/private/cloudkey.crt ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)
      cp /etc/ssl/private/cloudkey.key ${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem /etc/ssl/private/cloudkey.key
      fi
      service nginx restart
      if [[ \$(dpkg-query -W -f='\${Status}' unifi-protect 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
        unifi_protect_status=\$(service unifi-protect status | grep -i 'Active:' | awk '{print \$2}')
        if [[ \${unifi_protect_status} == 'active' ]]; then
          service unifi-protect restart
        fi
      fi
    fi
    if [[ -f ${eus_dir}/cloudkey/uas_management_ui ]]; then
      mkdir -p ${eus_dir}/uas/certs_backups/
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/uas/certs_backups/uas.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/uas/certs_backups/uas.key_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cp /etc/uas/uas.crt ${eus_dir}/uas/certs_backups/uas.crt_\$(date +%Y%m%d_%H%M)
      cp /etc/uas/uas.key ${eus_dir}/uas/certs_backups/uas.key_\$(date +%Y%m%d_%H%M)
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem /etc/uas/uas.crt
      fi
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem /etc/uas/uas.key
      fi
      service uas restart
    fi
    if [[ -f ${eus_dir}/cloudkey/cloudkey_unifi_led ]]; then
      service unifi-led restart
    fi
    if [[ -f ${eus_dir}/cloudkey/cloudkey_unifi_talk ]]; then
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/talk/certs_backups/server.pem_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      mkdir -p ${eus_dir}/talk/certs_backups && cp /usr/share/unifi-talk/app/certs/server.pem ${eus_dir}/talk/certs_backups/server.pem_\$(date +%Y%m%d_%H%M)
      cat /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem > /usr/share/unifi-talk/app/certs/server.pem
      service unifi-talk restart
    fi
    if [[ -f ${eus_dir}/eot/uas_unifi_led ]]; then
      mkdir -p ${eus_dir}/eot/certs_backups
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/eot/certs_backups/server.pem_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      cat /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem > ${eus_dir}/eot/eot_docker_container.pem
      eot_container=\$(docker container ls | grep -i 'ubnt/eot' | awk '{print \$1}')
      eot_container_name=ueot
      if [[ -n "\${eot_container}" ]]; then
        docker cp \${eot_container}:/app/certs/server.pem ${eus_dir}/eot/certs_backups/server.pem_\$(date +%Y%m%d_%H%M)
        docker cp ${eus_dir}/eot/eot_docker_container.pem \${eot_container}:/app/certs/server.pem
        docker restart \${eot_container_name}
      fi
    fi
    if [[ -f ${eus_dir}/video/unifi_video ]]; then
      mkdir -p /usr/lib/unifi-video/data/certificates
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/video/keystore_backups/keystore_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/video/keystore_backups/ufv-truststore_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
      openssl pkcs8 -topk8 -nocrypt -in /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem -outform DER -out /usr/lib/unifi-video/data/certificates/ufv-server.key.der
      openssl x509 -outform der -in /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem -out /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
      chown -R unifi-video:unifi-video /var/lib/unifi-video/certificates
      service unifi-video stop
      mkdir -p ${eus_dir}/video/keystore_backups
      mv /usr/lib/unifi-video/data/keystore ${eus_dir}/video/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)
      mv /usr/lib/unifi-video/data/ufv-truststore ${eus_dir}/video/keystore_backups/ufv-truststore_\$(date +%Y%m%d_%H%M)
      if ! cat /usr/lib/unifi-video/data/system.properties | grep "^ufv.custom.certs.enable=true"; then
        echo "ufv.custom.certs.enable=true" >> /usr/lib/unifi-video/data/system.properties
      fi
      service unifi-video start
    fi
  fi
fi
EOF
  chmod +x /etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh
}

le_import_failed() {
  if [[ ${prefer_dns_challenge} == 'true' ]]; then
    clear
    header_red
  fi
  echo -e "${RED}#${RESET} Failed to imported SSL certificate for '${server_fqdn}'"
  echo -e "${RED}#${RESET} Cleaning up files and restarting the controller service...\n"
  echo -e "${RED}#${RESET} Feel free to reach out to GlennR ( AmazedMender16 ) on the Ubiquiti Community Forums"
  echo -e "${RED}#${RESET} Log file is saved here: ${eus_dir}/logs/lets_encrypt_${time_date}.log"
  if [[ -f ${eus_dir}/logs/lets_encrypt_${time_date}.log ]]; then
    if cat ${eus_dir}/logs/lets_encrypt_${time_date}.log | grep -iq 'timeout during connect'; then
      script_timeout_http=true
      echo ""
      echo -e "${RED}---${RESET}"
      echo ""
      echo -e "${RED}#${RESET} Timed out..."
      echo -e "${RED}#${RESET} Your Firewall or ISP does not allow port 80, please verify that your Firewall/Port Fordwarding settings are correct."
      echo ""
      echo -e "${RED}---${RESET}"
    fi
    if cat ${eus_dir}/logs/lets_encrypt_${time_date}.log | grep -iq 'timeout after connect'; then
      script_timeout_http=true
      echo ""
      echo -e "${RED}---${RESET}"
      echo ""
      echo -e "${RED}#${RESET} Timed out... Your server may be slow or overloaded"
      echo -e "${RED}#${RESET} Please try to run the script again and make sure there is no firewall blocking port 80."
      echo ""
      echo -e "${RED}---${RESET}"
    fi
    if cat ${eus_dir}/logs/lets_encrypt_${time_date}.log | grep -iq 'too many certificates already issued for exact set of domains'; then
      echo ""
      echo -e "${RED}---${RESET}"
      echo ""
      echo -e "${RED}#${RESET} There were too many certificates issued for ${server_fqdn}"
      echo ""
      echo -e "${RED}---${RESET}"
    fi
    if cat ${eus_dir}/logs/lets_encrypt_${time_date}.log | grep -iq 'Problem binding to port 80'; then
      echo ""
      echo -e "${RED}---${RESET}"
      echo ""
      echo -e "${RED}#${RESET} Script failed to stop the service running on port 80, please manually stop it and run the script again!"
      echo ""
      echo -e "${RED}---${RESET}"
    fi
    if cat ${eus_dir}/logs/lets_encrypt_${time_date}.log | grep -iq 'Incorrect TXT record'; then
      echo ""
      echo -e "${RED}---${RESET}"
      echo ""
      echo -e "${RED}#${RESET} The TXT record you created was incorrect.."
      echo ""
      echo -e "${RED}---${RESET}"
    fi
    if cat ${eus_dir}/logs/lets_encrypt_${time_date}.log | grep -iq 'Account creation on ACMEv1 is disabled'; then
      echo ""
      echo -e "${RED}---${RESET}"
      echo ""
      echo -e "${RED}#${RESET} Account creation on ACMEv1 is disabled.."
      echo ""
      echo -e "${RED}---${RESET}"
    fi
    if [[ -f ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log ]] && cat ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log | grep -iq 'Keystore was tampered with, or password was incorrect'; then
      echo ""
      echo -e "${RED}#${RESET} Please clear your browser cache if you're seeing connection errors."
      echo ""
      echo -e "${RED}---${RESET}"
      echo ""
      echo -e "${RED}#${RESET} Keystore was tampered with, or password was incorrect"
      echo ""
      echo -e "${RED}---${RESET}"
      if [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
        rm -rf /usr/lib/unifi/data/keystore 2> /dev/null && service unifi restart
      fi
    fi
  fi
  rm -rf /etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh
  rm -rf /etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh
  run_uck_scripts=no
}

cloudkey_management_ui() {
  mkdir -p ${eus_dir}/cloudkey/certs_backups && touch ${eus_dir}/cloudkey/cloudkey_management_ui
  echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into the Cloudkey User Interface.."
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.key_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cp /etc/ssl/private/cloudkey.crt ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_$(date +%Y%m%d_%H%M)
  cp /etc/ssl/private/cloudkey.key ${eus_dir}/cloudkey/certs_backups/cloudkey.key_$(date +%Y%m%d_%H%M)
  if [[ -f ${fullchain_pem}.pem ]]; then
    cp ${fullchain_pem}.pem /etc/ssl/private/cloudkey.crt
  elif [[ -f /etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem ]]; then
    cp /etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem /etc/ssl/private/cloudkey.crt
  fi
  if [[ -f ${priv_key_pem}.pem ]]; then
    cp ${priv_key_pem}.pem /etc/ssl/private/cloudkey.key
  elif [[ -f /etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem ]]; then
    cp /etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem /etc/ssl/private/cloudkey.key
  fi
  service nginx restart && echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the Cloudkey User Interface!" && sleep 2
  if [[ $(dpkg-query -W -f='${Status}' unifi-protect 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
    echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Protect!"
    unifi_protect_status=$(service unifi-protect status | grep -i 'Active:' | awk '{print $2}')
    if [[ ${unifi_protect_status} == 'active' ]]; then
      service unifi-protect restart && echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Protect!" && sleep 2
    else
      echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Protect!" && sleep 2
    fi
  fi
}

cloudkey_unifi_led() {
  mkdir -p ${eus_dir}/cloudkey/ && touch ${eus_dir}/cloudkey/cloudkey_unifi_led
  echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED!"
  service unifi-led restart && echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED!" && sleep 2
}

cloudkey_unifi_talk() {
  mkdir -p ${eus_dir}/cloudkey/ && touch ${eus_dir}/cloudkey/cloudkey_unifi_talk
  echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Talk!"
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/talk/certs_backups/server.pem_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mkdir -p ${eus_dir}/talk/certs_backups && cp /usr/share/unifi-talk/app/certs/server.pem ${eus_dir}/talk/certs_backups/server.pem_$(date +%Y%m%d_%H%M)
  cat /etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem /etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem > /usr/share/unifi-talk/app/certs/server.pem
  service unifi-talk restart && echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Talk!" && sleep 2
}

uas_management_ui() {
  mkdir -p ${eus_dir}/uas/certs_backups/ && touch ${eus_dir}/uas/uas_management_ui
  echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Application Server User Interface.."
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/uas/certs_backups/uas.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/uas/certs_backups/uas.key_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cp /etc/uas/uas.crt ${eus_dir}/uas/certs_backups/uas.crt_$(date +%Y%m%d_%H%M)
  cp /etc/uas/uas.key ${eus_dir}/uas/certs_backups/uas.key_$(date +%Y%m%d_%H%M)
  if [[ -f ${fullchain_pem}.pem ]]; then
    cp ${fullchain_pem}.pem /etc/uas/uas.crt
  elif [[ -f /etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem ]]; then
    cp /etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem /etc/uas/uas.key
  fi
  if [[ -f ${priv_key_pem}.pem ]]; then
    cp ${priv_key_pem}.pem /etc/uas/uas.key
  elif [[ -f /etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem ]]; then
    cp /etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem /etc/uas/uas.key
  fi
  service uas restart && echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Application Server User Interface!" && sleep 2
}

uas_unifi_led() {
  mkdir -p ${eus_dir}/eot/certs_backups && touch ${eus_dir}/eot/uas_unifi_led
  if dpkg -l | grep -iq "\bUAS\b\|UniFi Application Server"; then
    echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED on the UniFi Application Server!"
  else
    echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-LED!"
  fi
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/eot/certs_backups/server.pem_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  cat /etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem /etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem > ${eus_dir}/eot/eot_docker_container.pem
  eot_container=$(docker container ls | grep -i ubnt/eot | awk '{print $1}')
  eot_container_name=ueot
  if [[ -n "${eot_container}" ]]; then
    docker cp ${eot_container}:/app/certs/server.pem ${eus_dir}/eot/certs_backups/server.pem_$(date +%Y%m%d_%H%M)
    docker cp ${eus_dir}/eot/eot_docker_container.pem ${eot_container}:/app/certs/server.pem
    docker restart ${eot_container_name} &>> ${eus_dir}/eot/ueot_container_restart && if dpkg -l | grep -iq "\bUAS\b\|UniFi Application Server"; then echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED on the UniFi Application Server!"; else echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-LED!"; fi && sleep 2
  else
    rm -rf ${eus_dir}/eot/uas_unifi_led 2> /dev/null
    echo -e "${RED}#${RESET} Couldn't find UniFi LED container.." && sleep 2
  fi
}

unifi_video() {
  mkdir -p ${eus_dir}/video/keystore_backups && touch ${eus_dir}/video/unifi_video
  echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into UniFi-Video!"
  mkdir -p /usr/lib/unifi-video/data/certificates
  mkdir -p /var/lib/unifi-video/certificates
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/video/keystore_backups/keystore_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/video/keystore_backups/ufv-truststore_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  openssl pkcs8 -topk8 -nocrypt -in /etc/letsencrypt/live/${server_fqdn}${le_var}/privkey.pem -outform DER -out /usr/lib/unifi-video/data/certificates/ufv-server.key.der
  openssl x509 -outform der -in /etc/letsencrypt/live/${server_fqdn}${le_var}/fullchain.pem -out /usr/lib/unifi-video/data/certificates/ufv-server.cert.der
  chown -R unifi-video:unifi-video /var/lib/unifi-video/certificates
  service unifi-video stop
  mv /usr/lib/unifi-video/data/keystore ${eus_dir}/video/keystore_backups/keystore_$(date +%Y%m%d_%H%M)
  mv /usr/lib/unifi-video/data/ufv-truststore ${eus_dir}/video/keystore_backups/ufv-truststore_$(date +%Y%m%d_%H%M)
  if ! cat /usr/lib/unifi-video/data/system.properties | grep -iq "^ufv.custom.certs.enable=true"; then
    echo "ufv.custom.certs.enable=true" >> /usr/lib/unifi-video/data/system.properties
  fi
  service unifi-video start && echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into UniFi-Video!" && sleep 2
}

unifi_network_controller() {
  echo "" && echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Controller.."
  echo -e "\n------- $(date +%F-%R) -------\n" &>> ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log
  md5sum ${fullchain_pem}.pem >${fullchain_pem}.pem.md5 &>> ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log
  if [[ ${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/network/keystore_backups/keystore_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
  mkdir -p ${eus_dir}/network/keystore_backups && cp /usr/lib/unifi/data/keystore ${eus_dir}/network/keystore_backups/keystore_$(date +%Y%m%d_%H%M)
  openssl pkcs12 -export -inkey ${priv_key_pem}.pem -in ${fullchain_pem}.pem -out ${fullchain_pem}.p12 -name unifi -password pass:aircontrolenterprise &>> ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log
  keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log
  keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore ${fullchain_pem}.p12 -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log
  service unifi restart && echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Controller!" && sleep 2
  if [[ -f ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log ]] && cat ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log | grep -iq 'Keystore was tampered with, or password was incorrect'; then
    if ! [[ -f ${eus_dir}/network/failed ]]; then
      echo -e "${RED}#${RESET} Importing into the UniFi Network Controller failed.. let's clean up some files and try it one more time."
      rm -rf /usr/lib/unifi/data/keystore 2> /dev/null && service unifi restart
      rm -rf ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log 2> /dev/null
      mkdir -p ${eus_dir}/network/ && touch ${eus_dir}/network/failed
	  unifi_network_controller
    else
      le_import_failed
    fi
  fi
}

import_ssl_certificates() {
  clear
  header
  if [[ ${prefer_dns_challenge} == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} Performing the DNS challenge!"
    echo ""
    ${certbot} certonly --manual --agree-tos --preferred-challenges dns --domain "${server_fqdn}" ${email} ${renewal_option} --manual-public-ip-logging-ok | tee -a ${eus_dir}/logs/lets_encrypt_${time_date}.log && dns_certbot_success=true
  else
    if [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
      if [[ $renewal_option == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates and importing them into the UniFi Network Controller!"
      else
        echo -e "${WHITE_R}#${RESET} Importing the SSL certificates into the UniFi Network Controller.."
      fi
    else
      if [[ $renewal_option == "--force-renewal" ]]; then
        echo -e "${WHITE_R}#${RESET} Force renewing the SSL certificates"
      else
        echo -e "${WHITE_R}#${RESET} Creating the certificates!"
      fi
    fi
    ${certbot} certonly --standalone --agree-tos --preferred-challenges http --pre-hook /etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh --post-hook /etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh --domain "${server_fqdn}" ${email} ${renewal_option} --non-interactive &> ${eus_dir}/logs/lets_encrypt_${time_date}.log && certbot_success=true
  fi
  if [[ ${certbot_success} == 'true' ]] || [[ ${dns_certbot_success} == 'true' ]]; then
    if [[ ${certbot_success} == 'true' ]]; then
      if [[ -f ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log ]] && cat ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log | grep -iq 'Keystore was tampered with, or password was incorrect'; then
        mkdir -p ${eus_dir}/network/ && touch ${eus_dir}/network/failed
        unifi_network_controller
      else
        rm -rf ${eus_dir}/logs/lets_encrypt_import_$(date +%Y%m%d).log 2> /dev/null
        echo -e "${GREEN}#${RESET} Successfully imported the SSL certificates into the UniFi Network Controller!"
        echo ""
        if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then
          run_uck_scripts=true
        fi
      fi
      if ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log &>/dev/null; then
        le_var=$(cat ${eus_dir}/logs/lets_encrypt_${time_date}.log | grep -i "/etc/letsencrypt/live/${server_fqdn}" | awk '{print $1}' | head -n1 | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
      fi
    fi
    if [[ ${dns_certbot_success} == 'true' ]]; then
      clear
      header
      echo -e "${GREEN}#${RESET} Successfully created the SSL Certificates!"
      if [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
        echo ""
        echo -e "${WHITE_R}---${RESET}"
        echo ""
        echo -e "${WHITE_R}#${RESET} UniFi Network Controller has been detected!"
        echo ""
        read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Network Controller? (Y/n) ' yes_no
        case "$yes_no" in
           [Yy]*|"")
              unifi_network_controller
              if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then run_uck_scripts=true; fi;;
           [Nn]*) ;;
        esac
      fi
    fi
    if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then
      echo ""
      echo -e "${WHITE_R}---${RESET}"
      echo ""
      echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
      echo ""
      if uname -a | awk '{print $2}' | grep -iq 'CloudKey-Gen2-Plus' && [[ $(dpkg-query -W -f='${Status}' unifi-protect 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
        read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface and UniFi-Protect? (Y/n) ' yes_no
      else
        read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface? (Y/n) ' yes_no
      fi
      case "$yes_no" in
         [Yy]*|"")
            cloudkey_management_ui
            run_uck_scripts=true;;
         [Nn]*) ;;
      esac
      if [[ $(dpkg-query -W -f='${Status}' unifi-led 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
        echo ""
        echo -e "${WHITE_R}---${RESET}"
        echo ""
        echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
        echo ""
        read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no
        case "$yes_no" in
           [Yy]*|"")
            cloudkey_unifi_led
            run_uck_scripts=true;;
           [Nn]*) ;;
        esac
      fi
      if [[ $(dpkg-query -W -f='${Status}' unifi-talk 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
        echo ""
        echo -e "${WHITE_R}---${RESET}"
        echo ""
        echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
        echo ""
        read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Talk? (Y/n) ' yes_no
        case "$yes_no" in
           [Yy]*|"")
            cloudkey_unifi_talk
            run_uck_scripts=true;;
           [Nn]*) ;;
        esac
      fi
    fi
    if dpkg -l | grep -iq "\bUAS\b\|UniFi Application Server"; then
      echo -e "${WHITE_R}---${RESET}"
      echo ""
      echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
      echo ""
      read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Application Server User Interface? (Y/n) ' yes_no
      case "$yes_no" in
         [Yy]*|"") uas_management_ui;;
         [Nn]*) ;;
      esac
      if [[ $(dpkg-query -W -f='${Status}' uas-led 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
        echo ""
        echo -e "${WHITE_R}---${RESET}"
        echo ""
        echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
        echo ""
        read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no
        case "$yes_no" in
           [Yy]*|"") uas_unifi_led;;
           [Nn]*) ;;
        esac
      fi
    fi
    if [[ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
      echo ""
      echo -e "${WHITE_R}---${RESET}"
      echo ""
      echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
      echo ""
      read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Video? (Y/n) ' yes_no
      case "$yes_no" in
         [Yy]*|"") unifi_video;;
         [Nn]*) ;;
      esac
    fi
    if [[ $(dpkg-query -W -f='${Status}' uas-led 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
      if dpkg -l | awk '{print $2}' | grep -iq "^docker-ce"; then
        if docker container ls | grep -iq 'ubnt/eot'; then
          echo ""
          echo -e "${WHITE_R}---${RESET}"
          echo ""
          echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
          echo ""
          read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"") uas_unifi_led;;
             [Nn]*) ;;
          esac
        fi
      fi
    fi
    if [[ ${dns_certbot_success} == 'true' ]]; then
      rm -rf ${eus_dir}/expire_date &> /dev/null
      rm -rf /etc/letsencrypt/renewal-hooks/post/EUS_${server_fqdn}.sh &> /dev/null
      rm -rf /etc/letsencrypt/renewal-hooks/pre/EUS_${server_fqdn}.sh &> /dev/null
      certbot certificates --domain "${server_fqdn}" &>> ${eus_dir}/expire_date
      if grep -iq "${server_fqdn}" ${eus_dir}/expire_date; then
        expire_date=$(cat ${eus_dir}/expire_date | grep -i "Expiry Date:" | awk '{print $3}')
      fi
      rm -rf ${eus_dir}/expire_date &> /dev/null
      if [[ -n "${expire_date}" ]]; then
         echo ""
         echo -e "${GREEN}---${RESET}"
         echo ""
         echo -e "${WHITE_R}#${RESET} Your SSL certificates will expire at '${expire_date}'"
         echo -e "${WHITE_R}#${RESET} Please run this script again before '${expire_date}' to renew your certificates"
      fi
    fi
  else
    le_import_failed
  fi
}

import_existing_ssl_certificates() {
  case "$yes_no" in
     [Yy]*|"")
        if [[ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
          echo ""
          echo -e "${WHITE_R}---${RESET}"
          echo ""
          echo -e "${WHITE_R}#${RESET} UniFi Network Controller ( SDN ) has been detected!"
          echo ""
          read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Network Controller? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"")
                unifi_network_controller
                if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then run_uck_scripts=true; fi;;
             [Nn]*) ;;
          esac
        fi
        if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then
          echo ""
          echo -e "${WHITE_R}---${RESET}"
          echo ""
          echo -e "${WHITE_R}#${RESET} You seem to have a Cloud Key!"
          echo ""
          if uname -a | awk '{print $2}' | grep -iq 'CloudKey-Gen2-Plus' && [[ $(dpkg-query -W -f='${Status}' unifi-protect 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
            read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface and UniFi-Protect? (Y/n) ' yes_no
          else
            read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Cloudkey User Interface? (Y/n) ' yes_no
          fi
          case "$yes_no" in
             [Yy]*|"")
                  cloudkey_management_ui
                  run_uck_scripts=true;;
             [Nn]*) ;;
          esac
          if [[ $(dpkg-query -W -f='${Status}' unifi-led 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
            echo ""
            echo -e "${WHITE_R}---${RESET}"
            echo ""
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            echo ""
            read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  cloudkey_unifi_led
                  run_uck_scripts=true;;
               [Nn]*) ;;
            esac
          fi
          if [[ $(dpkg-query -W -f='${Status}' unifi-talk 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
            echo ""
            echo -e "${WHITE_R}---${RESET}"
            echo ""
            echo -e "${WHITE_R}#${RESET} UniFi-Talk has been detected!"
            echo ""
            read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Talk? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  cloudkey_unifi_talk
                  run_uck_scripts=true;;
               [Nn]*) ;;
            esac
          fi
        fi
        if dpkg -l | grep -iq "\bUAS\b\|UniFi Application Server"; then
          echo ""
          echo -e "${WHITE_R}---${RESET}"
          echo ""
          echo -e "${WHITE_R}#${RESET} You seem to have a UniFi Application Server!"
          echo ""
          read -p $'\033[39m#\033[0m Would you like to apply the certificates to the UniFi Application Server User Interface? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"") uas_management_ui;;
             [Nn]*) ;;
          esac
          if [[ $(dpkg-query -W -f='${Status}' uas-led 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
            echo ""
            echo -e "${WHITE_R}---${RESET}"
            echo ""
            echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
            echo ""
            read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"") uas_unifi_led;;
               [Nn]*) ;;
            esac
          fi
        fi
        if [[ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -ge 1 ]]; then
          echo ""
          echo -e "${WHITE_R}---${RESET}"
          echo ""
          echo -e "${WHITE_R}#${RESET} UniFi-Video has been detected!"
          echo ""
          read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-Video? (Y/n) ' yes_no
          case "$yes_no" in
             [Yy]*|"") unifi_video;;
             [Nn]*) ;;
          esac
        fi
        if [[ $(dpkg-query -W -f='${Status}' uas-led 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
          if dpkg -l | awk '{print $2}' | grep -iq "^docker-ce"; then
            if docker container ls | grep -iq 'ubnt/eot'; then
              echo ""
              echo -e "${WHITE_R}---${RESET}"
              echo ""
              echo -e "${WHITE_R}#${RESET} UniFi-LED has been detected!"
              echo ""
              read -p $'\033[39m#\033[0m Would you like to apply the certificates to UniFi-LED? (Y/n) ' yes_no
              case "$yes_no" in
                 [Yy]*|"") uas_unifi_led;;
                 [Nn]*) ;;
              esac
            fi
          fi
        fi;;
     [Nn]*) ;;
  esac
}

le_question() {
  clear
  header
  read -p $'\033[39m#\033[0m Would you like to setup a SSL certificate ( Lets Encrypt )? (Y/n) ' yes_no
  case "${yes_no}" in
     [Yy]*|"")
        ls -t ${eus_dir}/logs/lets_encrypt_*.log 2> /dev/null | awk 'NR>2' | xargs rm -f &> /dev/null
        if [[ $os_codename =~ (jessie) || ${downloaded_certbot} == 'true' ]]; then certbot_auto_install_run; fi
        timezone
        delete_certs_question
        domain_name
        le_email
        le_post_hook
        le_pre_hook
        rm -rf ${eus_dir}/certificates 2> /dev/null
        ${certbot} certificates --domain "${server_fqdn}" &>> ${eus_dir}/certificates
        if grep -iq "${server_fqdn}" ${eus_dir}/certificates; then
          valid_days=$(cat ${eus_dir}/certificates | grep -i "valid:" | awk '{print $6}' | sed 's/)//' | grep -o -E '[0-9]+' | head -n1)
          if [[ -z "${valid_days}" ]]; then
            valid_days=$(cat ${eus_dir}/certificates | grep -i "valid:" | awk '{print $6}' | sed 's/)//' | head -n1)
          fi
          le_fqdn=$(cat ${eus_dir}/certificates | grep ${valid_days} -A2 | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | head -n1)
          fullchain_pem=$(cat ${eus_dir}/certificates | grep -i "Certificate Path" | grep -i "${le_fqdn}" | awk '{print $3}' | sed 's/.pem//g' | head -n1)
          priv_key_pem=$(cat ${eus_dir}/certificates | grep -i "Private Key Path" | grep -i "${le_fqdn}" | awk '{print $4}' | sed 's/.pem//g' | head -n1)
          expire_date=$(cat ${eus_dir}/certificates | grep -i "Expiry Date:" | grep -i "${le_fqdn}" | awk '{print $3}' | head -n1)
          if [[ ${valid_days} == 'EXPIRED' ]] || [[ ${valid_days} -lt '30' ]]; then
            clear
            header
            if [[ ${valid_days} == 'EXPIRED' ]]; then
              echo -e "${WHITE_R}#${RESET} Your certificates for '${server_fqdn}' are already EXPIRED!"
            else
              echo -e "${WHITE_R}#${RESET} Your certificates for '${server_fqdn}' in ${valid_days} days.."
            fi
            echo ""
            read -p $'\033[39m#\033[0m Do you want to force renew the certficiates? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  renewal_option="--force-renewal"
                  import_ssl_certificates;;
               [Nn]*)
                  read -p $'\033[39m#\033[0m Would you like to import the existing certificates? (Y/n) ' yes_no
                  import_existing_ssl_certificates;;
            esac
          elif [[ ${valid_days} -ge '30' ]]; then
            clear
            header
            echo -e "${WHITE_R}#${RESET} You already seem to have certificates for '${server_fqdn}', those expire in ${valid_days} days.."
            echo ""
            read -p $'\033[39m#\033[0m Would you like to import the existing certificates? (Y/n) ' yes_no
            case "$yes_no" in
               [Yy]*|"")
                  import_existing_ssl_certificates;;
               [Nn]*) ;;
            esac
          fi
        else
          import_ssl_certificates
        fi;;
     [Nn]*) ;;
  esac
  if [[ ${certbot_auto} == 'true' ]]; then
    tee /etc/cron.d/eus_certbot &>/dev/null << EOF
# /etc/cron.d/certbot: crontab entries for the certbot package
#
# Upstream recommends attempting renewal twice a day
#
# Eventually, this will be an opportunity to validate certificates
# haven't been revoked, etc.  Renewal will only occur if expiration
# is within 30 days.
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

0 */12 * * * root ${eus_dir}/certbot-auto -q renew
EOF
  fi
  if [[ ${run_uck_scripts} == 'true' ]]; then
    if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then
      echo "" && echo -e "${WHITE_R}---${RESET}" && echo ""
      echo -e "${WHITE_R}#${RESET} Creating required scripts and adding them as cronjobs!"
      mkdir -p /srv/EUS/cronjob
      if dpkg --print-architecture | grep -iq 'armhf'; then
        touch /usr/lib/eus &>/dev/null
        echo "$(cat /usr/lib/version)" &> /srv/EUS/cloudkey/version
        tee /etc/cron.d/eus_script_uc_ck &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root bash /srv/EUS/cronjob/eus_uc_ck.sh
EOF
        tee /srv/EUS/cronjob/eus_uc_ck.sh &>/dev/null << EOF
#!/bin/bash
if [[ -f /srv/EUS/cloudkey/version ]]; then
  current_version=\$(cat /usr/lib/version)
  old_version=\$(cat /srv/EUS/cloudkey/version)
  if [[ \${old_version} != \${current_version} ]] || ! [[ -f /usr/lib/eus ]]; then
    touch /usr/lib/eus
    echo "\$(date +%F-%R) | Cloudkey firmware version changed from \${old_version} to \${current_version}" &>> /srv/EUS/logs/uc-ck_firmware_versions.log
  fi
  server_fqdn="${server_fqdn}"
  if ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log &>/dev/null; then
    last_le_log=\$(ls ${eus_dir}/logs/lets_encrypt_[0-9]*.log | tail -n1)
    le_var=\$(cat \${last_le_log} | grep -i "/etc/letsencrypt/live/${server_fqdn}" | awk '{print \$1}' | head -n1 | sed 's/\/etc\/letsencrypt\/live\///g' | grep -io "${server_fqdn}.*" | cut -d'/' -f1 | sed "s/${server_fqdn}//g")
  fi
  if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem && -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
    uc_ck_key=\$(cat /etc/ssl/private/cloudkey.key)
    priv_key=\$(cat /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem)
    if [[ \${uc_ck_key} != \${priv_key} ]]; then
      echo "\$(date +%F-%R) | Certificates were different.. applying the Let's Encrypt ones." &>> /srv/EUS/logs/uc_ck_certificates.log
      cp /etc/ssl/private/cloudkey.crt ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_\$(date +%Y%m%d_%H%M)
      cp /etc/ssl/private/cloudkey.key ${eus_dir}/cloudkey/certs_backups/cloudkey.key_\$(date +%Y%m%d_%H%M)
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem /etc/ssl/private/cloudkey.crt
      fi
      if [[ -f /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem ]]; then
        cp /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem /etc/ssl/private/cloudkey.key
      fi
      service nginx restart
      if [[ \$(dpkg-query -W -f='\${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]]; then
        echo -e "\n------- \$(date +%F-%R) -------\n" &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        if [[ \${old_certificates} == 'last_three' ]]; then ls -t ${eus_dir}/cloudkey/certs_backups/cloudkey.crt_* 2> /dev/null | awk 'NR>3' | xargs rm -f 2> /dev/null; fi
        mkdir -p ${eus_dir}/network/keystore_backups && cp /usr/lib/unifi/data/keystore ${eus_dir}/network/keystore_backups/keystore_\$(date +%Y%m%d_%H%M)
        openssl pkcs12 -export -inkey /etc/letsencrypt/live/${server_fqdn}\${le_var}/privkey.pem -in /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.pem -out /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12 -name unifi -password pass:aircontrolenterprise &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        keytool -delete -alias unifi -keystore /usr/lib/unifi/data/keystore -deststorepass aircontrolenterprise &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        keytool -importkeystore -deststorepass aircontrolenterprise -destkeypass aircontrolenterprise -destkeystore /usr/lib/unifi/data/keystore -srckeystore /etc/letsencrypt/live/${server_fqdn}\${le_var}/fullchain.p12 -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -alias unifi -noprompt &>> ${eus_dir}/logs/uc_ck_unifi_import.log
        service unifi restart
      fi
    fi
  fi
  if [[ -f /srv/EUS/logs/uc_ck_certificates.log ]]; then
    uc_ck_certificates_log_size=\$(du -sc /srv/EUS/logs/uc_ck_certificates.log | grep total\$ | awk '{print \$1}')
    if [[ \${uc_ck_certificates_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc_ck_certificates.log &> /srv/EUS/logs/uc_ck_certificates_tmp.log
      cp /srv/EUS/logs/uc_ck_certificates_tmp.log /srv/EUS/logs/uc_ck_certificates.log && rm -rf /srv/EUS/logs/uc_ck_certificates_tmp.log
    fi
  fi
  if [[ -f /srv/EUS/logs/uc-ck_firmware_versions.log ]]; then
    firmware_versions_log_size=\$(du -sc /srv/EUS/logs/uc-ck_firmware_versions.log | grep total\$ | awk '{print \$1}')
    if [[ \${firmware_versions_log_size} -gt '50' ]]; then
      tail -n5 /srv/EUS/logs/uc-ck_firmware_versions.log &> /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
      cp /srv/EUS/logs/uc-ck_firmware_versions_tmp.log /srv/EUS/logs/uc-ck_firmware_versions.log && rm -rf /srv/EUS/logs/uc-ck_firmware_versions_tmp.log
    fi
  fi
  if [[ -f ${eus_dir}/cloudkey/uc_ck_unifi_import.log ]]; then
    unifi_import_log_size=\$(du -sc ${eus_dir}/logs/uc_ck_unifi_import.log | grep total\$ | awk '{print \$1}')
    if [[ \${unifi_import_log_size} -gt '50' ]]; then
      tail -n100 ${eus_dir}/logs/uc_ck_unifi_import.log &> ${eus_dir}/cloudkey/unifi_import_tmp.log
      cp ${eus_dir}/cloudkey/unifi_import_tmp.log ${eus_dir}/logs/uc_ck_unifi_import.log && rm -rf ${eus_dir}/cloudkey/unifi_import_tmp.log
    fi
  fi
fi
EOF
        chmod +x /srv/EUS/cronjob/eus_uc_ck.sh
      fi
      tee /etc/cron.d/eus_script &>/dev/null << EOF
SHELL=/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
@reboot root bash /srv/EUS/cronjob/install_certbot.sh
EOF
      tee /srv/EUS/cronjob/install_certbot.sh &>/dev/null << EOF
#!/bin/bash
if [[ \$(dpkg-query -W -f='\${Status}' certbot 2>/dev/null | grep -c "ok installed") -eq 0 ]]; then
  if [[ -f /srv/EUS/certbot_install_failed ]]; then
    rm -rf /srv/EUS/certbot_install_failed
  fi
  if [[ -f /srv/EUS/logs/cronjob_install.log ]]; then
    cronjob_install_log_size=\$(du -sc /srv/EUS/logs/cronjob_install.log | grep total\$ | awk '{print \$1}')
    if [[ \${cronjob_install_log_size} -gt '50' ]]; then
      tail -n100 /srv/EUS/logs/cronjob_install.log &> /srv/EUS/logs/cronjob_install_tmp.log
      cp /srv/EUS/logs/cronjob_install_tmp.log /srv/EUS/logs/cronjob_install.log && rm -rf /srv/EUS/logs/cronjob_install_tmp.log
    fi
  fi
  if [[ -z "\$(command -v lsb_release)" ]]; then
    if [[ -f "/etc/os-release" ]]; then
      if [[ -n "\$(grep VERSION_CODENAME /etc/os-release)" ]]; then
        os_codename=\$(grep VERSION_CODENAME /etc/os-release | sed 's/VERSION_CODENAME//g' | tr -d '="')
      elif [[ -z "\$(grep VERSION_CODENAME /etc/os-release)" ]]; then
        os_codename=\$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print \$4}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g')
        if [[ -z \${os_codename} ]]; then
          os_codename=\$(grep PRETTY_NAME /etc/os-release | sed 's/PRETTY_NAME=//g' | tr -d '="' | awk '{print \$3}' | sed 's/\((\|)\)//g' | sed 's/\/sid//g')
        fi
      fi
    fi
  else
    os_codename=\$(lsb_release -cs)
  fi
  echo -e "\n------- \$(date +%F-%R) -------\n" &>>/srv/EUS/logs/cronjob_install.log
  if [[ \$os_codename == "jessie" ]]; then
    if [[ ! -f "${eus_dir}/certbot-auto" && -s "${eus_dir}/certbot-auto" ]]; then
      curl -s https://dl.eff.org/certbot-auto -o ${eus_dir}/certbot-auto &>>/srv/EUS/logs/cronjob_install.log
      chown root ${eus_dir}/certbot-auto &>>/srv/EUS/logs/cronjob_install.log
      chmod 0755 ${eus_dir}/certbot-auto &>>/srv/EUS/logs/cronjob_install.log
      echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list
      apt-get update -o Acquire::Check-Valid-Until=false &>>/srv/EUS/logs/cronjob_install.log
      apt-get install -t jessie-backports libssl-dev -y &>>/srv/EUS/logs/cronjob_install.log
      sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list &>>/srv/EUS/logs/cronjob_install.log
    fi
    if [[ -f "${eus_dir}/certbot-auto" || -s "${eus_dir}/certbot-auto" ]]; then
      if [[ \$(stat -c "%a" "${eus_dir}/certbot-auto") != "755" ]]; then
        chmod 0755 ${eus_dir}/certbot-auto
      fi
      if [[ \$(stat -c "%U" "${eus_dir}/certbot-auto") != "root" ]] ; then
        chown root ${eus_dir}/certbot-auto
      fi
    fi
    ${eus_dir}/certbot-auto --non-interactive --install-only --verbose &>>/srv/EUS/logs/cronjob_install.log
  fi
  if [[ \$os_codename == "stretch" ]]; then
    apt-get update &>>/srv/EUS/logs/cronjob_install.log
    apt-get install certbot -y &>>/srv/EUS/logs/cronjob_install.log
    if [[ \$? > 0 ]]; then
      if [[ \$(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list
        apt-get update &>>/srv/EUS/logs/cronjob_install.log
        apt-get install certbot -y &>>/srv/EUS/logs/cronjob_install.log || touch /srv/EUS/certbot_install_failed
      fi
    fi
  fi
fi
EOF
      chmod +x /srv/EUS/cronjob/install_certbot.sh
    fi
  fi
  echo ""
  echo ""
  if [[ ${script_timeout_http} == 'true' ]]; then
    echo -e "${WHITE_R}#${RESET} A DNS challenge requires you to add a TXT record to your domain register. ( NO AUTO RENEWING )"
    echo -e "${WHITE_R}#${RESET} The DNS challenge is only recommend for users where the ISP blocks port 80. ( rare occasions )"
    echo ""
    read -p $'\033[39m#\033[0m Would you like to use the DNS challenge? (Y/n) ' yes_no
    case "$yes_no" in
       [Yy]*|"")
          if [[ ${run_ipv6} == 'true' ]]; then
            bash $0 -dns -v6 || ./$0 -dns -v6; exit 0
          else
            bash $0 -dns || ./$0 -dns; exit 0
          fi;;
       [Nn]*) ;;
    esac
  fi
}
le_question
