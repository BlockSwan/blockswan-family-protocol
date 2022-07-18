```
______ _            _    _____
| ___ \ |          | |  /  ___|
| |_/ / | ___   ___| | _\ `--.__      ____ _ _ __
| ___ \ |/ _ \ / __| |/ /`--. \ \ /\ / / _` | '_ \
| |_/ / | (_) | (__|   </\__/ /\ V  V / (_| | | | |
\____/|_|\___/ \___|_|\_\____/  \_/\_/ \__,_|_| |_|
```

# B-Family Protocol v1

This repository contains the smart contracts source code and markets configuration for B-Family Protocol V3.

## What is BlockSwan?

BlockSwan is a digital assets organisation powered by community intelligence.

## What is B-Family ?

B-Family is a decentralized protocol for online freelancers. Sellers supply digital services, buyers are allowed to contract them upon clear and defined rules while judges can resolve conflicts and capture a part of the protocol revenues.

## Contracts address

|             | Polygon Mumbai                             |
| ----------- | ------------------------------------------ |
| User Soul   | 0x96205CC540F9256448f507Bd695A9C37B7bADAD2 |
| Gig V1      | 0x66fbBfa3b7104E1F8Fc8089b5e843246e515fe70 |
| Gig Factory | 0x349Eebb43f0Ef6A1056a0e260f8664a8DD84bdDd |
| Fake USDC   | 0xAb2d097Fb4eBa52dc60842477564b381e1B85e56 |

## Documentation

See the link to the white paper or visit the BlockSwan Resources site

- [White Paper](https://resources.blockswan.family/whitepaper.pdf)

- [Resources site](https://resources.blockswan.family)

## Connect with the community

You can join at the [Discord](https://discord.com/invite/ffrzhYEn57) channel or at the [Twitter](https://twitter.com/BlockSwanHQ) for asking questions about the protocol or talk about BlockSwan with other peers.

## Getting Started

To install dependencies:

```
git clone https://github.com/BlockSwan/family-core-v1.git && cd family-core-v1
npm install
```

## Running tests

Before running the tests you need to create an enviroment file named `.env` and fill the next enviroment variables

```
# Add COIN MARKET CAP API key, enable or not GAS REPORTER
# Add your POLYGON API key as well as the SECRET KEY of the deployer address.
# Don't share this key anywhere!
COINMARKETCAP_API_KEY=
GAS_REPORTER_ENABLED=true
POLYGONSCAN_API_KEY=
DEPLOYER_PRIVATE_KEY=
```

You can run the full test suite with the following commands:

```
npx hardhat test
```
