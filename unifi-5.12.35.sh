#!/bin/bash

# UniFi Controller 5.12.35 auto installation script.
# OS       | List of supported Distributions/OS
#
#          | Ubuntu Precise Pangolin ( 12.04 )
#          | Ubuntu Trusty Tahr ( 14.04 )
#          | Ubuntu Xenial Xerus ( 16.04 )
#          | Ubuntu Bionic Beaver ( 18.04 )
#          | Ubuntu Cosmic Cuttlefish ( 18.10 )
#          | Ubuntu Disco Dingo  ( 19.04 )
#          | Ubuntu Eoan Ermine  ( 19.10 )
#          | Debian Jessie ( 8 )
#          | Debian Stretch ( 9 )
#          | Debian Buster ( 10 )
#          | Debian Bullseye ( 11 )
#          | Linux Mint 13 ( Maya )
#          | Linux Mint 17 ( Qiana | Rebecca | Rafaela | Rosa )
#          | Linux Mint 18 ( Sarah | Serena | Sonya | Sylvia )
#          | Linux Mint 19 ( Tara | Tessa | Tina )
#          | MX Linux 18 ( Continuum )
#          | Parrot OS
#
# Version  | 4.3.1
# Author   | Glenn Rietveld
# Email    | glennrietveld8@hotmail.nl
# Website  | https://GlennR.nl

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                           Color Codes                                                                                           #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

RESET='\033[0m'
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
  -skip) script_option_skip=true;; # Skip script removal and repository question
  esac
  shift
done

if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "downloads-distro.mongodb.org") -gt 0 ]]; then
  get_repo_lists=`grep -riIl "downloads-distro.mongodb.org" /etc/apt/ >> /tmp/glennr_dead_repo`
  repo_lists=$(tr '\r\n' ' ' < /tmp/glennr_dead_repo)
  for glennr_mongo_repo in ${repo_lists[@]}; do
    sed -i '/downloads-distro.mongodb.org/d' ${glennr_mongo_repo} 2> /dev/null
	if ! [[ -s ${glennr_mongo_repo} ]]; then
      rm -rf ${glennr_mongo_repo} 2> /dev/null
    fi
  done;
  rm -rf /tmp/glennr_dead_repo 2> /dev/null
fi

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

http_proxy_found() {
  clear
  header
  echo -e "${GREEN}#${RESET} HTTP Proxy found. | ${WHITE_R}${http_proxy}${RESET}"
  echo ""
  echo ""
}

remove_yourself() {
  if [[ $delete_script == 'true' || $script_option_skip == 'true' ]]; then
    if [[ -e $0 ]]; then
      rm -rf $0 2> /dev/null
    fi
  fi
}

author() {
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Author   |  ${WHITE_R}Glenn R.${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Email    |  ${WHITE_R}glennrietveld8@hotmail.nl${RESET}"
  echo -e "${WHITE_R}#${RESET} ${GRAY_R}Website  |  ${WHITE_R}https://GlennR.nl${RESET}"
  echo ""
  echo ""
  echo ""
}

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

if ! [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|cosmic|disco|eoan|jessie|stretch|continuum|buster|bullseye) ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} This script is not made for your OS.."
  echo -e "${WHITE_R}#${RESET} Feel free to contact Glenn R. (AmazedMender16) on the Community Forums if you need help with installing your UniFi Network Controller."
  echo -e ""
  echo -e "OS_CODENAME = ${os_codename}"
  echo -e ""
  echo -e ""
  exit 1
fi

if ! grep -iq '127.0.0.1.*localhost' /etc/hosts; then
  if [[ ${script_option_skip} != 'true' ]]; then
    clear
    header_red
    echo -e "${WHITE_R}#${RESET} '127.0.0.1   localhost' does not exist in your /etc/hosts file."
    echo -e "${WHITE_R}#${RESET} You will most likely see controller startup issues if it doesn't exist.."
    echo ""
    echo ""
    echo ""
    read -p $'\033[39m#\033[0m Do you want to add "127.0.0.1   localhost" to your /etc/hosts file? (Y/n) ' yes_no
    case "$yes_no" in
        [Yy]*|"")
            echo -e "${WHITE_R}----${RESET}"
            echo ""
            echo -e "${WHITE_R}#${RESET} Adding '127.0.0.1       localhost' to /etc/hosts"
            echo -e "$(echo '# Added by GlennR ( EUS/EIS ) script\n127.0.0.1       localhost\n# ------------------------------' | cat - /etc/hosts)" > /etc/hosts && echo -e "\n${WHITE_R}#${RESET} Done.."
            echo ""
            echo ""
            sleep 3;;
        [Nn]*) ;;
    esac
  else
    clear
    header_red
    echo -e "${WHITE_R}#${RESET} '127.0.0.1   localhost' does not exist in your /etc/hosts file."
    echo -e "${WHITE_R}#${RESET} Adding '127.0.0.1       localhost' to /etc/hosts"
    echo -e "$(echo '# Added by GlennR ( EUS/EIS ) script\n127.0.0.1       localhost\n# ------------------------------' | cat - /etc/hosts)" > /etc/hosts && echo -e "\n${WHITE_R}#${RESET} Done.."
    echo ""
    echo ""
    sleep 3
  fi
fi

if [[ $(echo $PATH | grep -c "/sbin") -eq 0 ]]; then
  #PATH=/sbin:/bin:/usr/bin:/usr/sbin:/usr/local/sbin:/usr/local/bin
  PATH=$PATH:/usr/sbin
fi

if [ ! -d /etc/apt/sources.list.d ]; then
  mkdir -p /etc/apt/sources.list.d
fi

# Check if UniFi is already installed.
if [ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  clear
  header
  echo ""
  echo -e "${WHITE_R}#${RESET} UniFi is already installed on your system!${RESET}"
  echo -e "${WHITE_R}#${RESET} You can use my Easy Update Script to update your controller.${RESET}"
  echo ""
  echo ""
  read -p $'\033[39m#\033[0m Would you like to download and run my Easy Update Script? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
        rm -rf $0 2> /dev/null
        wget https://get.glennr.nl/unifi/update/unifi-update.sh; chmod +x unifi-update.sh; ./unifi-update.sh; exit 0;;
      [Nn]*) exit 0;;
  esac
fi

dpkg_locked_message() {
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} dpkg is locked.. Waiting for other software managers to finish!"
  echo -e "${WHITE_R}#${RESET} If this is everlasting please contact Glenn R. (AmazedMender16) on the Community Forums!"
  echo ""
  echo ""
  sleep 5
  if [[ -z "$dpkg_wait" ]]; then
    echo "glennr_lock_active" >> /tmp/glennr_lock
  fi
}

dpkg_locked_60_message() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} dpkg is already locked for 60 seconds..."
  echo -e "${WHITE_R}#${RESET} Would you like to force remove the lock?"
  echo ""
  echo ""
  echo ""
}

# Check if dpkg is locked
if [ $(dpkg-query -W -f='${Status}' psmisc 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
  while fuser /var/{lib/{dpkg,apt/lists},cache/apt/archives}/lock >/dev/null 2>&1; do
    dpkg_locked_message
    if [ $(grep glennr_lock_active /tmp/glennr_lock | wc -l) -ge 12 ]; then
      rm -rf /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ ${script_option_skip} != 'true' ]]; then
        read -p $'\033[39m#\033[0m Do you want to proceed with removing the lock? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              killall apt apt-get 2> /dev/null
              rm -rf /var/lib/apt/lists/lock 2> /dev/null
              rm -rf /var/cache/apt/archives/lock 2> /dev/null
              rm -rf /var/lib/dpkg/lock* 2> /dev/null
              dpkg --configure -a 2> /dev/null
              apt-get check >/dev/null 2>&1
              if [ "$?" -ne 0 ]; then
                apt-get install --fix-broken -y 2> /dev/null
              fi
              clear
              clear;;
            [Nn]*) dpkg_wait=true;;
        esac
      else
        killall apt apt-get 2> /dev/null
        rm -rf /var/lib/apt/lists/lock 2> /dev/null
        rm -rf /var/cache/apt/archives/lock 2> /dev/null
        rm -rf /var/lib/dpkg/lock* 2> /dev/null
        dpkg --configure -a 2> /dev/null
        apt-get check >/dev/null 2>&1
        if [ "$?" -ne 0 ]; then
          apt-get install --fix-broken -y 2> /dev/null
        fi
        clear
        clear
      fi
    fi
  done;
else
  dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm -rf /tmp/glennr_dpkg_lock 2> /dev/null; fi
  while [[ $dpkg_locked == 'true'  ]]; do
    unset dpkg_locked
    dpkg_locked_message
    if [ $(grep glennr_lock_active /tmp/glennr_lock | wc -l) -ge 12 ]; then
      rm -rf /tmp/glennr_lock 2> /dev/null
      dpkg_locked_60_message
      if [[ ${script_option_skip} != 'true' ]]; then
        read -p $'\033[39m#\033[0m Do you want to proceed with force removing the lock? (Y/n) ' yes_no
        case "$yes_no" in
            [Yy]*|"")
              ps aux | grep -i apt | awk '{print $2}' >> /tmp/glennr_apt
              glennr_apt_pid_list=$(tr '\r\n' ' ' < /tmp/glennr_apt)
              for glennr_apt in ${glennr_apt_pid_list[@]}; do
                kill -9 $glennr_apt 2> /dev/null
              done;
              rm -rf /tmp/glennr_apt 2> /dev/null
              rm -rf /var/lib/apt/lists/lock 2> /dev/null
              rm -rf /var/cache/apt/archives/lock 2> /dev/null
              rm -rf /var/lib/dpkg/lock* 2> /dev/null
              dpkg --configure -a 2> /dev/null
              apt-get check >/dev/null 2>&1
              if [ "$?" -ne 0 ]; then
                apt-get install --fix-broken -y 2> /dev/null
              fi
              clear
              clear;;
            [Nn]*) dpkg_wait=true;;
        esac
      else
        ps aux | grep -i apt | awk '{print $2}' >> /tmp/glennr_apt
        glennr_apt_pid_list=$(tr '\r\n' ' ' < /tmp/glennr_apt)
        for glennr_apt in ${glennr_apt_pid_list[@]}; do
          kill -9 $glennr_apt 2> /dev/null
        done;
        rm -rf /tmp/glennr_apt 2> /dev/null
        rm -rf /var/lib/apt/lists/lock 2> /dev/null
        rm -rf /var/cache/apt/archives/lock 2> /dev/null
        rm -rf /var/lib/dpkg/lock* 2> /dev/null
        dpkg --configure -a 2> /dev/null
        apt-get check >/dev/null 2>&1
        if [ "$?" -ne 0 ]; then
          apt-get install --fix-broken -y 2> /dev/null
        fi
        clear
        clear
      fi
    fi
    dpkg -i /dev/null 2> /tmp/glennr_dpkg_lock; if grep -q "locked.* another" /tmp/glennr_dpkg_lock; then dpkg_locked=true; rm -rf /tmp/glennr_dpkg_lock 2> /dev/null; fi
  done;
  rm -rf /tmp/glennr_dpkg_lock 2> /dev/null
fi

script_online_version_dots=$(curl https://get.glennr.nl/unifi/install/unifi-5.12.35.sh -s | grep "# Version" | head -n 1 | awk '{print $4}')
script_local_version_dots=$(grep "# Version" $0 | head -n 1 | awk '{print $4}')
script_online_version=$(echo "${script_online_version_dots}" | sed 's/\.//g')
script_local_version=$(echo "${script_local_version_dots}" | sed 's/\.//g')

# Script version check.
if [[ ${script_online_version::3} -gt ${script_local_version::3} ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} You're currently running script version ${script_local_version_dots} while ${script_online_version_dots} is the latest!"
  echo -e "${WHITE_R}#${RESET} Downloading and executing version ${script_online_version_dots} of the Easy Installation Script.."
  echo ""
  echo ""
  sleep 3
  rm -rf $0 2> /dev/null
  rm -rf unifi-5.12.35.sh 2> /dev/null
  wget https://get.glennr.nl/unifi/install/unifi-5.12.35.sh; chmod +x unifi-5.12.35.sh; ./unifi-5.12.35.sh; exit 0
fi

armhf_recommendation() {
  print_architecture=$(dpkg --print-architecture)
  check_cloudkey=$(uname -a | awk '{print $2}')
  if [[ $print_architecture == 'armhf' && $check_cloudkey != "UniFi-CloudKey" ]]; then
    clear
    header_red
    echo -e "${WHITE_R}#${RESET} Your installation might fail, please consider getting a Cloud Key Gen2 or go with a VPS at OVH/DO/AWS."
    if [[ $os_codename =~ (precise|trusty|xenial|bionic|cosmic|disco|eoan) ]]; then
      echo -e "${WHITE_R}#${RESET} You could try using Debian Stretch before going with a UCK G2 ( PLUS ) or VPS"
    fi
    echo ""
    echo -e "${WHITE_R}#${RESET} UniFi Cloud Key Gen2       | https://store.ui.com/products/unifi-cloud-key-gen2"
    echo -e "${WHITE_R}#${RESET} UniFi Cloud Key Gen2 Plus  | https://store.ui.com/products/unifi-cloudkey-gen2-plus"
    echo ""
    echo ""
    sleep 20
  fi
}

armhf_recommendation

if uname -a | awk '{print $2}' | grep -iq 'cloudkey\|uck'; then
  eus_dir='/srv/EUS'
else
  eus_dir='/usr/lib/EUS'
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                        Required Packages                                                                                        #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

# Install needed packages if not installed
clear
header
echo -e "${WHITE_R}#${RESET} Checking if all required packages are installed!"
echo ""
echo ""
apt-get update
if [ $(dpkg-query -W -f='${Status}' sudo 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install sudo -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial-security main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install psmisc -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' lsb-release 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install lsb-release -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu trusty main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu trusty main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "eoan" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install lsb-release -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' net-tools 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install net-tools -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install net-tools -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' apt-transport-https 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install apt-transport-https -y
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
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "eoan" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu eoan main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install apt-transport-https -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' software-properties-common 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install software-properties-common -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu precise-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu precise-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install software-properties-common -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
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
if [ $(dpkg-query -W -f='${Status}' dirmngr 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install dirmngr -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu xenial-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu xenial-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu bionic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu cosmic-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu cosmic-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu disco-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu disco-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "eoan" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu eoan-security main") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu eoan-security main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ eoan main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ eoan main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (stretch|continuum) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abor
      fi
    elif [[ $os_codename == "buster" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ buster main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "bullseye" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian/ bullseye main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian/ bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    fi
    apt-get update
    apt-get install dirmngr -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' wget 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install wget -y
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
    apt-get install wget -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' netcat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install netcat -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "eoan" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ eoan universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ eoan universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install netcat -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' haveged 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install haveged -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ trusty universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ trusty universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ xenial universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ xenial universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ bionic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ bionic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ cosmic universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ cosmic universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "disco" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ disco universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ disco universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "eoan" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ eoan universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ eoan universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "jessie" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install haveged -y || abort
  fi
fi
if [ $(dpkg-query -W -f='${Status}' psmisc 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
  apt-get install psmisc -y
  if [[ $? > 0 ]]; then
    if [[ $os_codename =~ (precise|maya) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu/ precise-updates main restricted") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu/ precise-updates main restricted >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu trusty main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
      fi
    elif [[ $os_codename == "cosmic" ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
     if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
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
    apt-get install psmisc -y || abort
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                            Variables                                                                                            #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

MONGODB_ORG_SERVER=$(dpkg -l | grep "^ii" | grep "mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_MONGOS=$(dpkg -l | grep "^ii" | grep "mongodb-org-mongos" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_SHELL=$(dpkg -l | grep "^ii" | grep "mongodb-org-shell" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORG_TOOLS=$(dpkg -l | grep "^ii" | grep "mongodb-org-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_ORGN=$(dpkg -l | grep "^ii" | grep "mongodb-org" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER=$(dpkg -l | grep "^ii" | grep "mongodb-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_CLIENTS=$(dpkg -l | grep "^ii" | grep "mongodb-clients" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGODB_SERVER_CORE=$(dpkg -l | grep "^ii" | grep "mongodb-server-core" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
MONGO_TOOLS=$(dpkg -l | grep "^ii" | grep "mongo-tools" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//g')
#
system_memory=$(awk '/MemTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
system_swap=$(awk '/SwapTotal/ {printf( "%.0f\n", $2 / 1024 / 1024)}' /proc/meminfo)
#system_free_disk_space=$(df -h / | grep "/" | awk '{print $4}' | sed 's/G//')
system_free_disk_space=$(df -k / | awk '{print $4}' | tail -n1)
#
#SERVER_IP=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
#SERVER_IP=$(/sbin/ifconfig | grep 'inet ' | grep -v '127.0.0.1' | head -n1 | awk '{print $2}' | head -1 | sed 's/.*://')
SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
PUBLIC_SERVER_IP=$(curl https://ip.glennr.nl/ -s)
ARCHITECTURE=$(dpkg --print-architecture)
os_codename=$(lsb_release -cs | tr A-Z a-z)
if [[ $os_codename == 'n/a' ]]; then
  os_codename=$(lsb_release -is | tr A-Z a-z)
  if [[ $os_codename == 'parrot' ]]; then
    os_codename='buster'
  fi
fi
#
#JAVA8=$(dpkg -l | grep -c "openjdk-8-jre-headless\|oracle-java8-installer")
mongodb_server_installed=$(dpkg -l | grep "^ii" | grep -c "mongodb-server\|mongodb-org-server")
mongodb_version=$(dpkg -l | grep "mongodb-server\|mongodb-org-server" | awk '{print $3}' | sed 's/.*://' | sed 's/-.*//' | sed 's/\.//g')

# JAVA Check
java_v8=$(dpkg -l | grep "^ii" | grep -c "openjdk-8\|oracle-java8")
java_v9=$(dpkg -l | grep "^ii" | grep -c "openjdk-9\|oracle-java9")
java_v10=$(dpkg -l | grep "^ii" | grep -c "openjdk-10\|oracle-java10")
java_v11=$(dpkg -l | grep "^ii" | grep -c "openjdk-11\|oracle-java11")
java_v12=$(dpkg -l | grep "^ii" | grep -c "openjdk-12\|oracle-java12")
java_v13=$(dpkg -l | grep "^ii" | grep -c "openjdk-13\|oracle-java13")

unsupported_java_installed=''
openjdk_8_installed=''
remote_controller=''
debian_64_mongo=''
openjdk_repo=''
debian_32_run_fix=''
unifi_dependencies=''
mongodb_key_fail=''
port_8080_in_use=''
port_8080_pid=''
port_8080_service=''
port_8443_in_use=''
port_8443_pid=''
port_8443_service=''

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                             Checks                                                                                              #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

if [ $system_free_disk_space -lt "5000000" ]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} Free disk space is below 5GB.. Please expand the disk size!"
  echo -e "${WHITE_R}#${RESET} I recommend expanding to atleast 10GB"
  echo ""
  echo ""
  if [[ $script_option_skip != 'true' ]]; then
    read -p "Do you want to proceed at your own risk? (Y/n)" yes_no
    case "$yes_no" in
        [Yy]*|"") ;;
        [Nn]*) cancel_script;;
    esac
  else
    cancel_script
  fi
fi


# MongoDB version check.
if [[ $MONGODB_ORG_SERVER > "3.4.999" || $MONGODB_ORG_MONGOS > "3.4.999" || $MONGODB_ORG_SHELL > "3.4.999" || $MONGODB_ORG_TOOLS > "3.4.999" || $MONGODB_ORG > "3.4.999" || $MONGODB_SERVER > "3.4.999" || $MONGODB_CLIENTS > "3.4.999" || $MONGODB_SERVER_CORE > "3.4.999" || $MONGO_TOOLS > "3.4.999" ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} UniFi does not support MongoDB 3.6 or newer.."
  echo -e "${WHITE_R}#${RESET} Do you want to uninstall the unsupported MongoDB version?"
  echo ""
  echo -e "${WHITE_R}#${RESET} This will also uninstall any other package depending on MongoDB!"
  echo -e "${WHITE_R}#${RESET} I highly recommend creating a backup/snapshot of your machine/VM"
  echo ""
  echo ""
  echo ""
  read -p "Do you want to proceed with uninstalling MongoDB? (Y/n)" yes_no
  case "$yes_no" in
      [Yy]*|"")
        clear
        header
        echo -e "${WHITE_R}#${RESET} Uninstalling MongoDB!"
        if [ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          echo -e "${WHITE_R}#${RESET} Removing UniFi to keep system files!"
        fi
        if [ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          echo -e "${WHITE_R}#${RESET} Removing UniFi-Video to keep system files!"
        fi
        echo ""
        echo ""
        echo ""
        sleep 3
        rm /etc/apt/sources.list.d/mongo*.list
        if [ $(dpkg-query -W -f='${Status}' unifi 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          dpkg --remove --force-remove-reinstreq unifi || abort
        fi
        if [ $(dpkg-query -W -f='${Status}' unifi-video 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
          dpkg --remove --force-remove-reinstreq unifi-video || abort
        fi
        apt-get purge mongo* -y
        if [[ $? > 0 ]]; then
          clear
          header_red
          echo -e "${WHITE_R}#${RESET} Failed to uninstall MongoDB!"
          echo -e "${WHITE_R}#${RESET} Uninstalling MongoDB with different actions!"
          echo ""
          echo ""
          echo ""
          sleep 2
          apt-get --fix-broken install -y || apt-get install -f -y
          apt-get autoremove -y
          if [ $(dpkg-query -W -f='${Status}' mongodb-org 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-tools 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-tools || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-server || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-mongos 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-mongos || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-org-shell 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-org-shell || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-server 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-server || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-clients 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-clients || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongodb-server-core 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongodb-server-core || abort
          fi
          if [ $(dpkg-query -W -f='${Status}' mongo-tools 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
            dpkg --remove --force-remove-reinstreq mongo-tools || abort
          fi
        fi
        apt-get autoremove -y || abort
        apt-get clean -y || abort;;
      [Nn]*) cancel_script;;
  esac
fi

# Memory and Swap file.
if [[ ${system_swap} == "0" && ${system_memory} -lt "2" ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} System memory is lower than recommended!"
  echo -e "${WHITE_R}#${RESET} Creating swap file."
  echo ""
  echo ""
  sleep 2
  if [[ ${system_free_disk_space} -ge "10000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} You have more than 10GB of free disk space!"
    echo -e "${WHITE_R}#${RESET} We are creating a 2GB swap file!"
    echo ""
    dd if=/dev/zero of=/swapfile bs=2048 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ ${system_free_disk_space} -ge "5000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} You have more than 5GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 1GB swap file.."
    echo ""
    dd if=/dev/zero of=/swapfile bs=1024 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ ${system_free_disk_space} -ge "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} You have more than 4GB of free disk space."
    echo -e "${WHITE_R}#${RESET} We are creating a 256MB swap file.."
    echo ""
    dd if=/dev/zero of=/swapfile bs=256 count=1048576 &>/dev/null
    chmod 600 /swapfile &>/dev/null
    mkswap /swapfile &>/dev/null
    swapon /swapfile &>/dev/null
    echo "/swapfile swap swap defaults 0 0" | tee -a /etc/fstab &>/dev/null
  elif [[ ${system_free_disk_space} -lt "4000000" ]]; then
    echo -e "${WHITE_R}---${RESET}"
    echo ""
    echo -e "${WHITE_R}#${RESET} Your free disk space is extremely low!"
    echo -e "${WHITE_R}#${RESET} There is not enough free disk space to create a swap file.."
    echo ""
    echo -e "${WHITE_R}#${RESET} I highly recommend upgrading the system memory to atleast 2GB and expanding the disk space!"
    echo -e "${WHITE_R}#${RESET} The script will continue the script at your own risk.."
    echo ""
   sleep 10
  fi
else
  clear
  header
  echo -e "${WHITE_R}#${RESET} A swap file already exists!"
  echo ""
  echo ""
  sleep 2
fi

if netstat -lnp | grep -q ':8080\b'; then
  port_8080_pid=`netstat -lnp | grep ':8080\b' | awk '{print $7}' | sed 's/[/].*//g'`
  port_8080_service=`netstat -lnp | grep ':8080\b' | awk '{print $7}' | sed 's/[0-9/]//g'`
  if [[ $(ls -l /proc/${port_8080_pid}/exe | awk '{print $3}') != "unifi" ]]; then
    port_8080_in_use=true
  fi
fi
if netstat -lnp | grep -q ':8443\b'; then
  port_8443_pid=`netstat -lnp | grep ':8443\b' | awk '{print $7}' | sed 's/[/].*//g'`
  port_8443_service=`netstat -lnp | grep ':8443\b' | awk '{print $7}' | sed 's/[0-9/]//g'`
  if [[ $(ls -l /proc/${port_8443_pid}/exe | awk '{print $3}') != "unifi" ]]; then
    port_8443_in_use=true
  fi
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                  Ask to keep script or delete                                                                                   #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

script_removal() {
  header
  read -p $'\033[39m#\033[0m Do you want to keep the script on your system after completion? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"") ;;
      [Nn]*) delete_script=true;;
  esac
}

if [[ $script_option_skip != 'true' ]]; then
  script_removal
fi

###################################################################################################################################################################################################
#                                                                                                                                                                                                 #
#                                                                                 Installation Script starts here                                                                                 #
#                                                                                                                                                                                                 #
###################################################################################################################################################################################################

apt_mongodb_check() {
  apt-get update
  MONGODB_ORG_CACHE=$(apt-cache madison mongodb-org | awk '{print $3}' | sort -V | tail -n 1 | sed 's/\.//g')
  MONGODB_CACHE=$(apt-cache madison mongodb | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
  MONGO_TOOLS_CACHE=$(apt-cache madison mongo-tools | awk '{print $3}' | sort -V | tail -n 1 | sed 's/-.*//' | sed 's/.*://' | sed 's/\.//g')
}

set_hold_mongodb_org=''
set_hold_mongodb=''
set_hold_mongo_tools=''

clear
header
echo -e "${WHITE_R}#${RESET} Getting the latest patches for your machine!"
echo ""
echo ""
echo ""
sleep 2
apt_mongodb_check
if [[ ${MONGODB_ORG_CACHE::2} -gt "34" ]]; then
  if [ $(dpkg --get-selections | grep "mongodb-org" | awk '{print $2}' | grep -c "install") -ne 0 ]; then
    echo "mongodb-org hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-mongos hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-server hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-shell hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-org-tools hold" | dpkg --set-selections 2> /dev/null || abort
    set_hold_mongodb_org=true
  fi
fi
if [[ ${MONGODB_CACHE::2} -gt "34" ]]; then
  if [ $(dpkg --get-selections | grep "mongodb-server" | awk '{print $2}' | grep -c "install") -ne 0 ]; then
    echo "mongodb hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-server hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-server-core hold" | dpkg --set-selections 2> /dev/null || abort
    echo "mongodb-clients hold" | dpkg --set-selections 2> /dev/null || abort
    set_hold_mongodb=true
  fi
fi
if [[ ${MONGO_TOOLS_CACHE::2} -gt "34" ]]; then
  if [ $(dpkg --get-selections | grep "mongo-tools" | awk '{print $2}' | grep -c "install") -ne 0 ]; then
    echo "mongo-tools hold" | dpkg --set-selections 2> /dev/null || abort
    set_hold_mongo_tools=true
  fi
fi
apt-get update
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' upgrade || abort
DEBIAN_FRONTEND='noninteractive' apt-get -y -o Dpkg::Options::='--force-confdef' -o Dpkg::Options::='--force-confold' dist-upgrade || abort
apt-get autoremove -y || abort
apt-get autoclean -y || abort
if [[ $set_hold_mongodb_org == 'true' ]]; then
  echo "mongodb-org install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-mongos install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-server install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-shell install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-org-tools install" | dpkg --set-selections 2> /dev/null || abort
fi
if [[ $set_hold_mongodb == 'true' ]]; then
  echo "mongodb install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-server install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-server-core install" | dpkg --set-selections 2> /dev/null || abort
  echo "mongodb-clients install" | dpkg --set-selections 2> /dev/null || abort
fi
if [[ $set_hold_mongo_tools == 'true' ]]; then
  echo "mongo-tools install" | dpkg --set-selections 2> /dev/null || abort
fi

# MongoDB check
mongodb_server_installed=$(dpkg -l | grep "^ii" | grep -c "mongodb-server\|mongodb-org-server")

ubuntu_32_mongo() {
  clear
  header
  echo -e "${WHITE_R}#${RESET} 32 bit system detected!"
  echo -e "${WHITE_R}#${RESET} Installing MongoDB for 32 bit systems!"
  echo ""
  echo ""
  echo ""
  sleep 2
}

debian_32_mongo() {
  debian_32_run_fix=true
  clear
  header
  echo -e "${WHITE_R}#${RESET} 32 bit system detected!"
  echo -e "${WHITE_R}#${RESET} Skipping MongoDB installation!"
  echo ""
  echo ""
  echo ""
  sleep 2
}

mongodb_26_key() {
  if [ ! -z "$http_proxy" ]; then
    http_proxy_found
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys 7F0CEB10 || mongodb_key_fail=true
  elif [ -f /etc/apt/apt.conf ]; then
    apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
    if [[ apt_http_proxy ]]; then
      http_proxy_found
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 7F0CEB10 || mongodb_key_fail=true
    fi
  else
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 7F0CEB10 || mongodb_key_fail=true
  fi
  if [[ $mongodb_key_fail == "true" ]]; then
    wget -qO - https://www.mongodb.org/static/pgp/server-2.6.asc | apt-key add - || abort
  fi
}

mongodb_34_key() {
  if [ ! -z "$http_proxy" ]; then
    http_proxy_found
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys 0C49F3730359A14518585931BC711F9BA15703C6 || mongodb_key_fail=true
  elif [ -f /etc/apt/apt.conf ]; then
    apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
    if [[ apt_http_proxy ]]; then
      http_proxy_found
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 0C49F3730359A14518585931BC711F9BA15703C6 || mongodb_key_fail=true
    fi
  else
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 0C49F3730359A14518585931BC711F9BA15703C6 || mongodb_key_fail=true
  fi
  if [[ $mongodb_key_fail == "true" ]]; then
    wget -qO - https://www.mongodb.org/static/pgp/server-3.4.asc | apt-key add - || abort
  fi
}

if [[ $os_codename =~ (disco|eoan) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Installing a required package.."
  echo ""
  echo ""
  echo ""
  sleep 2
  libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
  if [[ $ARCHITECTURE == "amd64" ]]; then
    wget -O "$libssl_temp" 'http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb' || abort
  fi
  if [[ $ARCHITECTURE == "arm64" ]]; then
    wget -O "$libssl_temp" 'https://launchpad.net/ubuntu/+source/openssl1.0/1.0.2n-1ubuntu5/+build/14503127/+files/libssl1.0.0_1.0.2n-1ubuntu5_arm64.deb' || abort
  fi
  dpkg -i "$libssl_temp"
  rm -rf "$libssl_temp" 2> /dev/null
fi

clear
header
echo -e "${WHITE_R}#${RESET} The latest patches are installed on your system!"
echo -e "${WHITE_R}#${RESET} Installing MongoDB..."
echo ""
echo ""
echo ""
sleep 2
if ! [[ $mongodb_server_installed -eq 1 ]]; then
  if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "mongodb.org") -gt 0 ]]; then
    get_repo_lists=`grep -riIl "mongodb.org" /etc/apt/ >> /tmp/EIS_mongodb_repositories`
    repo_lists=$(tr '\r\n' ' ' < /tmp/EIS_mongodb_repositories)
    for EIS_repositories in ${repo_lists[@]}; do
      sed -i '/mongodb.org/d' ${EIS_repositories} 2> /dev/null
      if ! [[ -s ${EIS_repositories} ]]; then
        rm -rf ${EIS_repositories} 2> /dev/null
      fi
    done;
    rm -rf /tmp/EIS_mongodb_repositories 2> /dev/null
  fi
  if [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia) && ! $ARCHITECTURE =~ (amd64|arm64) ]]; then
    ubuntu_32_mongo
    #mongodb_26_key
    apt-get install -y mongodb-server mongodb-clients
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        apt-get update
      fi
      apt-get install -y mongodb-server mongodb-clients || apt-get install -f && apt-get install -y mongodb-server mongodb-clients || abort
    fi
  elif [[ $os_codename =~ (bionic|tara|tessa|tina|disco|eoan) && $ARCHITECTURE == "i386" ]]; then
    ubuntu_32_mongo
    libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
    wget -O "$libssl_temp" 'http://ftp.nl.debian.org/debian/pool/main/o/openssl1.0/libssl1.0.2_1.0.2s-1~deb9u1_i386.deb' || abort
    dpkg -i "$libssl_temp"
    rm -rf "$libssl_temp" 2> /dev/null
    if [[ $os_codename =~ (disco|eoan) ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
        echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        apt-get update
      fi
    fi
    apt-get install -y libboost-chrono1.62.0 libboost-filesystem1.62.0 libboost-program-options1.62.0 libboost-regex1.62.0 libboost-system1.62.0 libboost-thread1.62.0 libgoogle-perftools4 libpcap0.8 libpcrecpp0v5 libsnappy1v5 libstemmer0d libyaml-cpp0.5v5
    mongo_tools_temp="$(mktemp --tmpdir=/tmp mongo_tools-3.2.22_XXXXX.deb)" || abort
    wget -O "$mongo_tools_temp" 'http://ftp.nl.debian.org/debian/pool/main/m/mongo-tools/mongo-tools_3.2.11-1+b2_i386.deb' || abort
    dpkg -i "$mongo_tools_temp"
    rm -rf "$mongo_tools_temp" 2> /dev/null
    mongodb_clients_temp="$(mktemp --tmpdir=/tmp mongodb_clients-3.2.22_XXXXX.deb)" || abort
    wget -O "$mongodb_clients_temp" 'http://ftp.nl.debian.org/debian/pool/main/m/mongodb/mongodb-clients_3.2.11-2+deb9u1_i386.deb' || abort
    dpkg -i "$mongodb_clients_temp"
    rm -rf "$mongodb_clients_temp" 2> /dev/null
    mongodb_server_temp="$(mktemp --tmpdir=/tmp mongodb_clients-3.2.22_XXXXX.deb)" || abort
    wget -O "$mongodb_server_temp" 'http://ftp.nl.debian.org/debian/pool/main/m/mongodb/mongodb-server_3.2.11-2+deb9u1_i386.deb' || abort
    dpkg -i "$mongodb_server_temp"
    rm -rf "$mongodb_server_temp" 2> /dev/null
  elif [[ $os_codename =~ (precise|maya) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu precise/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64 ] https://repo.mongodb.org/apt/ubuntu trusty/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (xenial|bionic|cosmic|disco|eoan|sarah|serena|sonya|sylvia|tara|tessa|tina) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
    mongodb_34_key
    echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
    apt-get update
    apt-get install -y mongodb-org || abort
  elif [[ $os_codename =~ (jessie|stretch|continuum|buster|bullseye) ]]; then
    if [[ ! $ARCHITECTURE =~ (amd64|arm64) ]]; then
      debian_32_mongo
    fi
    if [[ $os_codename == "jessie" && $ARCHITECTURE =~ (amd64|arm64) ]]; then
      echo "deb https://repo.mongodb.org/apt/debian jessie/mongodb-org/3.4 main" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
      debian_64_mongo=install
    elif [[ $os_codename =~ (stretch|continuum|buster|bullseye) && $ARCHITECTURE =~ (amd64|arm64) ]]; then
      echo "deb [ arch=amd64,arm64 ] https://repo.mongodb.org/apt/ubuntu xenial/mongodb-org/3.4 multiverse" | tee /etc/apt/sources.list.d/mongodb-org-3.4.list || abort
      libssl_temp="$(mktemp --tmpdir=/tmp libssl1.0.2_XXXXX.deb)" || abort
      if [[ $ARCHITECTURE == "amd64" ]]; then
        wget -O "$libssl_temp" 'http://security.ubuntu.com/ubuntu/pool/main/o/openssl1.0/libssl1.0.0_1.0.2n-1ubuntu5.3_amd64.deb' || abort
      fi
      if [[ $ARCHITECTURE == "arm64" ]]; then
        wget -O "$libssl_temp" 'https://launchpad.net/ubuntu/+source/openssl1.0/1.0.2n-1ubuntu5/+build/14503127/+files/libssl1.0.0_1.0.2n-1ubuntu5_arm64.deb' || abort
      fi
      dpkg -i "$libssl_temp"
      rm -rf "$libssl_temp" 2> /dev/null
      debian_64_mongo=install
    fi
    if [ $debian_64_mongo == 'install' ]; then
      mongodb_34_key
      apt-get update
      apt-get install -y mongodb-org || abort
    fi
  else
    header_red
    echo -e "${RED}#${RESET} The script is unable to grab your OS ( or does not support it )"
    echo "${ARCHITECTURE}"
    echo "${os_codename}"
    abort
  fi
else
  clear
  header
  echo -e "${WHITE_R}#${RESET} MongoDB is already installed..."
  echo ""
  echo ""
  echo ""
  sleep 2
fi

if [[ $architecture == "armhf" ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Trying to use raspbian repo to install MongoDB..."
  echo ""
  echo ""
  echo 'deb http://archive.raspbian.org/raspbian stretch main contrib non-free rpi' | tee /etc/apt/sources.list.d/glennr_armhf.list
  wget https://archive.raspbian.org/raspbian.public.key -O - | apt-key add -
  apt-get update
  apt-get install -y mongodb-server mongodb-clients || apt-get install -f || abort
  if ! dpkg -l | grep "^ii" | grep "mongodb-server"; then
    echo -e "${RED}#${RESET} mongodb-server failed to install.." && abort
  fi
  if ! dpkg -l | grep "^ii" | grep "mongodb-clients"; then
    echo -e "${RED}#${RESET} mongodb-clients failed to install.." && abort
  fi
fi

clear
header
echo -e "${WHITE_R}#${RESET} MongoDB has been installed successfully!"
echo -e "${WHITE_R}#${RESET} Installing OpenJDK 8..."
echo ""
echo ""
echo ""
sleep 2
openjdk_version=$(dpkg -l | grep "^ii" | grep "openjdk-8" | awk '{print $3}' | grep "^8u" | sed 's/-.*//g' | sed 's/8u//g' | sort -V | tail -n 1)
if [[ ${openjdk_version} -lt 131 ]]; then
  old_openjdk_version=true
fi
if ! dpkg -l | grep "^ii" | grep -iq "openjdk-8" || [[ ${old_openjdk_version} == 'true' ]]; then
  if [[ $os_codename =~ (precise|maya) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu precise main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu precise main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu trusty main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* xenial main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* bionic main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu bionic main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename == "cosmic" ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* cosmic main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu cosmic main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (disco|eoan) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://security.ubuntu.com/ubuntu[/]* bionic-security main universe") -eq 0 ]]; then
        echo deb http://security.ubuntu.com/ubuntu bionic-security main universe >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename == "jessie" ]]; then
    apt-get install -t jessie-backports openjdk-8-jre-headless ca-certificates-java -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://archive.debian.org/debian[/]* jessie-backports main") -eq 0 ]]; then
        echo deb http://archive.debian.org/debian jessie-backports main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
        apt-get update -o Acquire::Check-Valid-Until=false
        apt-get install -t jessie-backports openjdk-8-jre-headless ca-certificates-java -y || abort
        sed -i '/jessie-backports/d' /etc/apt/sources.list.d/glennr-install-script.list
      fi
    fi
  elif [[ $os_codename =~ (stretch|continuum) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ppa.launchpad.net/openjdk-r/ppa/ubuntu[/]* xenial main") -eq 0 ]]; then
        echo deb http://ppa.launchpad.net/openjdk-r/ppa/ubuntu xenial main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  elif [[ $os_codename =~ (buster|bullseye) ]]; then
    apt-get install openjdk-8-jre-headless -y
    if [[ $? > 0 ]]; then
      if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -c "^deb http[s]*://ftp.nl.debian.org/debian[/]* stretch main") -eq 0 ]]; then
        echo deb http://ftp.nl.debian.org/debian stretch main >> /etc/apt/sources.list.d/glennr-install-script.list || abort
        openjdk_repo=true
      fi
    fi
  else
    header_red
    echo -e "${RED}#${RESET} The script is unable to grab your OS ( or does not support it )"
    echo "${ARCHITECTURE}"
    echo "${os_codename}"
    abort
  fi
  if [[ $openjdk_repo == 'true' ]]; then
    if [ ! -z "$http_proxy" ]; then
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys EB9B1D8886F44E2A || abort
    elif [ -f /etc/apt/apt.conf ]; then
      apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
      if [[ apt_http_proxy ]]; then
        apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys EB9B1D8886F44E2A || abort
      fi
    else
      apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv EB9B1D8886F44E2A || abort
    fi
    openjdk_installed=true
  fi
  apt-get update
  apt-get install openjdk-8-jre-headless -y || abort
else
  clear
  header
  echo -e "${WHITE_R}#${RESET} OpenJDK/Oracle JAVA 8 is already installed..."
  echo ""
  echo ""
  echo ""
  sleep 2
fi

if dpkg -l | grep "^ii" | grep -iq "openjdk-8"; then
  openjdk_8_installed=true
fi
if dpkg -l | grep "^ii" | grep -i "openjdk-.*-\|oracle-java.*" | grep -vq "openjdk-8\|oracle-java8"; then
  unsupported_java_installed=true
fi

if [[ ${openjdk_8_installed} == 'true' && ${unsupported_java_installed} == 'true' && ${script_option_skip} != 'true' ]]; then
  clear
  header_red
  echo -e "${WHITE_R}#${RESET} Unsupported JAVA version(s) are detected, do you want to uninstall them?"
  echo -e "${WHITE_R}#${RESET} This may remove packages that depend on these java versions."
  read -p $'\033[39m#\033[0m Do you want to proceed with uninstalling the unsupported JAVA version(s)? (y/N) ' yes_no
  case "$yes_no" in
       [Yy]*)
          rm -rf /tmp/EUS/java/* &> /dev/null
          mkdir -p /tmp/EUS/java/ &> /dev/null
          mkdir -p ${eus_dir}/logs/ &> /dev/null
          if [[ -f ${eus_dir}/logs/java_uninstall.log ]]; then
            java_uninstall_log_size=$(du -sc ${eus_dir}/logs/java_uninstall.log | grep total$ | awk '{print $1}')
            if [[ ${java_uninstall_log_size} -gt '50' ]]; then
              tail -n100 ${eus_dir}/logs/java_uninstall.log &> ${eus_dir}/logs/java_uninstall_tmp.log
              cp ${eus_dir}/logs/java_uninstall_tmp.log ${eus_dir}/logs/java_uninstall.log; rm -rf ${eus_dir}/logs/java_uninstall_tmp.log &> /dev/null
            fi
          fi
          clear
          header
          echo -e "${WHITE_R}#${RESET} Uninstalling unsupported JAVA versions..."
          echo -e "\n${WHITE_R}----${RESET}\n"
          sleep 3
          dpkg -l | grep "^ii" | awk '/openjdk-.*/{print $2}' | cut -d':' -f1 | grep -v "openjdk-8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          dpkg -l | grep "^ii" | awk '/oracle-java.*/{print $2}' | cut -d':' -f1 | grep -v "oracle-java8" &>> /tmp/EUS/java/unsupported_java_list_tmp
          awk '!a[$0]++' /tmp/EUS/java/unsupported_java_list_tmp >> /tmp/EUS/java/unsupported_java_list; rm -rf /tmp/EUS/java/unsupported_java_list_tmp 2> /dev/null
          echo -e "\n------- $(date +%F-%R) -------\n" &>> ${eus_dir}/logs/java_uninstall.log
          unsupported_java_list=$(tr '\r\n' ' ' < /tmp/EUS/java/unsupported_java_list)
          for package in ${unsupported_java_list[@]}; do
            apt-get remove ${package} -y &>> ${eus_dir}/logs/java_uninstall.log && echo -e "${WHITE_R}#${RESET} Successfully removed ${package}." || echo -e "${WHITE_R}#${RESET} Failed to remove ${package}."
          done
          rm -rf /tmp/EUS/java/unsupported_java_list &> /dev/null
          echo -e "\n";;
       [Nn]*|"") ;;
  esac
fi

if dpkg -l | grep "^ii" | grep -iq "openjdk-8"; then
  update_java_alternatives=$(update-java-alternatives --list | grep "^java-1.8.*openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_java_alternatives}" ]]; then
    update-java-alternatives --set ${update_java_alternatives} &> /dev/null
  fi
  update_alternatives=$(update-alternatives --list java | grep "java-8-openjdk" | awk '{print $1}' | head -n1)
  if [[ -n "${update_alternatives}" ]]; then
    update-alternatives --set java ${update_alternatives} &> /dev/null
  fi
  clear
  header
  echo -e "${WHITE_R}#${RESET} Updating ca-certificates..\n" && sleep 2
  rm /etc/ssl/certs/java/cacerts 2> /dev/null
  update-ca-certificates -f 2> /dev/null
fi

if dpkg -l | grep "^ii" | grep -iq "openjdk-8"; then
  java_home_readlink=$(echo "JAVA_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"")
  if [[ -f /etc/default/unifi ]]; then
    current_java_home=$(grep "^JAVA_HOME" /etc/default/unifi)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ ${current_java_home} != ${java_home_readlink} ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/default/unifi
        echo ${java_home_readlink} >> /etc/default/unifi
      fi
    fi
  else
    current_java_home=$(grep "^JAVA_HOME" /etc/environment)
    if [[ -n "${java_home_readlink}" ]]; then
      if [[ ${current_java_home} != ${java_home_readlink} ]]; then
        sed -i 's/^JAVA_HOME/#JAVA_HOME/' /etc/environment
        echo "JAVA_HOME="$( readlink -f "$( which java )" | sed "s:bin/.*$::" )"" >> /etc/environment
        source /etc/environment
      fi
    fi
  fi
fi

clear
header
echo -e "${WHITE_R}#${RESET} OpenJDK 8 has been installed successfully!"
echo -e "${WHITE_R}#${RESET} Installing UniFi Dependencies..."
echo ""
echo ""
echo ""
sleep 2
apt-get update
if [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa|xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|cosmic|disco|eoan|stretch|continuum|buster|bullseye) ]]; then
  apt-get install binutils ca-certificates-java java-common -y || unifi_dependencies=fail
  apt-get install jsvc libcommons-daemon-java -y || unifi_dependencies=fail
elif [[ $os_codename == 'jessie' ]]; then
  apt-get install binutils ca-certificates-java java-common -y --force-yes || unifi_dependencies=fail
  apt-get install jsvc libcommons-daemon-java -y --force-yes || unifi_dependencies=fail
fi
if [[ $unifi_dependencies == 'fail' ]]; then
  if [[ $os_codename =~ (precise|maya) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu precise main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu precise main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (trusty|qiana|rebecca|rafaela|rosa) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu trusty main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu trusty main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu xenial main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu xenial main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (bionic|tara|tessa|tina) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu bionic main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu bionic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "cosmic" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu cosmic main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu cosmic main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "disco" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu disco main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu disco main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "eoan" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://[A-Za-z0-9]*.archive.ubuntu.com/ubuntu eoan main universe") -eq 0 ]]; then
      echo deb http://nl.archive.ubuntu.com/ubuntu eoan main universe >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "jessie" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian jessie main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian jessie main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename =~ (stretch|continuum) ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian stretch main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian stretch main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "buster" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian buster main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian buster main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  elif [[ $os_codename == "bullseye" ]]; then
    if [[ $(find /etc/apt/* -name *.list | xargs cat | grep -P -c "^deb http[s]*://ftp.[A-Za-z0-9]*.debian.org/debian bullseye main") -eq 0 ]]; then
      echo deb http://ftp.nl.debian.org/debian bullseye main >>/etc/apt/sources.list.d/glennr-install-script.list || abort
    fi
  fi
  if [[ $os_codename =~ (xenial|sarah|serena|sonya|sylvia|bionic|tara|tessa|tina|cosmic|disco|eoan|stretch|continuum|buster|bullseye) ]]; then
    apt-get install binutils ca-certificates-java java-common -y || abort
    apt-get install jsvc libcommons-daemon-java -y || abort
  elif [[ $os_codename == 'jessie' ]]; then
    apt-get install binutils ca-certificates-java java-common -y --force-yes || abort
    apt-get install jsvc libcommons-daemon-java -y --force-yes || abort
  fi
fi

clear
header
echo -e "${WHITE_R}#${RESET} UniFi dependencies has been installed successfully!"
echo -e "${WHITE_R}#${RESET} Installing your UniFi Network Controller ( ${WHITE_R}5.12.35${RESET} )..."
echo ""
echo ""
echo ""
sleep 2
unifi_temp="$(mktemp --tmpdir=/tmp unifi_sysvinit_all_5.12.35_XXX.deb)"
wget -O "$unifi_temp" 'https://dl.ui.com/unifi/5.12.35/unifi_sysvinit_all.deb' || abort
dpkg -i "$unifi_temp"
if [[ $debian_32_run_fix == 'true' ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Fixing broken UniFi install..."
  echo ""
  echo ""
  echo ""
  apt-get --fix-broken install -y || abort
fi
rm -rf "$unifi_temp" 2> /dev/null
service unifi start || abort

# Check if MongoDB service is enabled
if ! [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
  if [ ${MONGODB_VERSION::2} -ge '26' ]; then
    SERVICE_MONGODB=$(systemctl is-enabled mongod)
    if [ $SERVICE_MONGODB = 'disabled' ]; then
      systemctl enable mongod 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  else
    SERVICE_MONGODB=$(systemctl is-enabled mongodb)
    if [ $SERVICE_MONGODB = 'disabled' ]; then
      systemctl enable mongodb 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | MongoDB"; sleep 3; }
    fi
  fi
  # Check if UniFi service is enabled
  SERVICE_UNIFI=$(systemctl is-enabled unifi)
  if [ $SERVICE_UNIFI = 'disabled' ]; then
    systemctl enable unifi 2>/dev/null || { echo -e "${RED}#${RESET} Failed to enable service | UniFi"; sleep 3; }
  fi
fi

if [[ $script_option_skip != 'true' ]]; then
  clear
  header
  echo -e "${WHITE_R}#${RESET} Would you like to update the UniFi Network Controller via APT?"
  echo ""
  echo ""
  read -p $'\033[39m#\033[0m Do you want the script to add the source list file? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
        clear
        header
        echo -e "${WHITE_R}#${RESET} Adding source list..."
        echo ""
        echo ""
        echo ""
        sleep 3
        sed -i '/unifi/d' /etc/apt/sources.list
        rm -rf /etc/apt/sources.list.d/100-ubnt-unifi.list 2> /dev/null
        wget -O /etc/apt/trusted.gpg.d/unifi-repo.gpg https://dl.ui.com/unifi/unifi-repo.gpg
        if [[ $? > 0 ]]; then
          if [ ! -z "$http_proxy" ]; then
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${http_proxy} --recv-keys 06E85760C0A52C50 || abort
          elif [ -f /etc/apt/apt.conf ]; then
            apt_http_proxy=$(grep http.*Proxy /etc/apt/apt.conf | awk '{print $2}' | sed 's/[";]//g')
            if [[ apt_http_proxy ]]; then
              apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --keyserver-options http-proxy=${apt_http_proxy} --recv-keys 06E85760C0A52C50 || abort
            fi
          else
            apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 06E85760C0A52C50 || abort
          fi
        fi
        echo 'deb https://www.ui.com/downloads/unifi/debian unifi-5.12 ubiquiti' | tee /etc/apt/sources.list.d/100-ubnt-unifi.list
        apt-get update;;
      [Nn]*) ;;
  esac
fi

if dpkg -l ufw | grep -q "^ii"; then
  if ufw status verbose | awk '/^Status:/{print $2}' | grep -xq "active"; then
    clear
    header
    echo -e "${WHITE_R}#${RESET} Uncomplicated Firewall ( UFW ) seems to be active."
    echo -e "${WHITE_R}#${RESET} Checking if all required ports are added!"
    rm -rf /tmp/EUS/ports/* &> /dev/null
    mkdir -p /tmp/EUS/ports/ &> /dev/null
    ssh_port=$(awk '/Port/{print $2}' /etc/ssh/sshd_config | head -n1)
    unifi_ports=(3478/udp 8080/tcp 8443/tcp 8880/tcp 8843/tcp 6789/tcp)
    echo -e "3478/udp\n8080/tcp\n8443/tcp\n8880/tcp\n8843/tcp\n6789/tcp" &>> /tmp/EUS/ports/all_ports
    echo ${ssh_port} &>> /tmp/EUS/ports/all_ports
    ufw status verbose &>> /tmp/EUS/ports/ufw_list
    all_ports=$(tr '\r\n' ' ' < /tmp/EUS/ports/all_ports)
    for port in ${all_ports[@]}; do
      port_number_only=$(echo ${port} | cut -d'/' -f1)
      if ! grep "^${port_number_only}\b\|^${port}\b" /tmp/EUS/ports/ufw_list | grep -iq "ALLOW IN"; then
        required_port_missing=true
      fi
      if ! grep -v "(v6)" /tmp/EUS/ports/ufw_list | grep "^${port_number_only}\b\|^${port}\b" | grep -iq "ALLOW IN"; then
        required_port_missing=true
      fi
    done
    if [[ ${required_port_missing} == 'true' ]]; then
      echo -e "\n${WHITE_R}----${RESET}\n\n"
      echo -e "${WHITE_R}#${RESET} We are missing required ports.."
      if [[ ${script_option_skip} != 'true' ]]; then
        read -p $'\033[39m#\033[0m Do you want to add the required ports for your UniFi Network Controller? (Y/n) ' yes_no
      else
        echo -e "${WHITE_R}#${RESET} Adding required UniFi ports.."
        sleep 2
      fi
      case "${yes_no}" in
         [Yy]*|"")
            echo -e "\n${WHITE_R}----${RESET}\n\n"
            for port in ${unifi_ports[@]}; do
              port_number=$(echo ${port} | cut -d'/' -f1)
              ufw allow ${port} &> /tmp/EUS/ports/${port_number}
              if [[ -f /tmp/EUS/ports/${port_number} && -s /tmp/EUS/ports/${port_number} ]]; then
                if grep -iq "added" /tmp/EUS/ports/${port_number}; then
                  echo -e "${WHITE_R}#${RESET} Successfully added port ${port} to UFW."
                fi
                if grep -iq "skipping" /tmp/EUS/ports/${port_number}; then
                  echo -e "${WHITE_R}#${RESET} Port ${port} was already added to UFW."
                fi
              fi
            done
            if [[ -f /etc/ssh/sshd_config && -s /etc/ssh/sshd_config ]]; then
              if ! ufw status verbose | grep -v "(v6)" | grep "${ssh_port}" | grep -iq "ALLOW IN"; then
                echo -e "\n${WHITE_R}----${RESET}\n\n${WHITE_R}#${RESET} Your SSH port ( ${ssh_port} ) doesn't seem to be in your UFW list.."
                if [[ ${script_option_skip} != 'true' ]]; then
                  read -p $'\033[39m#\033[0m Do you want to add your SSH port to the UFW list? (Y/n) ' yes_no
                else
                  echo -e "${WHITE_R}#${RESET} Adding port ${ssh_port}.."
                  sleep 2
                fi
                case "${yes_no}" in
                   [Yy]*|"")
                      echo -e "\n${WHITE_R}----${RESET}\n"
                      ufw allow ${ssh_port} &> /tmp/EUS/ports/${ssh_port}
                      if [[ -f /tmp/EUS/ports/${ssh_port} && -s /tmp/EUS/ports/${ssh_port} ]]; then
                        if grep -iq "added" /tmp/EUS/ports/${ssh_port}; then
                          echo -e "${WHITE_R}#${RESET} Successfully added port ${ssh_port} to UFW."
                        fi
                        if grep -iq "skipping" /tmp/EUS/ports/${ssh_port}; then
                          echo -e "${WHITE_R}#${RESET} Port ${ssh_port} was already added to UFW."
                        fi
                      fi;;
                   [Nn]*|*) ;;
                esac
              fi
            fi;;
         [Nn]*|*) ;;
      esac
    else
      echo -e "\n${WHITE_R}----${RESET}\n\n${WHITE_R}#${RESET} All required ports already exist!"
    fi
    echo -e "\n\n" && sleep 2
  fi
fi

if [[ -z "${SERVER_IP}" ]]; then
  SERVER_IP=$(ip addr | grep -A8 -m1 MULTICAST | grep -m1 inet | cut -d' ' -f6 | cut -d'/' -f1)
fi

# Check if controller is reachable via public IP.
timeout 1 nc -zv ${PUBLIC_SERVER_IP} 8443 &> /dev/null && remote_controller=true

if [[ ${remote_controller} == 'true' && ${script_option_skip} != 'true' ]]; then
  clear
  header
  le_script=true
  echo -e "${WHITE_R}#${RESET} Your controller seems to be exposed to the internet. ( port 8443 is open )"
  echo -e "${WHITE_R}#${RESET} It's recommend to secure your controller with a SSL certficate."
  echo ""
  echo -e "${WHITE_R}#${RESET} Requirements:"
  echo -e "${WHITE_R}-${RESET} A domain name and A record pointing to the controller."
  echo -e "${WHITE_R}-${RESET} Port 80 needs to be open ( port forwarded )"
  echo ""
  echo ""
  echo ""
  read -p $'\033[39m#\033[0m Do you want to download and execute my Easy Lets Encrypt Script? (Y/n) ' yes_no
  case "$yes_no" in
      [Yy]*|"")
          rm -rf unifi-lets-encrypt.sh &> /dev/null; wget https://get.glennr.nl/unifi/extra/unifi-lets-encrypt.sh; chmod +x unifi-lets-encrypt.sh; sudo ./unifi-lets-encrypt.sh -install_script;;
      [Nn]*) ;;
  esac
fi

if dpkg -l netcat | grep -q "^ii"; then
  clear
  header
  if [[ ${script_option_skip} != 'true' ]]; then
    read -p $'\033[39m#\033[0m Would you like to uninstall netcat? (Y/n) ' yes_no
  else
    echo -e "${WHITE_R}#${RESET} Uninstalling netcat.."
  fi
  case "$yes_no" in
      [Yy]*|"")
         apt-get purge netcat -y &> /dev/null && echo -e "\n${WHITE_R}#${RESET} Successfully uninstalled netcat." || echo -e "\n${WHITE_R}#${RESET} Failed to uninstall netcat."
         sleep 2;;
      [Nn]*) ;;
  esac
fi

if dpkg -l unifi | grep -q "^ii"; then
  clear
  header
  echo ""
  echo -e "${GREEN}#${RESET} UniFi Network Controller 5.12.35 has been installed successfully"
  if [[ ${remote_controller} = 'true' ]]; then
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE_R}https://$PUBLIC_SERVER_IP:8443${RESET}"
    if [[ ${le_script} == 'true' ]]; then
      if [[ -d /usr/lib/EUS/ ]]; then
        if [[ -f /usr/lib/EUS/server_fqdn_install && -s /usr/lib/EUS/server_fqdn_install ]]; then
          controller_fqdn_le=$(cat /usr/lib/EUS/server_fqdn_install | tail -n1)
          rm -rf /usr/lib/EUS/server_fqdn_install &> /dev/null
        fi
      elif [[ -d /srv/EUS/ ]]; then
        if [[ -f /srv/EUS/server_fqdn_install && -s /srv/EUS/server_fqdn_install ]]; then
          controller_fqdn_le=$(cat /srv/EUS/server_fqdn_install | tail -n1)
          rm -rf /srv/EUS/server_fqdn_install &> /dev/null
        fi
      fi
      if [[ -n "${controller_fqdn_le}" ]]; then
        echo -e "${GREEN}#${RESET} Your controller FQDN: ${WHITE_R}https://$controller_fqdn_le:8443${RESET}"
      fi
    fi
  else
    echo -e "${GREEN}#${RESET} Your controller address: ${WHITE_R}https://$SERVER_IP:8443${RESET}"
  fi
  echo ""
  echo ""
  if [[ $os_codename =~ (precise|maya|trusty|qiana|rebecca|rafaela|rosa) ]]; then
    service unifi status | grep -q running && echo -e "${GREEN}#${RESET} UniFi is active ( running )" || echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  else
    systemctl is-active -q unifi && echo -e "${GREEN}#${RESET} UniFi is active ( running )" || echo -e "${RED}#${RESET} UniFi failed to start... Please contact Glenn R. (AmazedMender16) on the Community Forums!"
  fi
  if [[ ${port_8080_in_use} == 'true' && ${port_8443_in_use} == 'true' && ${port_8080_pid} == ${port_8443_pid} ]]; then
    echo ""
    echo -e "${RED}#${RESET} Port 8080 and 8443 is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
    echo -e "${RED}#${RESET} Disable the service that is using port 8080 and 8443 ( ${port_8080_service} ) or kill the process with the command below"
    echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}"
    echo ""
  else
    if [[ ${port_8080_in_use} == 'true' ]]; then
      echo ""
      echo -e "${RED}#${RESET} Port 8080 is already in use by another process ( PID ${port_8080_pid} ), your UniFi Network Controll will most likely not start.."
      echo -e "${RED}#${RESET} Disable the service that is using port 8080 ( ${port_8080_service} ) or kill the process with the command below"
      echo -e "${RED}#${RESET} sudo kill -9 ${port_8080_pid}"
    fi
    if [[ ${port_8443_in_use} == 'true' ]]; then
      echo ""
      echo -e "${RED}#${RESET} Port 8443 is already in use by another process ( PID ${port_8443_pid} ), your UniFi Network Controll will most likely not start.."
      echo -e "${RED}#${RESET} Disable the service that is using port 8443 ( ${port_8443_service} ) or kill the process with the command below"
      echo -e "${RED}#${RESET} sudo kill -9 ${port_8443_pid}"
    fi
    echo ""
  fi
  echo ""
  echo ""
  author
  remove_yourself
else
  clear
  header_red
  echo ""
  echo -e "${RED}#${RESET} Failed to successfully install UniFi Network Controller 5.12.35"
  echo -e "${RED}#${RESET} Please contact Glenn R. (AmazedMender16) on the Community Forums!${RESET}"
  echo ""
  echo ""
  remove_yourself
fi
