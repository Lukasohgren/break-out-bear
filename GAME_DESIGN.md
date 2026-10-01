# BREAK OUT BEAR — GAME DESIGN DOCUMENT

Version: 0.1
Status: Early Design
Engine: Godot 4.x
Genre: Cooperative Stealth / Puzzle Adventure
Players: 2–5
Platform: PC
Perspective: 3/4 top-down perspective


# HIGH-LEVEL CONCEPT

Break Out Bear is a cooperative 3D stealth and puzzle game in which a group
of toys come alive after a toy store closes for the night.

Their goal is simple:

Escape the toy store without being caught.

The players must work together to navigate through different sections of
the store, solve environmental puzzles, carry useful objects, avoid security
guards and eventually reach the loading bay at the back of the building.

The final escape takes place by reaching a truck/container positioned outside
the loading bay.

The game is designed primarily around cooperation, environmental problem
solving, stealth and moments of tension rather than combat.


# GAME FANTASY

The player should feel like a small toy inside a large human environment.

Normal objects such as:

- shelves,
- counters,
- tables,
- cardboard boxes,
- doors,
- display stands,
- shopping carts,
- vents,
- toys,
- keys,

may become obstacles, hiding places, traversal tools or puzzle components.

The environment should feel significantly larger because of the toys'
small scale.

The fantasy is:

"We are tiny toys trying to secretly escape a huge toy store after closing."


# VISUAL DIRECTION

Use the images inside:

prompt-images/

as primary visual references for the intended atmosphere and perspective.

Important references include:

- game-overview.jpg
- characters.jpg
- preview-characters.jpg

The intended visual style is:

- Stylized 3D
- Warm toy-store aesthetic
- Dark nighttime environment
- Strong localized lighting
- Colorful toys against darker surroundings
- Cozy but suspenseful atmosphere
- Large environments viewed from a small character's perspective

The camera uses an elevated 3/4 top-down perspective.

The game should not look like a completely vertical top-down game.

The environment should remain readable while still allowing shelves,
furniture and other objects to obscure parts of the player's view.


# DESIGN PILLARS

The game should be built around four primary design pillars.


## 1. COOPERATION

Players should regularly benefit from working together.

Examples:

- carrying important objects,
- discovering puzzle solutions,
- distracting guards,
- opening paths for other players,
- moving objects into useful positions,
- coordinating movement through dangerous areas.

Players should not feel like five independent characters completing the
same single-player level.


## 2. STEALTH AND TENSION

Security guards create pressure.

Players should:

- observe patrol routes,
- wait for opportunities,
- move between safe areas,
- hide when necessary,
- react when a guard becomes suspicious,
- escape during a chase.

The game should create tension without becoming a combat game.


## 3. ENVIRONMENTAL PUZZLES

Progress through the store should require figuring out how the environment
can be manipulated.

Puzzles may involve:

- finding keys,
- transporting objects,
- climbing using movable objects,
- activating buttons,
- accessing higher shelves,
- opening doors,
- combining actions between multiple players,
- reaching locations that initially appear inaccessible.

The solution should often involve understanding the environment rather than
simply locating a button.


## 4. TOY-SCALE EXPLORATION

The store should feel enormous from the perspective of a toy.

Everyday human objects can become gameplay elements.

Examples:

A cardboard box may become a staircase.

A shelf may become a platforming challenge.

A counter may become an entire elevated area.

A small opening beneath furniture may become a safe route that a guard
cannot access.


# PLAYER COUNT

Minimum players:

2

Maximum players:

5

The game is designed primarily as a cooperative multiplayer experience.

Puzzle design should account for different player counts.

Avoid designing required puzzles that only function with exactly five
players.

Whenever practical, puzzle solutions should scale between 2–5 players.


# PLAYER CHARACTERS

Players control living toys.

Initial characters are primarily cosmetic from a gameplay perspective.

Future versions may introduce character-specific abilities.

Possible characters based on the current concept include:

- Bear
- Frog
- Robot
- Duck
- Doll

The exact playable roster may change.


# FUTURE CHARACTER ABILITIES

Character-specific abilities are an intended future feature but are NOT
required for the first playable version.

The long-term goal is for different toys to have small abilities based on
their physical characteristics.

Example:

Frog

Normal characters can carry:

1 object

The Frog could eventually carry:

- 1 object in its hands
- 1 additional object in its mouth

Total:

2 objects

Future character abilities should:

- encourage cooperation,
- create different approaches to puzzles,
- remain simple to understand,
- avoid making one character mandatory for large sections of the game unless
  the character selection system guarantees availability.

Do not implement character-specific abilities during the initial development
phase.


# PLAYER MOVEMENT

Initial movement should be simple and responsive.

Controls:

W
Move forward relative to the camera/view.

S
Move backward relative to the camera/view.

A
Move left relative to the camera/view.

D
Move right relative to the camera/view.

Space
Jump.

A and D are used for lateral movement / strafing, NOT character rotation.

Movement should be camera-relative so that controls remain intuitive from
the fixed 3/4 top-down perspective.

For example:

- W moves toward the upper/forward direction of the visible game world.
- S moves toward the lower/backward direction.
- A moves toward the left side of the visible game world.
- D moves toward the right side of the visible game world.

The camera's vertical pitch must not influence vertical player movement.

The character should smoothly rotate to face its current movement direction.

When the player stops moving, preserve the last facing direction.

Diagonal movement must not be faster than movement along a single axis.

Movement should feel responsive and game-like rather than physically realistic.


# JUMPING

Players can jump.

Jumping is intended primarily for:

- traversal,
- climbing objects,
- reaching shelves,
- navigating environmental obstacles,
- interacting with puzzle layouts.

Jumping is not intended to become highly technical platforming during the
initial version.

The toy's jump height should eventually be balanced around the physical
scale of environmental props.


# CAMERA

The camera uses a 3/4 top-down perspective.

The visual references in prompt-images/ define the intended general
composition.

The camera should:

- follow the player's character,
- remain elevated above the environment,
- look diagonally downward,
- show a useful amount of the surrounding room,
- preserve visibility during stealth situations,
- make guard patrol routes understandable,
- make the guard's vision/light readable.

The camera should not behave like:

- first-person,
- over-the-shoulder third-person,
- completely vertical top-down.

Exact:

- pitch,
- yaw,
- distance,
- height,
- field of view,

should remain tunable during development.


# MULTIPLAYER CAMERA

The intended camera follows the player group rather than a single character.

The camera target should be calculated from the positions of all currently
active players.

When players move around the environment, the camera should smoothly follow
the center of the group.

For example, if three players form a triangle, the camera should frame the
group from approximately the center of their positions rather than locking
onto one specific player.

The camera should maintain the established 3/4 top-down viewing angle.

Long-term, the camera should be capable of adjusting its framing when players
spread apart so that all relevant players remain visible.

Potential future behaviour includes:

- dynamic camera distance or zoom based on player spread,
- configurable screen-edge padding,
- room-specific camera boundaries,
- maximum zoom-out distance,
- handling players who move unusually far away from the group.

These advanced behaviours should not be implemented until the basic
group-follow camera works correctly.


# CORE GAMEPLAY LOOP

The basic gameplay loop is:

Enter a new area
↓
Observe the environment
↓
Understand the puzzle/problem
↓
Locate useful objects or routes
↓
Observe guard behaviour
↓
Coordinate with teammates
↓
Move objects / solve puzzle
↓
Avoid or escape guards
↓
Unlock access to the next area
↓
Continue deeper into the store

Eventually:

Reach loading bay
↓
Open / access final escape route
↓
Reach truck/container
↓
Escape the store
↓
Win


# LEVEL STRUCTURE

The initial game should contain one large interconnected toy store.

It is not currently intended to use traditional separate levels.

Instead, the store contains multiple:

- rooms,
- departments,
- corridors,
- storage areas,
- puzzle spaces,
- restricted areas.

Progress through the store gradually unlocks new sections.

Conceptually:

Starting Area
↓
Store Section
↓
Puzzle / Access Challenge
↓
Next Section
↓
Puzzle / Stealth Challenge
↓
Additional Store Areas
↓
Back-of-house area
↓
Loading Bay
↓
Truck / Container
↓
Escape


# TARGET PLAYTIME

The first complete store escape should take approximately:

45–90 minutes

for a group of new players.

This includes time spent:

- exploring,
- understanding the environment,
- figuring out puzzles,
- making mistakes,
- avoiding guards,
- coordinating with teammates.

Experienced players will naturally complete the level faster.

The initial target should prioritize an enjoyable first-time experience rather
than artificially forcing a specific duration.


# ROOM / AREA DESIGN

Different sections of the store should present different combinations of:

- exploration,
- stealth,
- puzzles,
- traversal,
- object manipulation.

Not every area needs all of these mechanics.

For example:

Area A
Primarily teaches movement and object interaction.

Area B
Introduces a simple guard patrol.

Area C
Requires carrying an object through a guarded area.

Area D
Introduces vertical traversal using shelves and boxes.

Area E
Requires multiple players to cooperate.

Later areas may combine several previously introduced mechanics.


# PUZZLE DESIGN

Puzzles should primarily be environmental and cooperative.

Potential puzzle types include:

## KEY PUZZLES

Players find a key and transport it to a locked location.


## MOVEMENT / PLATFORM PUZZLES

Players move an object such as a box into position to reach:

- a shelf,
- button,
- opening,
- key,
- alternate path.


## COOPERATIVE PUZZLES

Multiple players perform different actions.

Examples:

- one player holds a button while another passes through,
- one player distracts a guard,
- one player moves an object while another climbs,
- players transport multiple items to different locations.


## SEARCH PUZZLES

Players investigate the environment to determine what item or location is
required.


## SEQUENCE PUZZLES

Players activate objects in a particular order.


# OBJECT SYSTEM

Each player can initially carry:

1 object

Examples include:

- keys,
- boxes,
- puzzle pieces,
- tools,
- small toys,
- required environmental objects.

A carried object should be visually associated with the player.

Players should be able to:

- pick up an object,
- carry it,
- move while carrying it,
- drop it.

Additional interactions may be introduced later.


# OBJECT DESIGN PRINCIPLES

Objects should have understandable purposes.

Avoid filling environments with large numbers of interactable objects that
have no gameplay relevance unless they provide meaningful environmental
interaction.

Important puzzle objects should be identifiable without always requiring
explicit UI markers.

Environmental design should help communicate what can be used.


# STEALTH SYSTEM

The primary threat is the toy store's security guards.

Guards patrol areas looking for suspicious activity.

The player cannot defeat guards through normal combat.

Players instead survive using:

- positioning,
- timing,
- hiding,
- escape routes,
- environmental awareness,
- cooperation.


# GUARD PATROL

Guards normally follow predefined patrol routes.

A patrol may include:

- walking between patrol points,
- stopping,
- looking in specific directions,
- waiting,
- continuing along the route.

Patrols should be predictable enough that observant players can understand
them.

However, they should still create tension and require timing.


# GUARD VISION

The guard carries a flashlight.

The flashlight represents the guard's primary visible detection area.

Conceptually:

Guard
↓
Flashlight / vision cone
↓
Player enters visible area
↓
Guard detects player
↓
Guard begins chase

The light should clearly communicate danger to players.

Players should normally understand whether they are:

- safe,
- close to detection,
- inside the guard's vision.

The flashlight should therefore be both:

- a visual effect,
- a gameplay readability tool.


# DETECTION

CURRENT DESIGN ASSUMPTION:

Being seen does NOT immediately end the game.

Instead:

Player enters guard vision
↓
Guard detects player
↓
Guard abandons patrol
↓
Chase begins

This assumption should be confirmed before the stealth system is implemented.


# GUARD CHASE

When a guard detects a toy:

1. The guard abandons its normal patrol.
2. The guard begins pursuing the detected player.
3. The guard moves faster than during normal patrol.
4. The player must escape the guard's awareness.
5. Hiding or breaking detection can end the chase.

The chase should create a clear increase in tension compared with patrol
behaviour.


# HIDING

Players should be able to hide from guards.

Possible hiding locations include:

- underneath tables,
- inside or behind shelving,
- behind objects,
- inside designated hiding spaces,
- other environment-specific locations.

The exact hiding system has not yet been finalized.

Possible implementations may include:

- physical line-of-sight hiding,
- explicit hiding locations,
- a combination of both.

This should be decided before implementation.


# LOSING THE GUARD

Initial design target:

If the guard cannot locate the player for approximately:

8 seconds

after the player successfully hides or breaks detection, the guard stops
actively chasing.

The guard then returns to its normal patrol behaviour.

The exact timing should remain configurable during playtesting.

Potential state flow:

PATROL
↓
DETECTED
↓
CHASE
↓
SEARCH
↓
RETURN_TO_PATROL
↓
PATROL


# MULTIPLE GUARDS

Larger or more dangerous areas may contain multiple guards.

Guard count should be based on:

- room size,
- number of safe paths,
- available hiding locations,
- puzzle complexity,
- expected number of players.

More guards should create more interesting coordination rather than simply
making an area frustrating.


# GUARD AI PRINCIPLES

Guards should feel predictable enough to learn but dynamic enough to create
tension.

The player should generally be able to understand why they were detected.

Avoid:

- detection through solid walls,
- unexplained instant detection,
- guards knowing player locations without information,
- unpredictable teleporting,
- arbitrary failure.

Guard behaviour should communicate its current state through movement,
lighting, animation, audio or a combination of these.


# COMBAT

There is currently no planned player combat system.

Players should not defeat guards using weapons.

The primary responses to danger are:

- avoid,
- hide,
- escape,
- distract,
- cooperate.

Do not implement combat unless the game design changes later.


# CAPTURE AND FAILURE SYSTEM

Being detected does not immediately cause failure.

The intended sequence is:

Player enters guard vision
↓
Guard detects player
↓
Chase begins
↓
Player attempts to escape or hide
↓
Guard physically catches player
↓
Player is captured


## INDIVIDUAL CAPTURE

When a guard catches a toy, that individual player is temporarily captured.

The other players remain active.

The captured toy is moved to an appropriate holding location within the
store.

Potential thematic locations include:

- Lost & Found
- security storage
- returns bin
- locked storage container

The exact location may depend on the current area.

Other players should be able to rescue captured teammates.

The rescue system should create cooperative gameplay without leaving the
captured player inactive for an excessive amount of time.


## TEAM SECURITY LEVEL

Each player capture increases a shared team-wide Security Level.

The Security Level represents how suspicious store security has become.

Example:

Capture 1
→ Security Level increases

Capture 2
→ Security Level increases again

...

Maximum Security Level
→ Store lockdown
→ Team failure

The maximum number of captures should be configurable and may scale based
on player count.

Initial balancing concept:

2 players → 3 captures
3 players → 4 captures
4 players → 5 captures
5 players → 6 captures

These values are placeholders and must be determined through playtesting.


## FUTURE SECURITY ESCALATION

In future versions, higher Security Levels may affect guard behaviour.

Possible effects include:

- longer searches,
- modified patrol routes,
- additional guards,
- shorter patrol pauses,
- increased alertness.

These behaviours are NOT required for the initial implementation.


## FULL FAILURE

When the team reaches the maximum Security Level, the store enters lockdown.

This causes the team's current attempt to fail.

The exact reset behaviour should be determined during level design.

Preferred direction:

For the full 45–90 minute experience, major sections of the store may act
as checkpoints so that a late failure does not necessarily require replaying
the entire game from the beginning.


# WIN CONDITION

The players win by successfully escaping the toy store.

The final objective is located at the back of the building.

Players eventually reach:

Loading Bay
↓
Open / access loading area
↓
Reach waiting truck/container
↓
All required players enter the escape area
↓
Escape
↓
Victory

The player should be able to see that the truck/container leads outside the
store.

The ending should create a strong feeling that the toys have successfully
escaped into the outside world.


# MULTIPLAYER DESIGN

The game supports:

2–5 players.

Cooperation should provide meaningful gameplay advantages.

Players should be able to:

- explore together,
- split up,
- carry different puzzle objects,
- distract guards,
- communicate puzzle discoveries,
- help each other reach areas.

Puzzle design should avoid requiring one exact player count whenever
possible.


# MULTIPLAYER PRINCIPLE

A player leaving or making a mistake should not permanently make a puzzle
impossible whenever this can reasonably be avoided.

Critical puzzle objects should not become permanently lost.

The level should provide recovery from normal player mistakes.


# DIFFICULTY

Difficulty should primarily come from:

- understanding puzzles,
- reading patrol patterns,
- coordinating with teammates,
- navigating safely,
- making decisions under pressure.

Difficulty should not primarily come from:

- extremely precise platforming,
- unclear mechanics,
- random guard behaviour,
- hidden information with no clues,
- excessive punishment.


# AUDIO DIRECTION

Audio should contribute strongly to stealth readability.

Potential guard audio cues include:

- footsteps,
- keys or equipment moving,
- flashlight activation,
- alert sounds,
- chase music,
- guard vocal reactions.

Players should sometimes be able to hear a guard before seeing them.

Music should support the contrast between:

- playful toy-store atmosphere,
- quiet exploration,
- tense stealth,
- active pursuit.


# GAME FLOW — INITIAL TARGET

The first full playable experience may roughly follow:

1. Toys awaken after the store closes.

2. Players learn basic movement.

3. Players learn how to pick up and drop objects.

4. First simple environmental puzzle.

5. First guard is introduced.

6. Players learn guard vision and patrol behaviour.

7. Players learn hiding / escaping.

8. Store areas become larger and more complicated.

9. Puzzles require transporting objects through guarded spaces.

10. Cooperative challenges become more important.

11. Multiple guards may appear.

12. Players reach staff / warehouse areas.

13. Final puzzle opens access to the loading bay.

14. Players reach the waiting truck/container.

15. Escape sequence.

16. Victory.


# SCOPE — FIRST PLAYABLE VERSION

The first playable prototype should NOT attempt to create the entire
45–90 minute experience.

The prototype should prove the core game concept.

Initial prototype goals:

- One playable toy.
- Basic movement.
- Jumping.
- One small test environment.
- One carryable object.
- Pick up and drop behaviour.
- One guard.
- Basic patrol.
- Flashlight / vision detection.
- Basic chase behaviour.
- Basic hiding / losing the guard.
- One simple environmental puzzle.
- One multiplayer-capable gameplay foundation.

The prototype should answer:

"Is moving around as a toy, manipulating objects and avoiding a guard fun?"

Only expand toward the complete toy store after the core loop works.


# FUTURE FEATURES

Potential future features include:

- Character-specific abilities.
- Multiple character types.
- More advanced cooperative puzzles.
- Environmental distractions.
- More guard behaviours.
- Additional hiding mechanics.
- Different types of security enemies.
- More complex object interaction.
- Improved animations.
- Character customization.
- Replayability systems.

These are future possibilities, not current implementation requirements.


# OUT OF SCOPE FOR INITIAL DEVELOPMENT

Do not prioritize:

- combat,
- large character ability systems,
- complex progression systems,
- skill trees,
- procedural generation,
- large inventories,
- crafting,
- advanced character customization,
- many enemy types,
- multiple full levels.

The first priority is proving the core cooperative stealth/puzzle experience.


# CORE EXPERIENCE TEST

When evaluating a new feature, ask:

Does this improve at least one of these?

- Cooperation
- Stealth
- Environmental problem solving
- Toy-scale exploration
- Player readability
- Tension

If not, consider whether the feature is necessary.


# OPEN DESIGN QUESTIONS

The following decisions are intentionally unresolved and should be answered
before their respective systems are finalized:

1. What exactly happens when a guard catches a player?

2. Does one captured player fail the entire team?

3. Can captured players be rescued?

4. How exactly does entering a hiding location work?

5. Does breaking line of sight start the 8-second escape timer immediately,
   or does the guard actively search nearby first?

6. Can guards hear players or objects, or is detection initially visual only?

7. Can players intentionally distract guards?

8. Do guards react to dropped / thrown objects?

9. Can all toys jump equally high?

10. Are character abilities selected before starting the game?

11. Must every player reach the truck to win?

12. What happens if a player disconnects during a puzzle?

13. Does a room reset after failure, or does the whole run restart?

14. Will players have unlimited retries?

These decisions do not need to be solved before basic movement and environment
prototyping begins.