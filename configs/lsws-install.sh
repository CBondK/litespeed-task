#!/bin/bash
set -o allexport; source ../.env
SERVER_DIR='/usr/local/lsws'
[ -z "${LSWS_VER}"    ] && LSWS_VER='5.0'
[ -z "${LSWS_SUBVER}" ] && LSWS_SUBVER='5.4.9'
[ -z "${DOMAIN}"      ] && DOMAIN='localhost'
[ -z "${VH_ROOT}"     ] && VH_ROOT='/var/www/vhosts'
[ -z "${PHP_VER}"     ] && PHP_VER='lsphp73'
#####################
TMP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"



restart_srv(){
chown -R nobody:nogroup ${SERVER_DIR}/
${SERVER_DIR}/bin/lswsctrl restart
}

configure_lsws_conf(){
  #check input
  if [[ ${PHP_VER} =~ ^lsphp[5-9]{1}[3-9]{1} ]]; then
  sed -Ei "s|LSAPI_NAME|${PHP_VER}|g" ${TMP_DIR}/httpd_conf.xml
  sed -Ei "s|DOMAIN|${DOMAIN}|g" ${TMP_DIR}/httpd_conf.xml
  sed -Ei "s|VH_ROOT|${VH_ROOT}|g" ${TMP_DIR}/httpd_conf.xml
  mv ${TMP_DIR}/httpd_conf.xml  ${SERVER_DIR}/conf/httpd_config.xml
  fi
}

config_vh(){
  sed -Ei "s|DOMAIN|${DOMAIN}|g" ${TMP_DIR}/vh-conf.xml
  sed -Ei "s|VH_ROOT|${VH_ROOT}|g" ${TMP_DIR}/vh-conf.xml
  mv ${TMP_DIR}/vh-conf.xml ${SERVER_DIR}/conf/${DOMAIN}.xml
}

config_template(){
  sed -Ei "s|LSAPI_NAME|${PHP_VER}|g" ${TMP_DIR}/docker.xml
  sed -Ei "s|DOMAIN|${DOMAIN}|g" ${TMP_DIR}/docker.xml
  sed -Ei "s|VH_ROOT|${VH_ROOT}|g" ${TMP_DIR}/docker.xml
  mv ${TMP_DIR}/docker.xml ${SERVER_DIR}/conf/templates/docker.xml
}

admin_creds(){

NOCOLOR='\033[0m'
RED='\033[0;31m'
  if [ -z "${ADMIN_USER}" ]; then
    echo && echo
  	echo -e "${RED}The default admin login username was set ---> admin${NOCOLOR}"
  fi
  	if [ -z "$ADMIN_PASS" ]; then
  	       ADMIN_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
          echo && echo
          echo -e "${RED}Since the Admin pass was not pre-defined, the random one's generated ---> ${ADMIN_PASS}${NOCOLOR}"
  	echo && echo
   	fi
}

lsws_download(){
  curl -o lsws-${LSWS_SUBVER}.tar.gz https://www.litespeedtech.com/packages/${LSWS_VER}/lsws-${LSWS_SUBVER}-ent-x86_64-linux.tar.gz
  tar xfz lsws-${LSWS_SUBVER}.tar.gz --strip=1 -C .
  rm -f lsws-*.tar.gz
}

lsws-install(){
  sed -ie 's|^license$||g' ./install.sh
  sed -riE "s|(r[a-z]{3})\ (TMP[_A-Z]+)|\2=0|g" ./install.sh
  sed -riE "s|(r[a-z]{3})\ (PASS[_A-Z]+)|\2='${ADMIN_PASS}'|g" ./functions.sh
  sed -riE "s|(r[a-z]{3})\ ([A-Z_].*)|\2=\'\'|g" ./functions.sh
  cp ../trial.key ./trial.key
  ${LSWS_INST_DIR}/install.sh  && cp ./trial.key ${SERVER_DIR}/trial.key
}

set_vh_docroot(){
    mkdir -p ${VH_ROOT}
    if [ -d ${VH_ROOT}/${DOMAIN}/html ]; then
	    VH_ROOT="${VH_ROOT}/${DOMAIN}"
        VH_DOC_ROOT="${VH_ROOT}/${DOMAIN}/html"
		WP_CONST_CONF="${VH_DOC_ROOT}/wp-content/plugins/litespeed-cache/data/const.default.ini"
	elif    
		[ -d  ${VH_ROOT}/${DOMAIN} ]; then
                VH_ROOT="${VH_ROOT}/${DOMAIN}"
                VH_DOC_ROOT="${VH_ROOT}/${DOMAIN}/html"	        	
		echo "VH root & VH itself exist, so we will create required doctroot - html"
		mkdir -p ${VH_ROOT}/${DOMAIN}/{html,certs,cgi-bin,conf}    
                WP_CONST_CONF="${VH_DOC_ROOT}/wp-content/plugins/litespeed-cache/data/const.default.ini"
      
	elif
		[ -d ${VH_ROOT} ]; then
            echo "Only VH root exists, will create VH dir & docroot, etc"
	    mkdir -p ${VH_ROOT}/${DOMAIN}/{html,certs,cgi-bin,conf}    
            VH_ROOT="${VH_ROOT}/${DOMAIN}"
            VH_DOC_ROOT="${VH_ROOT}/${DOMAIN}/html"
            WP_CONST_CONF="${VH_DOC_ROOT}/wp-content/plugins/litespeed-cache/data/const.default.ini"
	else
	    echo "${VH_ROOT}/${DOMAIN}/html & ${VH_ROOT} itself do not exist, please add domain first! Abort!"
		exit 1
	fi	
}

admin_creds
lsws_download
lsws-install
configure_lsws_conf
config_vh
config_template
set_vh_docroot
restart_srv

