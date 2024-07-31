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
mv basic-coin-prediction-node worker-face-10m
cd worker-face-10m
git checkout worker-face-10m
# Create directories for worker and head data
mkdir -p worker-topic-1-data
chmod 777 worker-topic-1-data
mkdir -p worker-topic-3-data
chmod 777 worker-topic-3-data
mkdir -p worker-topic-5-data
chmod 777 worker-topic-5-data
mkdir -p head-data
chmod 777 head-data
mkdir -p worker-data
chmod 777 worker-data
# Create head keys
sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# Create worker keys
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# Read the head-id
head_id=$(cat head-data/keys/identity)
# Prompt for wallet seed phrase
read -p "Enter your wallet seed phrase: " wallet_seed_phrase
# Create docker-compose.yml
rm -rf docker-compose.yml
cat <<EOL > docker-compose.yml
version: '3'
services:
  inference:
    container_name: inference-basic-eth-pred
    build:
      context: .
    command: python -u /app/app.py
    ports:
      - "8000:8000"
    networks:
      eth-model-local:
        aliases:
          - inference
        ipv4_address: 172.22.0.4
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/inference/ETH"]
      interval: 10s
      timeout: 5s
      retries: 12
    volumes:
      - ./inference-data:/app/data

  worker-topic-1:
    container_name: worker-topic-1
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9011 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-1-worker \
          --allora-chain-key-name=$wallet_name \
          --allora-chain-restore-mnemonic='$wallet_seed_phrase' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=1
    volumes:
      - ./worker-topic-1-data:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-topic-1
        ipv4_address: 172.22.0.11

  worker-topic-3:
    container_name: worker-topic-3
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9012 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-3-worker \
          --allora-chain-key-name=$wallet_name \
          --allora-chain-restore-mnemonic='$wallet_seed_phrase' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=3
    volumes:
      - ./worker-topic-3-data:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-topic-3
        ipv4_address: 172.22.0.12

  worker-topic-5:
    container_name: worker-topic-5
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9013 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-5-worker \
          --allora-chain-key-name=$wallet_name \
          --allora-chain-restore-mnemonic='$wallet_seed_phrase' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=5
    volumes:
      - ./worker-topic-5-data:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-topic-5
        ipv4_address: 172.22.0.13

  head:
    container_name: head-basic-eth-pred
    image: alloranetwork/allora-inference-base-head:latest
    environment:
      - HOME=/data
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=head --peer-db=/data/peerdb --function-db=/data/function-db  \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9010 --rest-api=:6000
    ports:
      - "6000:6000"
    volumes:
      - ./head-data:/data
    working_dir: /data
    networks:
      eth-model-local:
        aliases:
          - head
        ipv4_address: 172.22.0.100

networks:
  eth-model-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/24

volumes:
  inference-data:
  worker-topic-1-data:
  worker-topic-3-data:
  worker-topic-5-data:
  head-data:
EOL

echo "Setup complete. The 'docker-compose.yml' file has been created with the head-id and wallet seed phrase."
sudo docker compose up -d

cd $HOME
git clone https://github.com/nhunamit/basic-coin-prediction-node.git
mv basic-coin-prediction-node worker-face-24h
cd worker-face-24h
git checkout worker-face-24h

# Create directories for worker and head data for worker-face-24h
mkdir -p worker-topic-2-data worker-topic-4-data worker-topic-6-data head-data worker-data
chmod 777 worker-topic-2-data worker-topic-4-data worker-topic-6-data head-data worker-data

# Create head keys for worker-face-24h
sudo docker run -it --entrypoint=bash -v $(pwd)/head-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# Create worker keys for worker-face-24h
sudo docker run -it --entrypoint=bash -v $(pwd)/worker-data:/data alloranetwork/allora-inference-base:latest -c "mkdir -p /data/keys && (cd /data/keys && allora-keys)"
# Read the head-id
head_id=$(cat head-data/keys/identity)
# Prompt for wallet seed phrase
read -p "Enter your wallet seed phrase: " wallet_seed_phrase

# Create docker-compose.yml for worker-face-24h
rm -rf docker-compose.yml
cat <<EOL > docker-compose.yml
version: '3'
services:
  inference:
    container_name: inference-basic-eth-pred
    build:
      context: .
    command: python -u /app/app.py
    ports:
      - "8000:8000"
    networks:
      eth-model-local:
        aliases:
          - inference
        ipv4_address: 172.22.0.4
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/inference/ETH"]
      interval: 10s
      timeout: 5s
      retries: 12
    volumes:
      - ./inference-data:/app/data

  head:
    container_name: head-basic-eth-pred
    image: alloranetwork/allora-inference-base-head:latest
    environment:
      - HOME=/data
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=head --peer-db=/data/peerdb --function-db=/data/function-db  \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9010 --rest-api=:6000
    ports:
      - "6000:6000"
    volumes:
      - ./head-data:/data
    networks:
      eth-model-local:
        aliases:
          - head
        ipv4_address: 172.22.0.100

  worker-topic-2:
    container_name: worker-topic-2
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9011 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-2-worker \
          --allora-chain-key-name=$wallet_name \
          --allora-chain-restore-mnemonic='$wallet_seed_phrase' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=2
    volumes:
      - ./worker-topic-2-data:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-topic-2
        ipv4_address: 172.22.0.11

  worker-topic-4:
    container_name: worker-topic-4
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9012 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-4-worker \
          --allora-chain-key-name=$wallet_name \
          --allora-chain-restore-mnemonic='$wallet_seed_phrase' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=4
    volumes:
      - ./worker-topic-4-data:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-topic-4
        ipv4_address: 172.22.0.12

  worker-topic-6:
    container_name: worker-topic-6
    environment:
      - INFERENCE_API_ADDRESS=http://inference:8000
      - HOME=/data
    build:
      context: .
      dockerfile: Dockerfile_b7s
    entrypoint:
      - "/bin/bash"
      - "-c"
      - |
        if [ ! -f /data/keys/priv.bin ]; then
          echo "Generating new private keys..."
          mkdir -p /data/keys
          cd /data/keys
          allora-keys
        fi
        allora-node --role=worker --peer-db=/data/peerdb --function-db=/data/function-db \
          --runtime-path=/app/runtime --runtime-cli=bls-runtime --workspace=/data/workspace \
          --private-key=/data/keys/priv.bin --log-level=debug --port=9013 \
          --boot-nodes=/ip4/172.22.0.100/tcp/9010/p2p/$head_id \
          --topic=allora-topic-6-worker \
          --allora-chain-key-name=$wallet_name \
          --allora-chain-restore-mnemonic='$wallet_seed_phrase' \
          --allora-node-rpc-address=https://allora-rpc.testnet-1.testnet.allora.network/ \
          --allora-chain-topic-id=6
    volumes:
      - ./worker-topic-6-data:/data
    working_dir: /data
    depends_on:
      - inference
      - head
    networks:
      eth-model-local:
        aliases:
          - worker-topic-6
        ipv4_address: 172.22.0.13

networks:
  eth-model-local:
    driver: bridge
    ipam:
      config:
        - subnet: 172.22.0.0/24

volumes:
  inference-data:
  worker-topic-2-data:
  worker-topic-4-data:
  worker-topic-6-data:
  head-data:

EOL

echo "Setup complete. The 'docker-compose.yml' file has been created with the head-id and wallet seed phrase."
sudo docker compose up -d