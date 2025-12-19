# Welcome to Mini Ground Control, a Mini Metro like game focused on airport ground control.

## Basic concepts:

  - Camera is zoomed in on a single, expanding airport.
  - A minimalistic design is used. A grid like blueprint structure where runways, gates are designed. Taxi Corridors are created and planes land or takeoff as they like.
  - The goal is to take the passengers to their destinations as fast and as smooth as possible.
  - Planes that do not have enough space cycle around the airport and are wasting their fuel.
  - Game ends if a plan remains without fuel, a gate has too much of a delay/ flight is cancelled.

## Lifecycle of a plane

  - a plane approaches (to land safely you need to clear the runway)
  - after landing you must draw a path from the runway to a matching colored Gate
  - Plane loads baggage and passagers (a short timer)
  - Taxi out & departure. You must route it from the Gate back to a Runway queue.

## Interactivity

  - you have a limited number of taxiways and limited available space
  - you can make a taxiway a **One Way** road (preventing gridlocks)
  - you can create manual traffic light in intersections with a "Stop Bar"

  
### Implementation principles:
  
  - Tile types:
    - Empty space (buildable tile)
    - Runway (Fixed oneway strips with an **entrance** and an **exit**)
    - Terminal (large structures that spawn new **gates** sporadically)
    - Gates (Differently colored/shaped small structures that handle passengers embarking and disembarking from the planes).
    - Taxiways (planned roads that link the runways to the terminals and specifically gates)
  - The Plane (Finite State Machine) has multiple different states (This state determines its behavior and what it's waiting for): 
    - **APPROACHWaiting**: in an off-screen queue.A timer icon near the runway.
    - **LANDING**: Moving fast along the runway tiles. Locks the runway ***(no one else can use it)**. Smoke effect on touch-down.
    - **TAXI_IN**: Pathfinding from Runway Exit to Assigned Gate. Slow movement.
    - **SERVICING**: Parked at Gate. A timer fills up (Loading passengers). Progress bar circle.
    - **TAXI_OUT**: Pathfinding from Gate to Runway Entrance. Slow movement.
    - **TAKEOFF**: Moving fast along runway. **Locks the runway**. Engines roaring (shake effect).

  
  uses A* or BFS algo for path to the gate calculation
  Built using raylib-zig and zig.


 ------ Todo -------
 
 - [x] link raylib to my zig project
 - [x] set the background as a light blue (blueprint)
 - [x] draw a grid structure with dashed white lines
 - [ ] choose a tile size and make a map of tiles (a 2d array of tiles, coordinates and type).
 - [ ] define a road look and feel
 - [ ] switch a tile by clicking from empty to a road
