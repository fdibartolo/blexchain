# Blexchain
[![Build Status](https://travis-ci.org/fdibartolo/blexchain.svg?branch=master)](https://travis-ci.org/fdibartolo/blexchain)

Mini blockchain implementation in Elixir

This development is inspired on Haseeb Qureshi Ruby's implementation:
  * His talk [here](https://www.youtube.com/watch?v=3aJI1ABdjQk)
  * His code [here](https://github.com/Haseeb-Qureshi/lets-build-a-blockchain)


## As for this code

### Start the network

To start the network (genesis node), specify the `PORT` it will be listening on, i.e.

`PORT=4000 mix phx.server`

And then, to join consecutive nodes to the network, a peer port needs to be specified, i.e.

  `PORT=4001 PEER=4000 mix phx.server`

  `PORT=4002 PEER=4001 mix phx.server`

  `PORT=4003 PEER=4000 mix phx.server`

`PEER` can be __any__ port already existing in the network.

### Submit a transaction

Even though any http client can be use to post to the api to submit a transaction, there is a mix task available for that as well (easier, right?). All three arguments must be specified, i.e.

  `$ mix blexchain.transfer from:4000 to:4001 amount:100`

`from` and `to` are the ports whose nodes are listening on.

---

To run the test suite locally, do so via `mix test`
