# Deliver a Parcel --- World Layout Blueprint

**Document:** World Layout Blueprint\
**Version:** 0.1\
**Project:** Deliver a Parcel (Roblox)\
**Phase:** Phase 1 --- Concept Validation & Game Design\
**Status:** Draft for review\
**Design baseline:** Mixed Philippine provincial/developing-suburban
setting; stylized low-poly art direction; adventure-oriented atmosphere;
expandable world.

------------------------------------------------------------------------

## 1. Purpose

This document translates the approved world direction into a practical
spatial blueprint for the first playable town and its future expansion.

It defines:

-   The town's spatial organization and district relationships.
-   The proposed road hierarchy and navigation logic.
-   The placement logic for the warehouse, customer houses, home lots,
    landmarks, and encounter areas.
-   The intended delivery routes and environmental progression.
-   Expansion boundaries and technical considerations.

This is a **design blueprint**, not a final Roblox Studio map, terrain
model, or surveyed coordinate plan. Dimensions and placements marked
provisional must be validated through blockout and playtesting.

## 2. Confirmed design decisions

  -----------------------------------------------------------------------
  Decision                            Direction
  ----------------------------------- -----------------------------------
  Setting                             Mixed Philippine provincial and
                                      developing-suburban town

  Visual style                        Stylized low-poly

  Atmosphere                          Adventure-oriented, with stronger
                                      exploration and nighttime tension

  World scale                         Expandable beyond the original town

  Initial map reference               Approximately 340 × 340 metres

  Core delivery model                 Ride to the customer's gate, park,
                                      then complete the final approach on
                                      foot

  Multiplayer                         Cooperative, while keeping solo
                                      play viable

  Session target                      Approximately 20--40 minutes
  -----------------------------------------------------------------------

### Design principles

1.  **Readable geography:** Players should learn the town through
    landmarks, road shapes, and repeated routes.
2.  **Natural progression:** The town should become less developed and
    more atmospheric toward its outskirts.
3.  **Gameplay-first layout:** Roads, gates, fences, alleys, and open
    spaces should support delivery decisions and encounters.
4.  **Expandable structure:** Future districts should connect naturally
    without requiring a complete redesign of the original town.
5.  **Mobile-aware scale:** Travel distances and visual clutter must
    remain manageable on smaller screens.

## 3. World organization

The initial town should be treated as a compact municipality with a
central service hub, surrounding neighborhoods, and a rural edge.

### 3.1 Districts

  -----------------------------------------------------------------------------
  ID             District       Primary        Main gameplay  Initial-release
                                character      role           priority
  -------------- -------------- -------------- -------------- -----------------
  A              Town Center    Developed,     Orientation,   High
                                busy, paved    short          
                                streets, shops deliveries,    
                                and public     social         
                                buildings      activity       

  B              Residential    Dense homes,   Standard       High
                 East           gates, fences, delivery       
                                narrow streets routes and dog 
                                               encounters     

  C              Residential    Mixed homes,   Standard and   High
                 West           larger         moderately     
                                properties,    challenging    
                                varied street  deliveries     
                                shapes                        

  D              Logistics /    Warehouse,     Order          High
                 Warehouse      loading area,  acceptance,    
                                vehicle        package        
                                services       collection,    
                                               ride           
                                               progression    

  E              Community      Basketball     Landmark       Medium
                 District       court, pond,   navigation and 
                                public         social         
                                facilities and activity       
                                open space                    

  F              Rural          Fields, dirt   Longer         High if required
                 Outskirts      or gravel      deliveries and by order range
                                roads,         exploration    
                                isolated homes                

  G              Cemetery       Tombs, mature  Night          Medium; core
                 District       trees, limited encounters,    encounter area
                                lighting and   Undas content  
                                fog-prone      and special    
                                spaces         jobs           

  H              Expansion      Undeveloped    Future         Reserve only
                 Reserve        terrain and    districts and  
                                planned road   content        
                                corridors                     
  -----------------------------------------------------------------------------

Districts are logical design areas, not necessarily separate technical
map instances. The initial release should prioritize a coherent,
polished core rather than filling every zone with content.

### 3.2 Spatial relationship

The following is a conceptual relationship map. It is not a
scale-accurate drawing.

``` text
                         NORTH
              [ Rural Expansion Reserve ]
                           |
                 [ Rural Outskirts ]
                           |
       [ Residential West ]---[ Cemetery District ]
                |                  |
                |             [ Outer Road ]
                |                  |
 [ Community ]--[ Town Center / Warehouse ]--[ Residential East ]
                |                  |
                |             [ Outer Road ]
                |                  |
          [ Future Link ]----[ Southern Expansion ]
                           |
                         SOUTH
```

The warehouse and town center should be easy to find from the main
roads. The cemetery should be on the outer edge rather than directly
beside the busiest commercial area. Rural routes should branch outward
from the residential and outer-road network.

## 4. Coordinate and blockout convention

To make the blueprint implementable, use a simple planning coordinate
system during blockout.

-   Set the initial map's approximate center to `(0, 0)`.
-   Use the warehouse hub as the primary orientation landmark, close to
    the center of the initial playable area.
-   Treat the original 340 × 340 m footprint as a planning reference,
    not a final hard boundary.
-   Use north as the top of planning diagrams.
-   Keep a consistent grid and document any intentional deviations.

### 4.1 Provisional planning zones

For the first blockout, divide the initial footprint into a 3 × 3
planning grid. These are broad zones, not exact district dimensions.

  -----------------------------------------------------------------------
  Zone                                Intended use
  ----------------------------------- -----------------------------------
  North-West                          Residential West / community
                                      connection

  North-Centre                        Town Center and main approach

  North-East                          Residential East

  Middle-West                         Community District and residential
                                      connector

  Middle-Centre                       Warehouse hub and primary
                                      intersections

  Middle-East                         Residential East / commercial
                                      connector

  South-West                          Residential West and future road
                                      link

  South-Centre                        Cemetery access / outer-road
                                      connection, subject to sightline
                                      testing

  South-East                          Rural transition and expansion
                                      reserve
  -----------------------------------------------------------------------

The exact cemetery and rural placement should be decided after a
visibility and route blockout. Do not force a location if it creates
poor delivery routes or makes the cemetery visible from the safe hub in
a way that weakens its atmosphere.

### 4.2 Blockout measurements to validate

  -----------------------------------------------------------------------
  Element                             Initial planning guidance
  ----------------------------------- -----------------------------------
  Original core footprint             Approximately 340 × 340 m

  Main roads                          Wide enough for two-way vehicle
                                      movement and passing

  Residential streets                 Narrower, slower, with clear
                                      turning and parking areas

  Alleys                              Optional shortcuts; avoid routes
                                      that trap vehicles or players

  Customer approach                   A clear gate/parking zone plus a
                                      short on-foot path

  Home lots                           Preserve the existing concept of
                                      seven individual lots

  Lot spacing                         Existing source concept says at
                                      least 72 m apart; verify
                                      feasibility against lot dimensions
                                      and usable map area

  Expansion corridors                 Reserve road connections beyond the
                                      initial footprint
  -----------------------------------------------------------------------

**Important validation:** Seven lots separated by at least 72 m may
consume a substantial amount of the original map. Confirm whether the 72
m refers to lot-centre spacing, boundary-to-boundary spacing, or
approximate separation. Do not silently interpret it as a final
constraint.

## 5. Road network

The road system should make navigation intuitive while allowing multiple
delivery approaches.

### 5.1 Road hierarchy

**Primary road / outer loop** - Connects the main districts. - Provides
the most reliable route for vehicles. - Helps players understand the
town's overall shape. - Should have clear intersections and recognizable
landmarks.

**Secondary district roads** - Connect residential areas, the warehouse,
shops, and community locations. - Provide the normal routes used by most
deliveries. - Should offer more than one approach to larger
neighborhoods where practical.

**Local residential streets** - Lead to individual customer houses. -
Include gates, driveways, fences, and roadside props. - Must allow
players to identify the correct customer property.

**Service paths and shortcuts** - Footpaths, alleys, narrow lanes, or
rural tracks. - May offer shorter routes but should have clear
trade-offs. - Avoid making a shortcut mandatory for ordinary deliveries.

### 5.2 Road design rules

1.  Avoid excessive four-way intersections. Use T-junctions and bends to
    create recognizable street layouts.
2.  Give each district a distinct road character without making the
    driving controls inconsistent.
3.  Keep the customer's gate and final approach visually obvious.
4.  Avoid placing large props, trees, or parked vehicles where they
    obstruct required vehicle movement.
5.  Use road signs, distinctive buildings, lighting, and vegetation to
    help players navigate.
6.  Ensure that a player on foot can reach every required delivery
    entrance.
7.  Do not allow decorative fences or terrain to create accidental dead
    ends.

### 5.3 Delivery-route design

Each customer location should have: - A vehicle-accessible approach. - A
recognizable stopping or parking area near the gate. - A clear route
from the gate to the delivery interaction point. - Enough room for the
player and carried package. - A safe fallback path if the player is
chased or obstructed.

The final on-foot approach is a signature gameplay moment. It should be
consistent enough for players to understand, but varied through gate
placement, yard layout, dog position, obstacles, and route visibility.

## 6. Key landmark placement

Landmarks should be visible from useful approach directions and should
help players build a mental map.

  ------------------------------------------------------------------------
  Landmark                Placement logic          Visual identity
  ----------------------- ------------------------ -----------------------
  Warehouse               Near the central road    Large roof, loading
                          network                  bay, conveyor, clear
                                                   signage

  Vehicle dealer          Near the hub but not     Displayed rides and
                          blocking warehouse       recognizable storefront
                          access                   

  Mechanic                Opposite or clearly      Garage doors, tools,
                          separated from dealer,   vehicle props
                          consistent with the      
                          existing concept         

  Sari-sari stores        Distributed through      Colorful awning,
                          residential/commercial   counter, signage
                          streets                  

  Basketball court        Community District       Open court, hoop
                                                   silhouettes, fencing

  Pond                    Community or green-space Distinct water shape,
                          area                     surrounding vegetation

  Barangay/public         Town Center or Community Civic building, flag,
  facility                District                 notice board

  Cemetery entrance       Outer district           Gate, signage, trees,
                          transition               visible path

  Player home lots        Residential edge or      Clear plot boundaries
                          dedicated home-lot area  and distinct entrances
  ------------------------------------------------------------------------

Avoid placing every landmark directly beside the warehouse. A few
minutes of exploration should reveal additional places without making
the town difficult to navigate.

## 7. Customer-house distribution

The existing concept includes 21 customer houses in three sizes. The
initial layout should distribute them across different delivery
environments rather than clustering them in one street.

### 7.1 Proposed distribution

  ---------------------------------------------------------------------------
  Group                            Count Intended         Delivery character
                                         environment      
  ---------------- --------------------- ---------------- -------------------
  Town / inner                         7 Developed        Shorter routes,
  residential                            streets and      beginner-friendly
                                         dense houses     

  Outer                                7 Mixed homes and  Moderate routes and
  residential                            narrower roads   more varied gates

  Rural / edge                         7 Less-developed   Longer routes and
  properties                             roads and        more exploration
                                         isolated houses  
  ---------------------------------------------------------------------------

This is a proposed distribution for blockout. It does not establish the
final customer-house coordinates or exact house-size allocation.

### 7.2 House-size variation

Use the three existing house-size categories to vary: - Front-yard
depth. - Gate type and width. - Distance from road to door. - Fence
height and visibility. - Available parking space. - Yard obstacles and
landscaping.

House size should not automatically determine dog difficulty or reward.
Keep those systems independently configurable.

### 7.3 Delivery interaction consistency

Every delivery house must have a clear and testable interaction setup: -
Unique customer/house identifier. - Correct delivery interaction
point. - Valid approach path. - Gate and property collision tested. -
Dog spawn/patrol area if applicable. - Clear feedback when the player is
too far away or at the wrong property.

## 8. Individual home lots

The existing concept includes seven individual home lots, with
persistent ownership and the ability to visit other players' properties.

### Layout requirements

-   Keep plots visually distinct from ordinary customer houses.
-   Provide a clear entrance and plot boundary.
-   Reserve enough space for the largest planned home.
-   Allow reasonable placement of decorations and garden elements.
-   Avoid blocking public roads or other players' access.
-   Ensure a visiting player can identify the owner and enter permitted
    areas.

The existing design notes specify at least 72 m between home lots. This
should be tested against the selected lot dimensions and map footprint
before it becomes a hard layout rule.

### Multiplayer requirements

-   Each lot has one persistent owner.
-   Visitors can enter and explore according to the game's permission
    rules.
-   Visitors cannot modify another player's property unless an explicit
    future feature permits it.
-   Property loading and decoration visibility must be tested with
    multiple players in the same server.

## 9. Chaser and encounter geography

The environment should support the existing dog-chase mechanic without
making every street equally dangerous.

### 9.1 Encounter placement

  -----------------------------------------------------------------------
  Environment                         Encounter design
  ----------------------------------- -----------------------------------
  Residential streets                 Dogs behind gates, patrols,
                                      occasional roaming dogs

  Larger properties                   More space for a dog to patrol
                                      within a defined area

  Rural roads                         Isolated encounters and longer
                                      escape routes

  Cemetery                            Special nighttime encounter
                                      opportunities

  Community areas                     Mostly safe, with controlled
                                      exceptions during events
  -----------------------------------------------------------------------

### 9.2 Encounter placement rules

1.  Do not spawn a chaser directly on top of a player.
2.  Give the player a readable warning when practical, such as barking,
    movement, or a visible dog behind a gate.
3.  Provide counterplay: route choices, sprinting, obstacles, and safe
    navigation.
4.  Keep attack and patrol areas within defined bounds.
5.  Prevent dog AI from crossing walls, fences, or inaccessible terrain
    unless that behavior is intentional.
6.  Avoid placing high-threat encounters on mandatory beginner routes.
7.  Test encounters with both solo players and groups.

### 9.3 Cemetery encounter

The cemetery should have a deliberate transition from ordinary town to
unsettling environment: - A recognizable entrance and boundary. -
Reduced street lighting. - Mature trees and varied tomb silhouettes. -
Clear navigation landmarks even in fog. - Controlled sightlines so the
player does not see every encounter location at once. - Enough open
space to move and escape.

Do not rely solely on darkness or jump scares. The atmosphere should
build through sound, lighting, environmental composition, and
anticipation.

## 10. Environment art and asset kit

The low-poly style should use reusable asset families with controlled
variation.

### 10.1 Asset families

**Architecture** - Small concrete house. - Wooden or mixed-material
house. - Bungalow. - Two-storey house. - Large house. - Sari-sari
store. - Small eatery. - Repair shop. - Barangay/public building. -
Warehouse. - Rural shed or farm building.

**Roadside and public props** - Streetlights. - Utility poles and
wires. - Road signs. - Waiting sheds. - Benches. - Trash bins. -
Drainage channels. - Fences and gates. - Road barriers. - Basketball
equipment.

**Vegetation** - Palm trees. - Broad-leaf tropical trees. - Shrubs. -
Grass clumps. - Flower beds. - Rural crops and field vegetation.

**Cemetery** - Ground tombs. - Above-ground tombs. - Stacked tomb
structures. - Cemetery wall and gate. - Candles and flower
arrangements. - Trees and controlled fog effects.

### 10.2 Variation strategy

Build modular components: - Wall sections. - Roof sections. - Doors and
windows. - Gate and fence modules. - Awning and sign modules. - Exterior
decoration sets.

Use a controlled palette and a small number of material families.
Variation should come from combinations, proportions, roof shapes,
paint, and props---not from making every asset use unrelated colors or
materials.

### 10.3 Visual readability

-   Interactive objects should stand out from decorative objects.
-   Customer houses should be recognizable at street level.
-   Important road turns should not be hidden by oversized vegetation.
-   Use lighting and color contrast to preserve nighttime navigation.
-   Keep visual clutter away from delivery interaction points.

## 11. Time, weather, and atmosphere

The environment should change in ways that players can recognize.

  -----------------------------------------------------------------------
  Condition               Visual behavior         Gameplay relationship
  ----------------------- ----------------------- -----------------------
  Morning                 Warm daylight and clear Normal delivery
                          visibility              conditions

  Afternoon               Brighter light and      Normal delivery
                          stronger shadows        conditions

  Sunset                  Warm sky and longer     Transition toward night
                          shadows                 

  Night                   Darker environment,     Increased atmosphere
                          streetlights,           and visibility
                          headlights              challenge

  Rain                    Rain particles,         Existing concept
                          wet-looking surfaces,   reduces grip and
                          puddles                 increases pay

  Brownout                Streetlights and        Visibility challenge
                          selected building       
                          lights switch off       

  Fiesta                  Bunting, decorations,   Existing concept
                          stalls and extra        increases pay
                          activity                

  Undas                   Cemetery decorations,   Existing concept
                          candles, subdued        increases pay and
                          atmosphere              enables themed content

  Wind                    Trees, flags and        Mostly atmospheric
                          hanging objects move    
  -----------------------------------------------------------------------

The existing concept includes a 10% rain pay bonus, +25% fiesta pay, and
+50% Undas pay. These values remain economy-design inputs and should be
verified during economy balancing; this document does not change them.

### 11.1 Time-cycle tuning

A 20--25-minute full day/night cycle is a provisional test target.
Validate it against the 20--40-minute session target. The cycle should
not make a player spend nearly an entire session in one lighting
condition unless that is an intentional event.

### 11.2 Visual and gameplay separation

Keep presentation and mechanics independently configurable: - Rain
visuals should not require every surface to have a separate physical
simulation. - Lighting changes should not disable navigation markers. -
Fog should not obscure essential interaction prompts. - Brownouts should
not make required routes impossible to navigate. - Event decorations
should not block vehicle or NPC movement.

## 12. Audio and environmental feedback

Audio is part of the spatial design and should help players understand
where they are.

  Area / condition      Audio direction
  --------------------- -------------------------------------------------
  Town Center           Distant traffic, conversations, shop ambience
  Residential streets   Birds, household ambience, dogs barking
  Rural outskirts       Wind, insects, birds, vegetation
  Rain                  Rainfall, thunder, water splashes
  Night                 Crickets, distant dogs, subdued ambient sound
  Cemetery              Quiet wind, restrained atmospheric cues
  Fiesta                Festive music, crowd ambience and event sounds
  Warehouse             Conveyor, package handling, doors and machinery

Audio should reinforce visual warnings. For example, a dog barking
behind a gate can warn a player before the dog becomes visible.

## 13. Animation and interaction dependencies

This blueprint identifies where animations are required, but the full
animation specification should be maintained as a separate companion
document or GDD section.

  -----------------------------------------------------------------------
  World element           Required presentation   Dependency
  ----------------------- ----------------------- -----------------------
  Player locomotion       Idle, walk, run,        Character controller
                          sprint, jump, fall,     
                          land                    

  Package handling        Pickup, carry,          Order and inventory
                          handover, drop          state

  Dogs                    Idle, patrol, alert,    Chaser AI state machine
                          bark, chase, attack,    
                          recover, return         

  Vehicles                Mount, dismount, riding Vehicle movement state
                          posture, wheel          
                          rotation, lights        

  Doors and gates         Open and close          Interaction and
                                                  collision logic

  Warehouse conveyor      Continuous belt and     Order presentation
                          package movement        

  Trees and flags         Subtle wind movement    Environmental state

  Streetlights            Switch on/off           Time and brownout state

  Weather                 Rain, puddles,          Weather state
                          splashes, wind          
  -----------------------------------------------------------------------

Animation states must have defined triggers and transitions. Do not
allow unrelated scripts to independently control the same character or
NPC animation state.

## 14. Expansion strategy

The initial town should be complete enough to support the core gameplay
loop. Future expansion should extend the town through connected roads
and recognizable transitions.

### Possible future districts

  -----------------------------------------------------------------------
  Expansion               Environment identity    Potential gameplay
  ----------------------- ----------------------- -----------------------
  Coastal village         Shoreline, fishing      Coastal deliveries and
                          homes, docks            weather

  Mountain barangay       Sloped roads, elevated  Steeper routes and
                          homes, vegetation       specialized vehicles

  Agricultural district   Farms, fields, storage  Bulky and long-distance
                          buildings               deliveries

  Commercial extension    Denser shops and larger Higher order density
                          buildings               and new customers

  Industrial extension    Warehouses, workshops,  Specialized cargo and
                          loading areas           logistics jobs
  -----------------------------------------------------------------------

### Expansion rules

1.  Reserve road corridors during initial map design.
2.  Avoid hardcoding gameplay systems to a fixed number of districts.
3.  Keep customer, house, encounter, and landmark identifiers stable.
4.  Organize assets and scripts by system or district responsibility.
5.  Add new content without invalidating existing player property or
    progression data.
6.  Profile performance before increasing NPC, vehicle, particle, and
    lighting counts.

## 15. Technical and performance constraints

The map must support Roblox desktop and mobile players.

-   Use StreamingEnabled where appropriate for the expanded world.
-   Keep district assets organized and reusable.
-   Avoid excessive unique meshes when a modular kit can achieve the
    same result.
-   Limit unnecessary transparent geometry and particle emitters.
-   Use distance/visibility-aware updates for NPCs and environmental
    effects.
-   Avoid running full AI logic for distant or inactive encounters.
-   Keep important interactions server-validated.
-   Do not let the client determine delivery rewards or authoritative
    encounter outcomes.
-   Test with multiple players and mobile hardware, not only in Studio
    on a desktop.

### Suggested world organization in Studio

``` text
Workspace
├── World
│   ├── TownCenter
│   ├── ResidentialEast
│   ├── ResidentialWest
│   ├── CommunityDistrict
│   ├── LogisticsDistrict
│   ├── RuralOutskirts
│   ├── CemeteryDistrict
│   └── ExpansionReserve
├── Gameplay
│   ├── CustomerHouses
│   ├── HomeLots
│   ├── EncounterZones
│   ├── DeliveryPoints
│   └── VehicleSpawnPoints
└── Environment
    ├── Lighting
    ├── Weather
    ├── AmbientAudio
    └── Effects
```

This is a proposed organizational convention, not a required final
hierarchy. The final architecture should be confirmed in Phase 2.

## 16. World blockout and validation plan

Do not begin detailed decoration before the spatial layout works.

### Blockout sequence

1.  Create the approximate map boundary and terrain.
2.  Place the warehouse and major landmarks.
3.  Lay down the primary road and outer-road connections.
4.  Add district boundaries and secondary roads.
5.  Place all 21 customer-house markers.
6.  Place the seven home-lot markers.
7.  Add delivery gates, parking areas, and final on-foot paths.
8.  Place encounter zones and cemetery access.
9.  Reserve future expansion connections.
10. Test routes using placeholder geometry before adding detailed
    assets.

### Playtest checklist

-   Can a new player find the warehouse without assistance?
-   Can players distinguish the major districts?
-   Are there multiple viable routes to important destinations?
-   Can every customer house be reached by vehicle and on foot?
-   Is the final on-foot approach clear and interesting?
-   Are there safe and risky route choices?
-   Are dog encounters avoidable through understandable counterplay?
-   Does the cemetery feel distinct without making navigation unfair?
-   Can players identify home lots and visit other players?
-   Does the map remain readable at mobile screen size?
-   Are delivery distances suitable for 20--40-minute sessions?
-   Do expansion corridors connect naturally to the initial road
    network?

### Exit criteria for the world-layout task

The task is ready for approval when: - The district arrangement is
agreed. - The primary and secondary road network is mapped. - Customer
houses and home lots have proposed positions. - Landmark and encounter
placement is defined. - Expansion connections are reserved. - A
graybox/blockout test confirms that core delivery routes work. - Known
dimension and spacing conflicts are resolved or explicitly documented.

## 17. Open decisions requiring review

These are intentionally unresolved; they should not be treated as
approved facts.

1.  Should the warehouse sit exactly at the map center or slightly
    offset to create a more natural town center?
2.  Should the cemetery be visible from the main road, or discovered
    through a quieter side road?
3.  Should the rural outskirts be included in the first release, or
    reserved for a later content update?
4.  Should the seven player home lots be grouped in one neighborhood or
    distributed around the town?
5.  Does the 72 m home-lot spacing refer to lot centers or lot
    boundaries?
6.  Should the map use a continuous terrain layout or controlled
    district transitions?
7.  What is the final playable footprint after the first graybox test?

## 18. Phase 1 tracker update

  Workstream                      Status
  ------------------------------- -------------
  Core concept and pillars        Completed
  Gameplay and progression        Drafted
  Economy and events              Drafted
  World identity and setting      Drafted
  Visual and art direction        Drafted
  District structure              Proposed
  Road network                    Proposed
  Customer-house distribution     Proposed
  Home-lot layout                 Proposed
  Encounter geography             Proposed
  Environmental behavior          Drafted
  Audio direction                 Drafted
  Expansion strategy              Proposed
  World blockout validation       Not started
  Final GDD review and approval   Pending

**Phase 1 remains open.** This document is a design proposal. It does
not claim that the world has been built, tested, or approved. The next
practical deliverable is a top-down graybox layout with measured roads,
district boundaries, customer-house positions, home lots, and delivery
routes.

------------------------------------------------------------------------

**End of document**
