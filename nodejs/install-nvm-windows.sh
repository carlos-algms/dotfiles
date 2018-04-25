#!/usr/bin/env bash

URL="https://github.com/coreybutler/nvm-windows/releases/download/1.1.6/nvm-noinstall.zip"
tempPath="/tmp/nvm"
tempPath="${HOME}/nvm"
zipFile="${tempPath}.zip"
nodeVersion="9.11.1"

# if [ ! -d "${tempPath}" ]; then
#     echo Download NVM from ${URL}
#     echo
#     curl -L --output "${zipFile}" ${URL}

#     echo Extract zip package
#     echo
#     unzip "${zipFile}" -d "${tempPath}"
# else
#     echo NVM alredy installed, no need to download it again
# fi

if [[ ! -z "${1}" ]]; then
    nodeVersion="${1}"

    echo "Installing  '${nodeVersion}' as requested"
    echo
else
    echo "Installing pre-defined '${nodeVersion}'"
fi


${tempPath}/nvm.exe install "${nodeVersion}"
${tempPath}/nvm.exe use "${nodeVersion}"
