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
mkdir -p ./app/tools/wordlists
touch ./app/tool_requirements.txt

if [ "$arch" == "x86_64" ]; then

    echo "Installing ffuf..."
    tmpdir=$(mktemp -d)
    wget https://github.com/ffuf/ffuf/releases/download/v2.1.0/ffuf_2.1.0_linux_amd64.tar.gz -O $tmpdir/ffuf.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/ffuf.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/ffuf ./app/tools/bin/
    rm -rf $tmpdir

    echo "Installing httpx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/httpx/releases/download/v1.6.5/httpx_1.6.5_linux_amd64.zip -O $tmpdir/httpx.zip > /dev/null 2>&1
    unzip $tmpdir/httpx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/httpx ./app/tools
    rm -rf $tmpdir

    echo "Installing gau..."
    tmpdir=$(mktemp -d)
    wget https://github.com/lc/gau/releases/download/v2.2.3/gau_2.2.3_linux_amd64.tar.gz -O $tmpdir/gau.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/gau.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/gau ./app/tools/bin/
    rm -rf $tmpdir

    echo "Installing subfinder..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/subfinder/releases/download/v2.6.6/subfinder_2.6.6_linux_amd64.zip -O $tmpdir/subfinder.zip > /dev/null 2>&1
    unzip $tmpdir/subfinder.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/subfinder ./app/tools
    rm -rf $tmpdir

    echo "Installing dnsx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/dnsx/releases/download/v1.2.1/dnsx_1.2.1_linux_amd64.zip -O $tmpdir/dnsx.zip > /dev/null 2>&1
    unzip $tmpdir/dnsx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/dnsx ./app/tools
    rm -rf $tmpdir

    echo "Installing nuclei..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/nuclei/releases/download/v3.2.9/nuclei_3.2.9_linux_amd64.zip -O $tmpdir/nuclei.zip > /dev/null 2>&1
    unzip $tmpdir/nuclei.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/nuclei ./app/tools/bin
    rm -rf $tmpdir

    echo "Installing katana..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/katana/releases/download/v1.1.0/katana_1.1.0_linux_amd64.zip -O $tmpdir/katana.zip > /dev/null 2>&1
    unzip $tmpdir/katana.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/katana ./app/tools
    rm -rf $tmpdir

    echo "Installing shortscan..."
    git clone https://github.com/bitquark/shortscan.git > /dev/null 2>&1
    cd shortscan
    go mod tidy > /dev/null 2>&1
    GOARCH=amd64 go build -o ../app/tools/shortscan ./cmd/shortscan > /dev/null 2>&1
    cd ..
    rm -rf shortscan

    tmpdir=$(mktemp -d)
    wget http://ftp.us.debian.org/debian/pool/main/b/busybox/busybox_1.30.1-4_amd64.deb -O $tmpdir/busybox.deb > /dev/null 2>&1
    dpkg -x $tmpdir/busybox.deb $tmpdir > /dev/null 2>&1
    mv $tmpdir/bin/busybox ./app/tools/bin/
    rm -rf $tmpdir

elif [ "$arch" == "arm64" ]; then

    echo "Installing ffuf..."
    tmpdir=$(mktemp -d)
    wget https://github.com/ffuf/ffuf/releases/download/v2.1.0/ffuf_2.1.0_linux_arm64.tar.gz -O $tmpdir/ffuf.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/ffuf.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/ffuf ./app/tools/bin/
    rm -rf $tmpdir

    echo "Installing httpx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/httpx/releases/download/v1.6.5/httpx_1.6.5_linux_arm64.zip -O $tmpdir/httpx.zip > /dev/null 2>&1
    unzip $tmpdir/httpx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/httpx ./app/tools
    rm -rf $tmpdir

    echo "Installing gau..."
    tmpdir=$(mktemp -d)
    wget https://github.com/lc/gau/releases/download/v2.2.3/gau_2.2.3_linux_arm64.tar.gz -O $tmpdir/gau.tar.gz > /dev/null 2>&1
    tar -xvf $tmpdir/gau.tar.gz -C $tmpdir > /dev/null 2>&1
    mv $tmpdir/gau ./app/tools/bin/
    rm -rf $tmpdir

    echo "Installing subfinder..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/subfinder/releases/download/v2.6.6/subfinder_2.6.6_linux_arm64.zip -O $tmpdir/subfinder.zip > /dev/null 2>&1
    unzip $tmpdir/subfinder.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/subfinder ./app/tools
    rm -rf $tmpdir

    echo "Installing dnsx..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/dnsx/releases/download/v1.2.1/dnsx_1.2.1_linux_arm64.zip -O $tmpdir/dnsx.zip > /dev/null 2>&1
    unzip $tmpdir/dnsx.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/dnsx ./app/tools
    rm -rf $tmpdir

    echo "Installing nuclei..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/nuclei/releases/download/v3.2.9/nuclei_3.2.9_linux_arm64.zip -O $tmpdir/nuclei.zip > /dev/null 2>&1
    unzip $tmpdir/nuclei.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/nuclei ./app/tools/bin
    rm -rf $tmpdir

    echo "Installing katana..."
    tmpdir=$(mktemp -d)
    wget https://github.com/projectdiscovery/katana/releases/download/v1.1.0/katana_1.1.0_linux_arm64.zip -O $tmpdir/katana.zip > /dev/null 2>&1
    unzip $tmpdir/katana.zip -d $tmpdir > /dev/null 2>&1
    mv $tmpdir/katana ./app/tools
    rm -rf $tmpdir

    echo "Installing shortscan..."
    git clone https://github.com/bitquark/shortscan.git > /dev/null 2>&1
    cd shortscan
    go mod tidy > /dev/null 2>&1
    GOARCH=arm64 go build -o ../app/tools/shortscan ./cmd/shortscan > /dev/null 2>&1
    cd ..
    rm -rf shortscan

    tmpdir=$(mktemp -d)
    wget http://ftp.us.debian.org/debian/pool/main/b/busybox/busybox_1.30.1-4_arm64.deb -O $tmpdir/busybox.deb > /dev/null 2>&1
    dpkg -x $tmpdir/busybox.deb $tmpdir > /dev/null 2>&1
    mv $tmpdir/bin/busybox ./app/tools/bin/
    rm -rf $tmpdir

fi

echo "Installing smuggler..."
git clone https://github.com/defparam/smuggler ./app/tools/bin/smuggler > /dev/null 2>&1

echo "Installing SecLists's common.txt wordlist..."
wget https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt -O ./app/tools/wordlists/common.txt > /dev/null 2>&1

rm -rf ./app/tools/install_tools.sh


