# ProtonGraph live sync add-on

This add-on allows you to drive [ProtonGraph](https://github.com/protongraph/protongraph)
from Godot 4. Inputs from your scene are sent to ProtonGraph, which sends the
generated models back to the Godot editor (or your game).

If you don't know what ProtonGraph is, this add-on might not be relevant to you.
Head over to [the project page](https://github.com/protongraph/protongraph) to
learn more about it.


## Status

+ Work in progress, many features are still missing.

+ Currently requires you to manually start ProtonGraph in the background, but
the plan is to ship the add-on with a size optimized binary that will be
automatically started in headless mode from the plugin script.

+ Although this add-on is meant to connect to a local instance of ProtonGraph
(running on the same machine), data is transfered between the two programs
through a websocket.
In theory, this means it could also work over the network if you want to sync
from a distant machine hosting ProtonGraph.
However there's a lot of edge cases that are not supported (certificates among
others), but there are plans to integrate ProtonGraph with a proper signaling
server, like Apache Kafka, in order to make network communication possible.


## How to use

+ Put the `proton_graph` folder in your add-ons folder.
+ Enable it in the `Project Settings`.
+ You can now add `ProtonGraph` nodes to your scenes.

Note: The ProtonGraph standalone app must be running for anything to happen.
For now, you have to start the instance manually, but this shouldn't be
mandatory in later versions.

+ Check the node inspector, you should see a panel showing the connection
status, make sure the node is connected to ProtonGraph.
+ Still in the node inspector, select a node graph file (.tpgn).
+ You should see the results from your node graph appear in the scene editor.
