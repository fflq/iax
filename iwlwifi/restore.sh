#/usr/bin/sudo /bin/bash

echo "* restore normal iwlwifi" 

iax_iwlwifi_dir=$(dirname ${BASH_SOURCE[0]})

${iax_iwlwifi_dir}/restore-firmware.sh
${iax_iwlwifi_dir}/clean-updates.sh
${iax_iwlwifi_dir}/reload-csi-iwlwifi.sh

echo "done"

