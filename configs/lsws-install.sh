#!/bin/bash
set -o allexport; source ../.env
######### Dynamic vars, can be changed via .env ###########
[ -z "${SERVER_DIR}"  ] && SERVER_DIR='/usr/local/lsws' ###
[ -z "${LSWS_VER}"    ] && LSWS_VER='5.0'               ###
[ -z "${LSWS_SUBVER}" ] && LSWS_SUBVER='5.4.9'          ###
[ -z "${DOMAIN}"      ] && DOMAIN='localhost'           ###
[ -z "${VH_ROOT}"     ] && VH_ROOT='/var/www/vhosts'    ###
[ -z "${PHP_VER}"     ] && PHP_VER='lsphp73'            ###
[ -z "${ALLOWED_SUB}" ] && ALLOWED_SUB='0.0.0.0/0'      ###
[ -z "${ADMIN_PASS}"  ] && ADMIN_PASS='dummy_pass'      ###
###########################################################

TMP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DIR_REM=${TMP_DIR}

# Functions declaration
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
  sed -Ei "s|LSAPI_NAME|${PHP_VER}|g" ${TMP_DIR}/httpd_conf.xml
  mv ${TMP_DIR}/httpd_conf.xml  ${SERVER_DIR}/conf/httpd_config.xml
  fi
}

config_httpd(){
  sed -Ei "s|ALLOWED_SUB|${ALLOWED_SUB}|g" ${TMP_DIR}/httpd.conf
  mv ${TMP_DIR}/httpd.conf ${SERVER_DIR}/conf/httpd.conf
}

config_vh(){
  sed -Ei "s|DOMAIN|${DOMAIN}|g" ${TMP_DIR}/vh-conf.xml
  sed -Ei "s|VH_ROOT|${VH_ROOT}|g" ${TMP_DIR}/vh-conf.xml
  sed -Ei "s|PHP_VER|${PHP_VER}|g" ${TMP_DIR}/vh-conf.xml
  mv ${TMP_DIR}/vh-conf.xml ${SERVER_DIR}/conf/${DOMAIN}.xml
}

config_template(){
  sed -Ei "s|LSAPI_NAME|${PHP_VER}|g" ${TMP_DIR}/docker.xml
  sed -Ei "s|DOMAIN|${DOMAIN}|g"   ${TMP_DIR}/docker.xml
  sed -Eir "s|VH_ROOT|${VH_ROOT}|g" ${TMP_DIR}/docker.xml
  if [[ ${PHP_VER} =~ ^lsphp[5-9]{1}[3-9]{1} ]]; then
	  sed -Ei "s|PHP_VER|${PHP_VER}|g" ${TMP_DIR}/docker.xml
  fi
  mv ${TMP_DIR}/docker.xml ${SERVER_DIR}/conf/templates/docker.xml
}

admin_creds(){

NOCOLOR='\033[0m'
RED='\033[0;31m'
  if [ -z "${ADMIN_USER}" ]  && [ ${ADMIN_PASS} = "dummy_pass" ]; then
    ADMIN_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
    echo && echo
    echo -e "${RED}Since the Admin username and pass were not pre-defined, the random ones generated ---> admin : ${ADMIN_PASS}${NOCOLOR}"
    reset_details "admin" ${ADMIN_PASS}

  elif [ ! -z "${ADMIN_USER}" ] && [ ${ADMIN_PASS} = "dummy_pass" ]; then
    ADMIN_PASS=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 7 | head -n 1)
    echo && echo
    echo -e "${RED}Admin username -----> ${ADMIN_USER}, Admin Pass (generated automatically) -----> ${ADMIN_PASS}${NOCOLOR}"
    reset_details ${ADMIN_USER} ${ADMIN_PASS}
  elif  [ -z "${ADMIN_USER}" ] && [ ! -z "${ADMIN_PASS}" ]; then
      if [[ ${ADMIN_PASS} -ge 8 ]]; then
      reset_details "admin" ${ADMIN_PASS}
      echo && echo
      echo -e "${RED}Admin username was set automatically -----> admin, Admin Pass -----> ${ADMIN_PASS}${NOCOLOR}"
      else
        echo -e "${RED} Password too short! exiting ${NOCOLOR}"
        exit 1
      fi
  else
     echo && echo
     echo -e "${RED}The admin username -----> ${ADMIN_USER}, Admin Pass -----> ${ADMIN_PASS}${NOCOLOR}"
     reset_details ${ADMIN_USER} ${ADMIN_PASS}
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
        chown -R 1000:1000 ${VH_DOC_ROOT}/
		WP_CONST_CONF="${VH_DOC_ROOT}/wp-content/plugins/litespeed-cache/data/const.default.ini"
	elif
		[ -d  ${VH_ROOT}/${DOMAIN} ]; then
                VH_ROOT="${VH_ROOT}/${DOMAIN}"
                VH_DOC_ROOT="${VH_ROOT}/${DOMAIN}/html"
		echo "VH root & VH itself exist, so we will create required doctroot - html"
		mkdir -p ${VH_ROOT}/${DOMAIN}/{html,certs,cgi-bin,conf}
    chown -R 1000:1000 ${VH_DOC_ROOT}/
    WP_CONST_CONF="${VH_DOC_ROOT}/wp-content/plugins/litespeed-cache/data/const.default.ini"

	elif
		[ -d ${VH_ROOT} ]; then
            echo "Only VH root exists, will create VH dir & docroot, etc"
	    mkdir -p ${VH_ROOT}/${DOMAIN}/{html,certs,cgi-bin,conf}
            VH_DOC_ROOT="${VH_ROOT}/${DOMAIN}/html"
            chown -R 1000:1000 ${VH_DOC_ROOT}/
            WP_CONST_CONF="${VH_DOC_ROOT}/wp-content/plugins/litespeed-cache/data/const.default.ini"
	else
	    echo "${VH_ROOT}/${DOMAIN}/html & ${VH_ROOT} itself do not exist, please add domain first! Abort!"
		exit 1
	fi
}

reset_details(){
  ENCRYPT_PASS=`"${SERVER_DIR}/admin/fcgi-bin/admin_php5" -q "${SERVER_DIR}/admin/misc/htpasswd.php" ${2}`
  echo "$1:${ENCRYPT_PASS}" > "${SERVER_DIR}/admin/conf/htpasswd"
  echo "$1:${ENCRYPT_PASS}" > "${SERVER_DIR}/admin/htpasswds/status"
}




#############################
#            Main           #
#############################
lsws_download
lsws-install
configure_lsws_conf
config_httpd
config_vh
config_template
set_vh_docroot
admin_creds
restart_srv
