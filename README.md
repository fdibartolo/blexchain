# Blexchain

Mini blockchain implementation in Elixir

This development is inspired on Haseeb Qureshi Ruby's implementation:
  * His talk [here](https://www.youtube.com/watch?v=3aJI1ABdjQk)
  * His code [here](https://github.com/Haseeb-Qureshi/lets-build-a-blockchain)


## As for this code

To start the network (genesis node), run `PORT=4000 mix phx.server`

And then, to join consecutive nodes to the network, a peer port needs to be specified, i.e.

  `PORT=4001 PEER=4000 mix phx.server`

  `PORT=4002 PEER=4001 mix phx.server`

  `PORT=4003 PEER=4000 mix phx.server`

`PEER` can be __any__ port already existing in the network.

Test suite run via `mix test`
