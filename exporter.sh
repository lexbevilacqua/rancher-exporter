#!/bin/bash

DIR=`dirname $0`
RANCHER="${DIR}/rancher"

function log () {
    AGORA=`date '+%Y%m%d%H%M%S'`
    echo "$AGORA - $1"
}

function test_variables () {

    log 'Testing required variables'

    if [ -z "$RANCHER_URL" ] || [ -z "$RANCHER_ACCESS_KEY" ] || [ -z "$RANCHER_SECRET_KEY" ] 
    then
        log 'Is mandatory declare this variables: RANCHER_URL, RANCHER_ACCESS_KEY, RANCHER_SECRET_KEY'
        log 'more info on \"ACCOUNT API KEYS\" http://http://rancher.com/docs/rancher/v1.2/en/api/v2-beta/api-keys/'
        exit 1
    fi

    if [ -z "$SECONDS_WAIT" ]
    then
        log 'SECONDS_WAIT is set to default: 86400( 1 day )'
        export SECONDS_WAIT=86400
    fi

    if [ -z "$GIT_URL" ]
    then
        log 'Is mandatory declare git url in GIT_URL'
        exit 1
    fi

    if [ ! -z "$GIT_USER_NAME" ] && [ ! -z "$GIT_USER_EMAIL" ]
    then
        git config --global user.name "$GIT_USER_NAME"
        git config --global user.email "$GIT_USER_EMAIL"
    fi

    git config --global http.sslVerify "false"
    git clone $GIT_URL

    export PROJECT=`echo $GIT_URL | sed -e 's/.*\///g' | cut -d'.' -f1`
        
    MESSAGE="[rancher-exporter] Automatically checking status changes"

    if [ -z "$ENVIROMENT" ]
    then
        MESSAGE="${MESSAGE} enviroment: ${ENVIROMENT}"
    fi

    log "################################################"
    log "#  DIR:.................: ${DIR}"
    log "#  RANCHER_URL:.........: ${RANCHER_URL}"
    log "#  RANCHER_ACCESS_KEY:..: ${RANCHER_ACCESS_KEY}"
    log "#  SECONDS_WAIT:........: ${SECONDS_WAIT}"
    log "#  GIT_URL:.............: ${GIT_URL}"
    log "#  GIT_USER_NAME:.......: ${GIT_USER_NAME}"
    log "#  GIT_USER_EMAIL:......: ${GIT_USER_EMAIL}"
    log "#  PROJECT:.............: ${PROJECT}"
    log "#  ENVIROMENT:..........: ${ENVIROMENT}"
    log "#  MESSAGE:.............: ${MESSAGE}"
    log "################################################"

}

function export_rancher()  {

    log "################################################"
    log "# Start exporter..."
    log "################################################"
    
    log "Switch to dir: ${DIR}/${PROJECT}/${ENVIROMENT}"
    if [ ! -d ${DIR}/${PROJECT}/${ENVIROMENT} ]
    then
        mkdir "${DIR}/${PROJECT}/${ENVIROMENT}"
    fi
    cd "${PROJECT}/${ENVIROMENT}"

    log "Stacks"
    ${RANCHER} stacks ls

    for i in `${RANCHER} stacks ls | awk '{print $2}' | grep -v 'NAME'`
    do
        log "Exporting stack ${i}" 
        ${RANCHER} export ${i}
    done

    log "Switch to dir: ${DIR}/${PROJECT}"
    cd ${DIR}/${PROJECT}
    
    log "git adding changes"
    git add .

    log "git commit "
    git commit -m "${MESSAGE}"

    n=$?
    if [ $n -eq 0 ]
    then
        git push
    fi

    cd ${DIR}
    rm -rf $PROJETO 2> /dev/null

}

cat << "EOF"

#####################################
### RANCHER EXPORTER
#####################################

       ,/         \,
      ((__,-"""-,__))
       `--)~   ~(--`
      .-'(       )`-,
      `~~`d\   /b`~~`
          |     |
          (6___6)
           `---`

#####################################

EOF

test_variables

while :
do
	export_rancher
    log "Waiting ${SECONDS_WAIT} seconds..."
	sleep $SECONDS_WAIT
done




