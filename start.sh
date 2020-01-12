#!/bin/bash

echo "Initialing the ${event}...."
export BUILD_VERSION="${build_version}"
export RELEASE_VERSION="${release_version}"
export AWS_ACCOUNT="${aws_account}"
export AWS_ACCESS_KEY_ID="${aws_access_key_id}"
export AWS_SECRET_ACCESS_KEY="${aws_secret_access_key}"
export AWS_DEFAULT_REGION="${aws_region}";

if [ "${event}" == "vpcsetup" ]; then
    make -s vpcsetup
elif [ "${event}" == "build" ]; then
    make -s release
elif [ "${event}" == "clustersetup" ]; then
    make -s clustersetup    
elif [ "${event}" == "deploy" ]; then
    make -s servicesetup   
else
    echo "Invalid execute command"
    exit 1  
fi;