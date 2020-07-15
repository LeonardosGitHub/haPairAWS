#cloud-config
write_files:
- path: /config/cloud/startup-script.sh
  permissions: '0755'
  content: |
    #!/bin/bash

    ## 1NIC BIG-IP ONBOARD SCRIPT

    ## IF THIS SCRIPT IS LAUNCHED EARLY IN BOOT (ex. when from cloud-init),
    # YOU NEED TO RUN IT IN THE BACKGROUND TO NOT BLOCK OTHER STARTUP FUNCTIONS
    # ex. location of interpolated cloud-init script
    #/opt/cloud/instances/i-079ac8a174eb1727a/scripts/part-001

    LOG_FILE=/var/log/startup-script.log
    if [ ! -e $LOG_FILE ]
    then
      touch $LOG_FILE
      exec &>>$LOG_FILE
      # nohup $0 0<&- &>/dev/null &
    else
      #if file exists, exit as only want to run once
      exit
    fi

    ### ONBOARD INPUT PARAMS

    echo "!!!!! Sleeping for 3 minutes!!!!!"
    sleep 3m
    echo "!!!!! FINISHED - Sleeping for 3 minutes!!!!!"

    adminUsername=${adminUsername}
    adminPassword=${adminPassword}

    # Management Interface uses DHCP
    # v13 uses mgmt for ifconfig & defaults to 8443 for GUI for Single Nic Deployments
    if ifconfig mgmt; then managementInterface=mgmt; else managementInterface=eth0; fi
    managementAddress=$(egrep -m 1 -A 1 $managementInterface /var/lib/dhclient/dhclient.leases | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    managementGuiPort=${managementGuiPort}

    ### CREATING LIBS $ DIRECTORY
    dep_dir="/config/cloud/dependencies"
    mkdir -p $dep_dir

    ### DOWNLOADING DEPENDENCIES

    echo "!!!!! Using curl to download Declarative Onboarding rpm!!!!!"
    curl -L -o $dep_dir/f5-declarative-onboarding-1.13.0-5.noarch.rpm https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.13.0/f5-declarative-onboarding-1.13.0-5.noarch.rpm

    echo "!!!!! Using curl to download Application Services(AS3) rpm!!!!!"
    curl -L -o $dep_dir/f5-appsvcs-3.20.0-3.noarch.rpm https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.20.0/f5-appsvcs-3.20.0-3.noarch.rpm

    echo "!!!!! Using curl to download Telemetry Streaming rpm!!!!!"
    curl -L -o $dep_dir/f5-telemetry-1.12.0-3.noarch.rpm https://github.com/F5Networks/f5-telemetry-streaming/releases/download/v1.12.0/f5-telemetry-1.12.0-3.noarch.rpm

    echo "!!!!! creating admin user"
    tmsh create auth user $${adminUsername} password $${adminPassword} shell bash partition-access replace-all-with { all-partitions { role admin } }
    tmsh save /sys config

    echo "!!!!! Installing DO rpm"
    rpm=${do_rpm}
    DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/config/cloud/dependencies/$${rpm}\"}"
    response_code=$(/usr/bin/curl -skvvu $${adminUsername}:$${passwd} -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Origin: https://$${managementAddress}" "https://localhost:$${managementGuiPort}/mgmt/shared/iapp/package-management-tasks"   --data $${DATA} -o /dev/null)

    if [[ $response_code == 202 ]]; then
      echo "!!!!! Installment of DO rpm succeeded."
    else
      echo "!!!!! Failed to install DO rpm; continuing..."
    fi

    # Install TS rpm
    echo "!!!!! Installing TS rpm"
    rpm=${ts_rpm}
    DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/config/cloud/dependencies/$${rpm}\"}"
    response_code=$(/usr/bin/curl -skvvu $${adminUsername}:$${passwd} -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Origin: https://$${managementAddress}" "https://localhost:$${managementGuiPort}/mgmt/shared/iapp/package-management-tasks"   --data $${DATA} -o /dev/null)

    if [[ $response_code == 202 ]]; then
      echo "!!!!! Installment of TS rpm succeeded."
    else
      echo "!!!!! Failed to deploy TS rpm; continuing..."
    fi

    # Install AS3 rpm
    echo "!!!!! Installing AS3 rpm"
    rpm=${as3_rpm}
    DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/config/cloud/dependencies/$${rpm}\"}"
    response_code=$(/usr/bin/curl -skvvu $${adminUsername}:$${passwd} -w "%%{http_code}" -X POST -H "Content-Type: application/json" -H "Origin: https://$${managementAddress}" "https://localhost:$${managementGuiPort}/mgmt/shared/iapp/package-management-tasks"   --data $${DATA} -o /dev/null)

    if [[ $response_code == 202 ]]; then
      echo "!!!!! Installment of as3 rpm succeeded."
    else
      echo "!!!!! Failed to deploy as3 rpm; continuing..."
    fi

    tmsh save /sys config
 
    echo "!!!!! creating signal file to show startup script has completed !!!!!"
    echo > /tmp/signal
    echo "!!!!! FINISHED STARTUP SCRIPT"

runcmd:
  - nohup /config/cloud/startup-script.sh &
