#!/usr/bin/env bash
set -e

source_url="https://github.com/nickspat/setupcfongcp/raw/master"

if [ -f ./constants.sh ]; then
    rm -rf ./constants.sh
fi
wget ${source_url}/constants.sh && chmod 744 ./constants.sh && source ./constants.sh

echo "-------------- Starting to delete cloud foundry setup -----------------"
bosh_ip=`gcloud compute instances describe bosh-bastion --zone ${google_zone} | grep natIP: | cut -f2 -d :`
command="wget ${source_url}/cf-teardown.sh && chmod 744 ./cf-teardown.sh && ./cf-teardown.sh"
ssh -t -o StrictHostKeyChecking=no -i ~/.ssh/google_compute_engine ${bosh_ip} ${command}

echo "-------------- Starting to teardown Bosh Director -----------------"
gcloud compute ssh bosh-bastion --zone ${google_zone} --command "wget ${source_url}/director-teardown.sh && chmod 744 ./director-teardown.sh && ./director-teardown.sh"

wget ${source_url}/infra-teardown.sh && chmod 744 ./infra-teardown.sh && ./infra-teardown.sh

echo "Successfully deleted bosh director, cloud foundry and GCP components"

set -e