#!/bin/bash

logo() {
    echo -e "\x1b[33m"
    echo -e "         ██        ▄▄▄▄▄▄▄▄▄▄▄▄▄  ▐██           ▄█▄     ██           ▄█▄            ▄▄           "
    echo -e "        ██▌       ▀▀ ▐██           ███         ███▌     ███         ███▌          ████           "
    echo -e "       ▐██           ███           ███▌       ████      ███▌       ████         ▄█  ██           "
    echo -e "       ██▌          ▄███▄▄▄▄▄     ▐████      █████     ▐████▄     █████        █▀   ██▌          "
    echo -e "      ▐██           ▐██           ██ ▐██   ▄█▀ ███     ██  ██▄  ▄█▀ ███      ██████████          "
    echo -e "     ███           ███          ███   ████▀   ██▌    ▐██   ████▀   ██▌    ▄██      ▀██           "
    echo -e "     ██▌      ▄▄   ██▌          ██            ██▌    ██            ██▌   ▄██        ███          "
    echo -e "     ▀██████▀▀▀    ▀█████▀▀▀   ▐██            ██▌    ██            ██▌   ██▀         ██▀\x1b[0m  "
    echo -e ""
    echo -e "                          Response Streaming CLI Tools on AWS Lambda                             "
    echo -e ""
    echo -e "Lemma build and deploy script"
    echo -e ""
}

function choose_aws_region() {
    local choice
    while true; do
        read -p "Choose an AWS region to deploy to [default: us-east-1]: " choice
        choice=${choice:-us-east-1}
        
        if [[ "$choice" =~ ^[a-zA-Z0-9-]+$ ]]; then
            # return the choice
            aws_region=$choice
            break
        else
            echo "Invalid choice. Please enter a valid AWS region."
        fi
    done
}

function choose_architecture() {
    local choice
    while true; do
        read -p "Choose architecture (arm64 or x86_64) [default: arm64]: " choice
        choice=${choice:-arm64}
        
        if [[ "$choice" == "arm64" || "$choice" == "x86_64" ]]; then
            # return the choice
            arch=$choice
            break
        else
            echo "Invalid choice. Please enter 'arm64' or 'x86_64'."
        fi
    done
}

function lambda_timeout() {
    local choice
    while true; do
        read -p "Choose lambda timeout (1-900 seconds) [default: 300]: " choice
        choice=${choice:-300}
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le 900 ]; then
            # return the choice
            lambda_timeout=$choice
            break
        else
            echo "Invalid choice. Please enter a number between 1 and 900."
        fi
    done
}

function lambda_memory() {
    local choice
    while true; do
        read -p "Choose lambda memory limit (multiples of 64, 128-10240 MB) [default: 1024]: " choice
        choice=${choice:-1024}
        
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 128 ] && [ "$choice" -le 10240 ] && [ "$(($choice % 64))" -eq 0 ]; then
            # return the choice
            lambda_memory=$choice
            break
        else
            echo "Invalid choice. Please enter a number between 128 and 10240, a multiple of 64 only."
        fi
    done
}

function install_tools() {
    # ask a Y/N question to the user if they want to install tools, default is Y
    local choice
    while true; do
        read -p "Do you want to install tools into the lambda package? [Y/n]: " choice
        choice=${choice:-Y}
        
        if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
            # run the install tools script
            echo "Installing tools..."
            ./tools/install_tools.sh $arch
            echo -e "Tools installed\n"
            break
        elif [[ "$choice" == "N" || "$choice" == "n" ]]; then
            break
        else
            echo "Invalid choice. Please enter 'Y' or 'N'."
        fi
    done
}

function remove_template_ask() {
    # ask a Y/N question to the user if they want to install tools, default is Y
    local choice
    while true; do
        read -p "template.yaml exists, create a new template? [y/N]: " choice
        choice=${choice:-N}
        
        if [[ "$choice" == "Y" || "$choice" == "y" ]]; then
            rm -f template.yaml
            echo -e "Template removed\n"
            break
        elif [[ "$choice" == "N" || "$choice" == "n" ]]; then
            echo -e ""
            break
        else
            echo "Invalid choice. Please enter 'Y' or 'N'."
        fi
    done
}

logo

if [ -f /.dockerenv ]; then
    echo "Lemma Build and Deploy..."
else
    echo "Docker Build and Run..."
    docker build -t lemma .

    if [ "$1" == "delete" ]; then
        docker run -it --rm -v ~/.aws:/root/.aws -v .:/lambda \
        -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
        lemma /lambda/build.sh delete
        exit 0
    fi

    # forward AWS credentials to the container in both .aws and environment variables
    docker run -it --rm -v ~/.aws:/root/.aws -v .:/lambda \
    -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY -e AWS_SESSION_TOKEN=$AWS_SESSION_TOKEN \
    lemma /lambda/build.sh
    exit 0
fi

# check if arg1 is 'delete'
if [ "$1" == "delete" ]; then
    echo "Removing Lemma Lambda from AWS... (Please wait, this may take a while)"
    sam delete --no-prompts > delete.log 2>&1
    # check if it fails
    if [ $? -ne 0 ]; then
        echo -e "\x1b[31mRemoval failed. Check delete.log for more information.\x1b[0m"
        exit 1
    fi
    echo -e "Removal successful\n"
    exit 0
fi


# check if template.yaml exists
if [ -f template.yaml ]; then
    remove_template_ask
fi

# if template.yaml doesn't exist, run these functions
if [ ! -f template.yaml ]; then
    cp -f ./templates/samconfig.toml .

    choose_aws_region
    echo -e "AWS region specified: $aws_region\n"

    # replace %REGION% with aws_region
    sed -i "s/%REGION%/$aws_region/g" samconfig.toml

    choose_architecture
    echo -e "Architecture specified: $arch\n"
    lambda_timeout
    echo -e "Lambda timeout specified: $lambda_timeout\n"
    lambda_memory
    echo -e "Lambda memory specified: $lambda_memory\n"

    # generate a random API key
    api_key=$(openssl rand -hex 8)

    #check if arch is arm64
    if [ "$arch" == "arm64" ]; then
        cp ./templates/template_arm64.yaml ./template.yaml
    else
        cp ./templates/template_x86.yaml ./template.yaml
    fi

    # replace %MEMORY% with lambda_memory
    sed -i "s/%MEMORY%/$lambda_memory/g" template.yaml
    # replace %TIMEOUT% with lambda_timeout
    sed -i "s/%TIMEOUT%/$lambda_timeout/g" template.yaml
    # replace %API_KEY% with api_key
    sed -i "s/%API_KEY%/$api_key/g" template.yaml
fi

arch=$(grep -A 1 'Architectures:' template.yaml | awk '/- / {print $2}')
api_key=$(grep -A 5 'Environment:' template.yaml | grep 'LEMMA_API_KEY:' | awk '{print $2}')

install_tools

rm -rf .aws-sam

echo "Building Lemma Lambda... (Please wait, this may take a while)"
sam build > build.log 2>&1
# check if it fails
if [ $? -ne 0 ]; then
    echo -e "\x1b[31mBuild failed. Check build.log for more information.\x1b[0m"
    exit 1
fi

echo -e "Build successful\n"

echo "Deploying Lemma Lambda to AWS... (Please wait, this may take a while)"
sam deploy > deploy.log 2>&1
# check if it fails
if [ $? -ne 0 ]; then
    echo -e "\x1b[31mDeployment failed. Check deploy.log for more information.\x1b[0m"
    exit 1
fi

echo -e "Deployment successful\n"

echo -e "To remove the Lambda, run: \x1b[32m./build.sh delete\x1b[0m"
echo -e "To update the Lambda with new tools re-run \x1b[32m./build.sh\x1b[0m\n"

URL=$(tr -d '\n ' < deploy.log | sed -n 's/.*LEMMA_URL:\(https:\/\/[^ ]*\.aws\/\).*/\1/p')

echo -e "Your Lemma Lambda URL is: \x1b[32m$URL?key=$api_key\x1b[0m"
