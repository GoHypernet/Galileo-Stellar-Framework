<p align="center">
  <img src="https://cryptologos.cc/logos/stellar-xlm-logo.png?v=013" width="200">
</p>

# Galileo-Stellar Environment

## Overview
- **Industry**: Cryptocurrency, node hosting

- **Target Container OS**: Linux

- **Source Code**: open source

- **Github**: https://github.com/stellar/

## Notes

Stellar is a decentralized transaction network based on the Stellar Consensus Protocol which achieved federated Byzantine agreemeent. 
This repository couples the Galileo IDE with the official Stellar Core docker image. 

Running a node requires syncing with the Stellar network. 

This containerized application exposes the following reverse proxy endpoints:

- /* -> localhost:11625 (Peer connection port)
- /ui/* -> localhost:3000 (Galileo IDE + authentication)
 
Additionally, the runtime environment contains node and python 3.8 smart contract development. 

## Building

This container runtime is targeted at linux. To build the container run:

```
docker build -t algorand .
```