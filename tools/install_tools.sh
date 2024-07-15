#!/bin/bash

# Function to display usage message
usage() {
    echo "Usage: $0 <arch>"
    echo "arch must be either x86_64 or arm64"
    exit 1
}

# Check if argument is provided
if [ -z "$1" ]; then
    echo "Error: No architecture specified."
    usage
fi

# Check if the argument is valid
if [ "$1" != "x86_64" ] && [ "$1" != "arm64" ]; then
    echo "Error: Invalid architecture specified."
    usage
fi

# If the argument is valid, proceed with the script
arch="$1"
echo "Architecture specified: $arch"
#cd ..
rm -rf ./app/tools
rm -f ./app/tool_requirements.txt
cp -rf ./tools ./app/
mkdir -p ./app/tools/bin
mkdir -p ./app/tools/wordlists
touch ./app/tool_requirements.txt

if [ "$arch" == "x86_64" ]; then

    echo "Installing ffuf..."
    tmpdir=$(mktemp -d)
    wget https://github.com/ffuf/ffuf/releases/download/v2.1.0/ffuf_2.1.0_linux_amd64.tar.gz -O $tmpdir/ffuf.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/ffuf.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/ffuf ./app/tools/bin/

    echo "Installing httpx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/httpx/releases/download/v1.6.5/httpx_1.6.5_linux_amd64.zip -O $tmpdir/httpx.zip > /dev/null 2>&1
    unzip $tmpdir/httpx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/httpx ./app/tools

    echo "Installing gau..."
    tmpdir=$(mktemp -d)
    wget https://github.com/lc/gau/releases/download/v2.2.3/gau_2.2.3_linux_amd64.tar.gz -O $tmpdir/gau.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/gau.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/gau ./app/tools/bin/

    echo "Installing subfinder..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/subfinder/releases/download/v2.6.6/subfinder_2.6.6_linux_amd64.zip -O $tmpdir/subfinder.zip > /dev/null 2>&1
    unzip $tmpdir/subfinder.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/subfinder ./app/tools

    echo "Installing dnsx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/dnsx/releases/download/v1.2.1/dnsx_1.2.1_linux_amd64.zip -O $tmpdir/dnsx.zip > /dev/null 2>&1
    unzip $tmpdir/dnsx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/dnsx ./app/tools

elif [ "$arch" == "arm64" ]; then

    echo "Installing ffuf..."
    tmpdir=$(mktemp -d)
    wget https://github.com/ffuf/ffuf/releases/download/v2.1.0/ffuf_2.1.0_linux_arm64.tar.gz -O $tmpdir/ffuf.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/ffuf.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/ffuf ./app/tools/bin/

    echo "Installing httpx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/httpx/releases/download/v1.6.5/httpx_1.6.5_linux_arm64.zip -O $tmpdir/httpx.zip > /dev/null 2>&1
    unzip $tmpdir/httpx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/httpx ./app/tools

    echo "Installing gau..."
    tmpdir=$(mktemp -d)
    wget https://github.com/lc/gau/releases/download/v2.2.3/gau_2.2.3_linux_arm64.tar.gz -O $tmpdir/gau.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/gau.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/gau ./app/tools/bin/

    echo "Installing subfinder..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/subfinder/releases/download/v2.6.6/subfinder_2.6.6_linux_arm64.zip -O $tmpdir/subfinder.zip > /dev/null 2>&1
    unzip $tmpdir/subfinder.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/subfinder ./app/tools

    echo "Installing dnsx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/dnsx/releases/download/v1.2.1/dnsx_1.2.1_linux_arm64.zip -O $tmpdir/dnsx.zip > /dev/null 2>&1
    unzip $tmpdir/dnsx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/dnsx ./app/tools

fi

echo "Installing smuggler..."
git clone https://github.com/defparam/smuggler ./app/tools/bin/smuggler > /dev/null 2>&1


echo "Installing SecLists's common.txt wordlist..."
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -O ./app/tools/wordlists/common.txt > /dev/null 2>&1

rm -rf ./app/tools/install_tools.sh


