#!/bin/bash

# Pre-requisites
# sudo apt install -y docker-compose
# sudo apt install -y build-essential
# sudo snap install go --classic

# Download Fabric and Fabric-samples
mkdir -p $HOME/go/src/github.com/hyperledger
cd $HOME/go/src/github.com/hyperledger
curl -sSL http://bit.ly/2ysbOFE | bash -s -- 2.2.2 1.4.9
cd fabric-samples && git checkout v2.2.2
cd .. && git clone https://github.com/hyperledger/fabric && cd fabric && git checkout release-2.2

# Environment preparation
cd fabric-samples/test-network
./network.sh up createChannel -ca -s couchdb
source ./addOrg1.sh
source ./addOrg2.sh

# Package the chaincode
peer lifecycle chaincode package simple_chaincode.tar.gz --path ../chaincode/simple_chaincode/ --lang node --label simple_chaincode_1.0

# Install the chaincode in the peers
peer lifecycle chaincode install simple_chaincode.tar.gz

# Approve the chaincode in both peers
export PACKAGE_ID=simple_chaincode_1.0:4cee77dfe4b8965e3865d72fea6c0893d9589fb317c543e2f8fe8a13979277cd
peer lifecycle chaincode approveformyorg -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name simple_chaincode --version 1.0 --package-id $PACKAGE_ID --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

# Commit the chaincode in the channel
peer lifecycle chaincode checkcommitreadiness --channelID mychannel --name simple_chaincode --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --output json
peer lifecycle chaincode commit -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --channelID mychannel --name simple_chaincode --version 1.0 --sequence 1 --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt

# Invoke the chaincode
peer chaincode invoke -o localhost:7050 --ordererTLSHostnameOverride orderer.example.com --tls --cafile ${PWD}/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem -C mychannel -n simple_chaincode --peerAddresses localhost:7051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt --peerAddresses localhost:9051 --tlsRootCertFiles ${PWD}/organizations/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/tls/ca.crt -c '{"function":"put","Args":["string", "a", "b"]}'

# Query the chaincode
peer chaincode query -C mychannel -n simple_chaincode -c '{"function":"get","Args":["string", "a"]}'

