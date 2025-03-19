
space voxel proof of concept

GOAL:
Make an engine capable of rendering an object 83,460,000,000,000^3 meters in size

Engine:

*- Reimplement existing codebase in zig
- Implement shader modules
- Implement Vulkan Render Pipelines
- Render a triangle
- Get screen resizing implemented
- Implement a basic vertex meshing algorithm
- Implement a basic chunking system for individual voxel entities
- Implement a basic collision system
- Implement gravity
- Recreate a simple model of the (Sol)ar System
- Implement textures for Boxels

- Add live shader reloading
- Add a shader editor
- Add basic debugging tools
- Add a benchmarking tool (Should run through various premade/predictable scenes for various intensive tasks (test worst case scenarios for chunks etc.))
- Optimize mesh generation
- Add shadows
- Add LODs w/ octrees
- Add acceleration structures and optimizations if necessary
- Add more sophisticated mesh based techniques (ie: Vercidium compression)
- Implement raymarched voxels (Should be the most optimal?)

GamePlay:
- Block breaking
- an inventory
- items
- factory blocks
- design and implement factory chains
- Maybe optimization of processes can be done through precision? things have to cool down for longer if it is too hot for example?
- Implement Physics blocks/interfaces
- Figure out how to make a very reliable gyroscope, potentially just an interface for control systems... End goal is to fascilitate UX for complex tools
- Implement multiblocks
- Implement Computers in some facet
- Decide how advanced or simple they should be, should they scale in ability? Should they be comprised of simple logic gates or should they be as capable as Computer Craft? Both?
- Add music playing and sounds
- Add atmospheres
- consider implementing a full Electro-Magnetic Spectrum, materials could filter and modify the EMS or camera blocks/items could interpret it as computer data. EMS could be important in certain processies etc. Could be quite out of scope though

- consider integrating cimgui

- Focus Primarily on developing interesting mechanics that are simple, yet deep.
- Guide the player. Maybe have a mode where you don't have access to the guide? Hardcore vs Legendary or something?
#IGNORE#- Determine how flexible we want the game play to be. Do we want emphasis of discovery? Or should we focus on automation and management?
- Decide the final scale of the game and what the engine is capable of. What compromises should be made to have fun instead of realism.

- Abstract physics and chunk storage to a seperate server application to make Multiplayer easier in the future
