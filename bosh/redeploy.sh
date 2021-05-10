#!/bin/bash

PWD=`cd $(dirname $0); pwd`

echo "tar zcf monit_ng.tar.gz ..."
(
    cd $PWD/..
    rm -rf bosh/src/monit_ng.tar.gz
    tar zcf monit_ng.tar.gz `ls | grep -v bosh`
    mv monit_ng.tar.gz bosh/src/monit_ng.tar.gz
)

echo "bosh login to cnbase ..."
bosh target https://172.17.0.144:25555
bosh login admin kunJCfo2

echo "bosh create and upload new release"
(
    cd $PWD

    echo "generate new yml files ... "
    ruby generate-yml.rb deployment-marmot-agent-cn.yml.template > deploy.yml

    bosh -n create release --force --final
    bosh upload release

    echo "bosh deploy ..."
    bosh -d deploy.yml deploy $1
)

