#!/bin/bash
# Exit immediately if a command exits with a non-zero status
set -e
# Update and upgrade the system
sudo apt update
sudo apt upgrade -y
# Install Go
curl -OL https://go.dev/dl/go1.22.4.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.22.4.linux-amd64.tar.gz
export PATH=$PATH:/usr/local/go/bin
export PATH=$PATH:/usr/.local/go/bin
source ~/.bashrc
go version
# Install Python3 and pip@
sudo apt install -y python3-pip
# Install Docker
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/2.28.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
docker compose version
# Install allocmd CLI
pip install allocmd --upgrade
export PATH="$PATH:$HOME/.local/bin"
source ~/.bashrc
allocmd --version
# Wallet Setup
curl -sSL https://raw.githubusercontent.com/allora-network/allora-chain/main/install.sh | bash -s -- v0.0.10
export PATH="$PATH:/root/.local/bin"
git clone -b v0.0.10 https://github.com/allora-network/allora-chain.git
cd allora-chain && make all
allorad version
# Recover or create a new wallet
read -p "Do you want to recover an existing wallet? (y/n): " recover_wallet
if [ "$recover_wallet" == "y" ]; then
  read -p "Enter your wallet name: " wallet_name
  allorad keys add $wallet_name --recover
else
  read -p "Enter your wallet name: " wallet_name
  allorad keys add $wallet_name
fi
# Get faucet tokens
echo "Get faucet tokens from https://faucet.testnet-1.testnet.allora.network/"
# Clone the basic coin prediction node repository
cd $HOME
git clone https://github.com/nhunamit/basic-coin-prediction-node.git
mv basic-coin-prediction-node worker-10m
cd worker-10m
git checkout worker1-10m

# Prompt for wallet seed phrase
read -p "Enter your wallet seed phrase: " wallet_seed_phrase

# Xóa file config.json hiện tại
rm -f config.json

# Tạo file config.json mới
cat <<EOL > config.json
{
    "wallet": {
        "addressKeyName": "test",
        "addressRestoreMnemonic": "$wallet_seed_phrase",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://allora-rpc.testnet-1.testnet.allora.network",
        "maxRetries": 2,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8012/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 4,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8012/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 6,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8012/inference/{Token}",
                "Token": "SOL"
            }
        }
    ]
}
EOL

# Build the worker
bash ./init.config
docker-compose up -d

cd $HOME
git clone https://github.com/nhunamit/basic-coin-prediction-node.git
mv basic-coin-prediction-node worker-24h
cd worker-24h
git checkout worker2-24h

# Xóa file config.json hiện tại
rm -f config.json

# Tạo file config.json mới
cat <<EOL > config.json
{
    "wallet": {
        "addressKeyName": "test",
        "addressRestoreMnemonic": "$wallet_seed_phrase",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://allora-rpc.testnet-1.testnet.allora.network",
        "maxRetries": 2,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 2,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8012/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 4,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8012/inference/{Token}",
                "Token": "BTC"
            }
        },
        {
            "topicId": 6,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8012/inference/{Token}",
                "Token": "SOL"
            }
        }
    ]
}
EOL

# Build the worker
bash ./init.config
docker-compose up -d

cd $HOME
git clone https://github.com/nhunamit/basic-coin-prediction-node.git
mv basic-coin-prediction-node worker-20m
cd worker-20m
git checkout worker3-20m

# Xóa file config.json hiện tại
rm -f config.json

# Tạo file config.json mới
cat <<EOL > config.json
{
    "wallet": {
        "addressKeyName": "test",
        "addressRestoreMnemonic": "$wallet_seed_phrase",
        "alloraHomeDir": "",
        "gas": "1000000",
        "gasAdjustment": 1.0,
        "nodeRpc": "https://allora-rpc.testnet-1.testnet.allora.network",
        "maxRetries": 2,
        "delay": 1,
        "submitTx": false
    },
    "worker": [
        {
            "topicId": 7,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8013/inference/{Token}",
                "Token": "ETH"
            }
        },
        {
            "topicId": 8,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8013/inference/{Token}",
                "Token": "BNB"
            }
        },
        {
            "topicId": 9,
            "inferenceEntrypointName": "api-worker-reputer",
            "loopSeconds": 5,
            "parameters": {
                "InferenceEndpoint": "http://inference:8013/inference/{Token}",
                "Token": "ARB"
            }
        }
    ]
} 
EOL


# Build the worker
bash ./init.config
docker-compose up -d