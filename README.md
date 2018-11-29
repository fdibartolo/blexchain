# Blexchain
[![Build Status](https://travis-ci.org/fdibartolo/blexchain.svg?branch=master)](https://travis-ci.org/fdibartolo/blexchain)

Mini blockchain implementation in Elixir

This development is inspired on Haseeb Qureshi Ruby's implementation:
  * His talk [here](https://www.youtube.com/watch?v=3aJI1ABdjQk)
  * His code [here](https://github.com/Haseeb-Qureshi/lets-build-a-blockchain)


## As for this code

### Build the docker image

Considering you are in the root directory of the repo, then

`$ docker build -t <IMAGE NAME> .`

Finally, create the network the future nodes will share, let's name it _blexnet_

`$ docker network create blexnet`

### Start the blockchain network

To start the network (genesis node), just start the first container, i.e.

`$ docker run --name node --network blexnet <IMAGE NAME>`

And then, to join consecutive nodes to the network, a peer ip address needs to be specified, i.e.

`$ docker run --name node2 --network blexnet -e PEER=172.18.0.2 <IMAGE NAME>`

`$ docker run --name node3 --network blexnet -e PEER=172.18.0.3 <IMAGE NAME>`

`$ docker run --name node4 --network blexnet -e PEER=172.18.0.2 <IMAGE NAME>`

`PEER` can be __any__ peer ip address already existing in the network.

### Submit a transaction

Even though any http client can be use to post to the api to submit a transaction, there is a mix task available for that as well (easier, right?). All three arguments must be specified, i.e.

`$ docker exec node3 mix blexchain.transfer from:172.18.0.2 to:172.18.0.3 amount:100`

`from` and `to` are the peer ip addresses whose nodes are listening on.
`node3` can actually be __any__ node in the network

---

To run the test suite locally, do so via `mix test`
