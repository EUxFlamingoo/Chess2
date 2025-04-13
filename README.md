The goal is to make a lightweight and modular chess framework, which can be used to make chess clones, turn based top down strategie games and similar.
Everything is horrible and unoptimized, I'm very much a beginner.
Initial setup was made with https://youtube.com/playlist?list=PLd_56bdSJ-tS4-q1gczTdKJhqMep3Ij_w&si=yFeAbLqsj4sf9zSc as a guide.
Everything is made in Godot 4.

- local 2 Player mode adhering to all conventional chess rules (done)
- single player mode against a simple Algorithm which can handle:
  - a few handprepared openings (black side: done)
  - assigning value to own and enemy pieces (done)
  - threat detection against its own pieces in it's own turn and capture/evade/block response (in progress)
  - greed response, take highest value enemy piece (done)
  - safety response, threat detection for next turn and randomly move to a not threatend empty field
  - fallback random response with no conditions (done)

- Additional rulesets which the non-player algorithm seemlessly adopts, for example
  - bigger & smaller board size
  - more & less pieces on both or one side
  - additional capabilities of pieces
  - additional new pieces
  - additional win/loose conditions
  - assigning own starting position with given pieces
  - selection of starting pieces
  - obsticals on board
  - make the pieces "walk" or "jump" using pathfinding
  - move multiple pieces in one turn
 - maybe:
   - z-axis capabilities
   - players choose their moves but both turns get resolved simultaniously in an "action phase"
   - online multiplayer capabilities

---------------------------------------------------------------------------------------------------------
Next to do:

bot acts on threat detection appropriately

---------------------------------------------------------------------------------------------------------
Log:

Apr 12, 2025

- added threat detection


Apr 11, 2025

- Tile location and piece identity succesfull mapped, back to two starting formations

- Experimental features moved to a separate script

- makes only greed move if value > 0 else greed

- greed ai done, and 2 example opening moves done


Apr 10, 2025

- Value Movement works, auto promote doesn't

- working random ai, ongoing value system

- inits (project already in progress)


