# Deliver a Parcel --- Game Design Document (GDD) v1.0

**Document status:** Phase 1 design baseline --- ready for owner review
and approval\
**Document date:** 7 November 2026\
**Platform:** Roblox\
**Development approach:** Roblox Studio + Luau + Rojo + Rokit\
**Source concept:** Existing browser game, *Deliver a Parcel*\
**Browser version:** https://deliver-a-parcel.vercel.app

------------------------------------------------------------------------

## Document purpose

This document consolidates the existing *Deliver a Parcel* concept and
the Phase 1 decisions confirmed for its Roblox adaptation. It separates:

-   **Existing design:** mechanics and values already documented in the
    browser-game plan.
-   **Approved direction:** decisions confirmed for the Roblox
    experience.
-   **Proposals:** recommended additions that still require playtesting
    or explicit approval.
-   **Deferred scope:** features intentionally excluded from the initial
    MVP.

The browser game remains the reference implementation while the Roblox
version is developed. Existing values are starting balance values, not
guaranteed final balance targets. Actual playtesting should overrule
untested assumptions.

## 1. Executive concept

### 1.1 Game overview

*Deliver a Parcel* is a casual, cooperative delivery adventure and
tycoon set in a fictional Filipino town.

Players begin with very limited resources and take food and parcel
orders from a central warehouse. They travel through town using
progressively better transportation, but rides stop at customers' gates.
The final approach is completed on foot, where dogs and other unusual
encounters can damage deliveries or threaten the player.

Players earn pesos by completing deliveries, then invest their earnings
in vehicles, vehicle parts, homes, equipment, and customization. The
town changes through its day/night cycle, weather, brownouts, fiestas,
and special nighttime encounters.

The Roblox version should preserve the browser game's identity while
using multiplayer as a meaningful extension: friends can help with
demanding deliveries, contribute to shared town objectives, and visit
one another's properties.

### 1.2 Design pillars

Every major feature should strengthen at least one pillar.

1.  **The dog chase:** Rides park at the customer's gate. The final
    stretch remains an on-foot, skill-based risk.
2.  **Visible progression:** Vehicle parts, rides, homes, and
    decorations visibly change the player's appearance and property.
3.  **Filipino flavour:** The town, customers, animals, events,
    architecture, and humor draw from Filipino everyday life and
    seasonal traditions.
4.  **Cooperative adventure:** Players can help one another and
    contribute to shared activities without making solo play unviable.

### 1.3 Unique selling proposition

A cosy, funny Filipino-town delivery tycoon where players build their
delivery lifestyle, ride through a lively neighborhood, and face a risky
final ten metres because a dog may be waiting at the gate.

### 1.4 Target experience

**Approved target: Casual.**

The game should be easy to understand, welcoming to new players, and
rewarding in short or moderate sessions. Difficulty should come
primarily from readable gameplay situations and player decisions, not
complicated controls or punishing resource management.

**Target average session: 20--40 minutes.**

This is a design target for pacing and playtesting, not a forced session
length. Players should be able to make progress in shorter sessions and
should not be punished for leaving.

## 2. Target audience and player experience

### 2.1 Intended audience

Players looking for a casual Roblox experience with: -
Easy-to-understand delivery missions. - Funny and memorable chase
encounters. - Collectible and visibly upgradeable rides. - Personal
homes and customization. - Friendly cooperative play. - A recognizable
Filipino setting.

The experience should support both solo players and groups of friends.

### 2.2 Player journey

  -----------------------------------------------------------------------
  Player stage            Desired experience      Main goals
  ----------------------- ----------------------- -----------------------
  New player              Understand the game     Complete first
                          quickly and experience  deliveries and buy an
                          the signature           early upgrade
                          delivery/chase loop     

  Returning player        See clear objectives    Improve equipment,
                          and discover new        build customer
                          opportunities           familiarity, complete
                                                  goals

  Mid-game player         Make meaningful choices Unlock specialized
                          about rides, capacity,  delivery opportunities
                          risk, and contracts     and improve a preferred
                                                  build

  Late-game player        Complete advanced       Acquire advanced rides,
                          content and invest in   improve property,
                          long-term goals         complete difficult
                                                  contracts

  Endgame player          Have goals beyond       Collections, advanced
                          buying every standard   challenges, cooperative
                          item                    milestones, franchise
                                                  progression in a future
                                                  update
  -----------------------------------------------------------------------

### 2.3 First-session goals

**Proposed targets to validate in playtests:** - The player understands
how to accept and complete an order without external instructions. - The
player experiences a delivery and a chaser encounter early. - The player
receives clear feedback for payment, time, and order condition. - The
player can identify a meaningful first purchase within approximately
5--10 minutes. - The player understands where to spend earnings and how
to begin another delivery.

These are hypotheses to test, not promises about final pacing.

## 3. World and setting

### 3.1 Existing browser-game world

The current browser game contains:

-   A 340 × 340 metre town with ring roads.
-   21 customer houses in three sizes.
-   Sari-sari stores.
-   A basketball court, pond, and pickleball court.
-   A central warehouse hub with a conveyor belt and order board.
-   A dealer and mechanic on opposite sides of the hub.
-   A Filipino cemetery on the outer ring, including ground tombs and
    stacked apartment tombs.
-   Seven home lots, spaced at least 72 metres apart.
-   A day/night cycle, headlights, cemetery candles, and fog.

This is the initial Roblox world scope. Additional districts are future
expansions, not MVP requirements.

### 3.2 World atmosphere and events

Existing world conditions include: - Rain, which reduces grip and
increases pay. - Brownouts, which turn off lights. - Fiesta decorations
and increased delivery pay. - Undas cemetery activity and increased
delivery pay. - Road traffic and 12 citizens walking leashed dogs. -
Citizen collision penalties.

The world should feel active but remain readable and performant on
mobile devices.

### 3.3 Filipino identity

Use local details as part of the world and gameplay rather than as
superficial decoration: - Sari-sari stores and neighborhood houses. -
Filipino cemetery architecture and traditions. - Fiesta decorations and
food orders. - Christmas parols and Simbang Gabi-inspired deliveries. -
Undas encounters. - Filipino animals and familiar neighborhood
situations.

Seasonal and cultural content should be handled respectfully and should
fit the game's lighthearted tone.

## 4. Core gameplay

### 4.1 Primary gameplay loop

1.  Visit the warehouse order board.
2.  Choose an available order or an eligible special job.
3.  Travel toward the customer using the player's ride.
4.  Automatically park or dismount at the customer's gate.
5.  Complete the final approach on foot.
6.  Avoid or survive the chaser encounter while protecting the order.
7.  Deliver to the correct destination before the timer expires.
8.  Receive payment and relevant progression credit.
9.  Spend earnings on rides, parts, homes, equipment, or customization.
10. Return to the board and choose another activity.

### 4.2 Secondary gameplay loops

Secondary activities should complement deliveries, not become mandatory
chores.

  -----------------------------------------------------------------------
  Activity                            Purpose
  ----------------------------------- -----------------------------------
  Home improvement and decoration     Personal expression and visible
                                      long-term investment

  Vehicle and part customization      Different looks and
                                      performance/capacity choices

  Daily and weekly objectives         Short- and medium-term goals

  Customer familiarity                Give players reasons to revisit
                                      neighborhoods

  Night jobs                          Risk-versus-reward alternative
                                      activity

  Cooperative deliveries              Social play and teamwork

  World events                        Change route conditions and create
                                      variety

  Collections and achievements        Long-term optional goals
  -----------------------------------------------------------------------

### 4.3 Order board

Existing browser-game configuration: - Three offers are displayed at a
time. - Each offer lasts 30 seconds. - Food and parcel orders are the
standard types. - Special variants include Fragile, Rush, and Bulky. - A
player can carry up to four orders when their equipment allows it.

The Roblox implementation must create and validate offers on the server.
The client displays offers and requests acceptance; it does not
determine payment or order state.

### 4.4 Existing order types

  Order type   Existing rule
  ------------ -----------------------------------------
  Food         ₱30 base pay; 8-second base timer
  Parcel       ₱25 base pay; 14-second base timer
  Fragile      Takes 2× damage
  Rush         Pays 1.5×; uses 55% of the normal time
  Bulky        Pays 1.4×; requires carry capacity of 3

Existing bonuses: - Distance bonus: up to +40% at the far edge. -
Difficulty: 1--5 stars, +12% pay per star. - Tip: up to +60%, based on
speed and condition. - Night pay: +15%. - Streak: +2% per delivery, up
to +20%. - Regular customer: +10% at a house after three visits.

Typical earnings documented in the browser plan are approximately ₱50
for an easy delivery, ₱100 on average, and ₱340 for the best night rush.

**Balance note:** The exact stacking order and any payout cap must be
verified against the browser implementation and tested in Roblox. Do not
assume every bonus should multiply every other bonus without limit.

### 4.5 Delivery failure philosophy

**Approved decision: Partial consequence.**

A failed or damaged delivery should generally result in reduced payment
or tip and order-condition consequences, rather than always removing all
earnings and imposing a severe loss.

Implementation details still to tune: - Whether a timeout pays a reduced
base amount. - How order damage affects the final payment. - Whether a
completely destroyed order receives no payment. - Whether special
contracts can have stricter failure rules.

The experience should communicate the consequences before a player
accepts a high-risk contract. Failure should teach the player about the
system, not make casual play feel punishing.

## 5. Chasers and encounters

### 5.1 Existing dog categories

  Size         Speed   Order damage per bite
  -------- --------- -----------------------
  Tiny       8.2 m/s                      5%
  Small      7.5 m/s                     10%
  Medium     6.3 m/s                     18%
  Big        5.4 m/s                     30%
  Giant      4.6 m/s                     45%

Existing breeds: - Chihuahua - Pomeranian - Shih Tzu - Dachshund -
Aspin - Beagle - German Shepherd - Husky - Great Dane - Saint Bernard -
Mastiff - Angry cat - Goose

The White Lady appears in the cemetery at night, with an existing
documented speed of 3.4 m/s and 40% order damage.

### 5.2 Encounter design direction

Do not make every new encounter a faster or stronger version of an
existing dog. Variety should come from recognizable behavior and player
counterplay.

Potential behavior identities: - Fast but fragile pursuer. - Slow,
high-damage pursuer. - Persistent pursuer that follows longer. -
Area-denial encounter that blocks a route. - Unpredictable animal that
changes direction. - Supernatural encounter with different detection or
pursuit rules.

These behavior differences are proposals. The initial port should first
reproduce and stabilize the existing encounter behavior.

### 5.3 Fairness requirements

-   Chasers should have readable detection and attack behavior.
-   Players should have a reasonable opportunity to react.
-   Damage and failure feedback must be clear.
-   A chaser should not permanently trap a player.
-   NPC behavior must be server-authoritative where it affects rewards
    or order condition.
-   AI population and update frequency must be controlled for server
    performance.

## 6. Vehicles, equipment, and homes

### 6.1 Existing rides

  Ride                Price                Speed Existing parts/capabilities
  --------------- --------- -------------------- ---------------------------------
  On foot              Free   6 run / 9.5 sprint None
  Roller blades        ₱300              7.8 m/s Wheels, laces, backpack
  Skateboard           ₱900              9.5 m/s Wheels, deck, milk crate
  Bicycle            ₱2,500             12.5 m/s Tyres, front basket, sidecar
  Moped              ₱7,000               17 m/s Engine, tyres, top box, sidecar
  Motorcycle        ₱12,000               20 m/s Racing engine, saddlebags
  Tricycle          ₱18,000             17.5 m/s Carry 3, engine, roof rack

Sprint is documented as a +35% boost using a shared stamina bar.

Rides are intentionally arcade-like: a ride model is attached to the
character, while movement speed and carry capacity are controlled by
server-validated stats. The design avoids relying on full vehicle-seat
physics. Rides park at the gate before the final on-foot segment.

### 6.2 Vehicle progression philosophy

The progression model is hybrid:

-   **Vertical progression:** improved speed, capacity, durability, or
    other existing ride statistics.
-   **Horizontal progression:** different ride types and equipment that
    support different delivery strategies.

Avoid making every new ride strictly better in every category. Different
rides should have trade-offs, such as speed versus capacity or
maneuverability versus cargo protection.

### 6.3 Existing homes

  Home                  Price   Pay bonus
  ------------------ -------- -----------
  Cardboard box          Free          0%
  Wooden shack           ₱400         +3%
  Bungalow             ₱1,500         +6%
  Two-storey house     ₱4,000         +9%
  Mansion              ₱9,000        +12%

Existing customization includes house paint, ride paint, flower beds,
and a Philippine flag. Skin and clothes are free during the
introduction.

### 6.4 Property ownership

**Approved decision: Individual persistent ownership.**

Each player has an individual home/property that persists between
sessions. Players should be able to visit other players' properties.

The initial seven-lot world allocation is the starting implementation.
The Roblox version must decide how to represent persistent ownership
when the owner's lot is occupied by another player or when a player
joins a full server.

Recommended implementation direction: - Persist the player's home tier
and decoration choices in their player data. - Assign an available
physical lot when they join. - Build or apply their saved property state
to that lot. - Allow visitors without granting them edit permissions by
default. - Keep property permissions server-validated.

Shared ownership of a jointly developed property is not part of the MVP.
It can be evaluated after individual property persistence and visiting
work reliably.

## 7. Progression architecture

### 7.1 Approved progression direction

**Hybrid progression: vertical and horizontal.**

Players should improve existing equipment while also unlocking different
ways to play. Late-game updates should not rely solely on higher prices
and larger multipliers.

### 7.2 Progression categories

1.  **Economic progression:** pesos, purchases, and investments.
2.  **Vehicle progression:** rides, parts, carry capacity, and
    specialized setups.
3.  **Lifestyle progression:** home tiers, property decoration, and
    customization.
4.  **Reputation progression:** customer familiarity, licenses, and
    access to contracts.
5.  **Cooperative progression:** shared objectives and team delivery
    milestones.

Reputation XP/levels are a proposed addition and need final balancing
and unlock definitions before implementation.

### 7.3 Progression stages

  -----------------------------------------------------------------------
  Stage                   Main goals              Opportunities
  ----------------------- ----------------------- -----------------------
  Early                   First rides and home    Standard food and
                          improvements            parcel orders

  Mid                     Better rides,           Rush, Fragile, Bulky,
                          equipment, and licenses and night contracts

  Late                    Advanced rides,         Advanced and
                          tricycle, mansion,      cooperative contracts
                          specialized setups      

  Endgame                 Collections,            New strategies, social
                          reputation, difficult   goals, and future
                          challenges, and future  content
                          franchise progression   
  -----------------------------------------------------------------------

### 7.4 Horizontal progression examples

Potential future unlocks: - Cargo-focused tricycle. - Lightweight ride
for narrow streets. - Protective backpack for fragile orders. -
Equipment that changes how a player handles a chase. - Licenses for
special order categories. - Different customer contract chains.

These should change decisions or gameplay opportunities, not merely
increase income.

## 8. Economy architecture

### 8.1 Primary currency

**Pesos (₱)** remain the primary launch currency.

Do not introduce multiple spendable currencies at launch without a clear
need.

### 8.2 Progression metric

Reputation XP or reputation levels are proposed as a non-spendable
progression track. They may unlock licenses, contract types, customer
stories, or other opportunities.

### 8.3 Future currencies

  -----------------------------------------------------------------------
  Currency                Purpose                 Timing
  ----------------------- ----------------------- -----------------------
  Pesos                   Main purchases and      Launch
                          upgrades                

  Reputation XP           Unlock contracts and    Launch only if the
                          licenses                progression design is
                                                  finalized

  Event tokens            Seasonal cosmetics and  Future update
                          collectibles            

  Franchise points        Permanent prestige      Future update
                          progression             
  -----------------------------------------------------------------------

### 8.4 Spending categories

  -----------------------------------------------------------------------
  Category                Frequency               Purpose
  ----------------------- ----------------------- -----------------------
  Vehicle purchases and   Milestone purchases     Performance and
  parts                                           capacity

  Home upgrades           Long-term purchases     Visible progression and
                                                  home bonus

  Equipment               Occasional purchases    Change delivery
                                                  capability

  Cosmetics               Optional                Personal expression

  Consumables             Optional recurring      Temporary utility, if
                          spend                   implemented

  Licenses                Milestone purchases     Unlock gameplay
                                                  categories

  Franchise expansion     Major investment        Endgame progression,
                                                  future feature
  -----------------------------------------------------------------------

### 8.5 Money sinks and economy safeguards

Recommended sinks: - Vehicles and parts. - Home tiers and decorations. -
Cosmetic collections. - Optional utility consumables. - Licenses and
special access. - Future franchise investments.

Avoid mandatory recurring maintenance bills in the casual experience.
Optional maintenance can provide a small benefit or cosmetic service,
but should not become a punishment for playing.

Economy safeguards: - The server is the sole authority for cash
changes. - Validate item IDs, prices, ownership, range, and
prerequisites. - Apply reward formulas on the server. - Prevent
duplicate order completion and duplicate purchase requests. - Use
controlled bonus stacking and test high-income combinations. - Track
sources and sinks during testing to identify inflation. - Do not sell
gameplay advantages that trivialize the signature dog-chase mechanic.

### 8.6 Existing economy reference

The browser plan estimates: - ₱41,250 for the home ladder, first four
rides, and their parts. - Approximately 400 average deliveries or 4--5
hours for that initial climb. - A further ₱42,000 for the motorcycle,
tricycle, and their parts.

These values should be reviewed against the casual target and the
desired 20--40 minute session. Early progression may need to be faster,
but changes must be based on playtest results.

## 9. Cooperative multiplayer

### 9.1 Approved multiplayer direction

**Cooperative multiplayer is the priority.**

The experience should support players helping one another and
contributing to shared goals. Solo players must still be able to
complete the main progression and enjoy the game.

### 9.2 Proposed cooperative systems

**Team deliveries** - Some bulky or special orders can involve two or
more players. - One player may carry cargo while another assists with
obstacles or a chaser. - Rewards are determined by the server using
clear participation rules. - Solo alternatives should exist for
essential progression.

**Community milestones** - The server contributes deliveries toward a
shared objective. - Example: the town completes 50 deliveries before a
fiesta objective ends. - Rewards should be granted once per eligible
player, with server-side tracking.

**Specialized roles** - Players may develop different equipment setups,
such as cargo transport, speed delivery, or order protection. - Roles
should create useful differences without requiring a fixed party
composition.

### 9.3 Multiplayer fairness and security

-   The server validates participants, order state, delivery location,
    and rewards.
-   Do not trust client-reported distance, damage, time, or payment.
-   Prevent multiple players from claiming the same exclusive order
    reward.
-   Define what happens if a teammate disconnects during a team
    delivery.
-   Ensure team activities do not make solo players feel excluded.

## 10. Events and live content

### 10.1 Launch event foundation

The initial release should prioritize existing world events: - Day/night
cycle. - Rain. - Brownouts. - Fiesta. - Undas. - Night encounters.

Daily goals may also be included if they are stable and do not create
excessive time pressure.

### 10.2 Daily and weekly activities

Proposed examples: - Complete a number of deliveries. - Deliver to
several yards with chasers. - Complete a cemetery delivery at night. -
Finish a special job. - Complete several Bulky deliveries. - Complete
deliveries while protecting order condition.

Weekly objectives can combine several delivery types and provide
longer-term rewards.

### 10.3 Seasonal events

  -----------------------------------------------------------------------
  Event                   Theme and gameplay      Potential rewards
  ----------------------- ----------------------- -----------------------
  Christmas / Simbang     Dawn deliveries,        Parols, cosmetics, home
  Gabi                    festive orders,         decorations
                          decorated town          

  Undas                   Cemetery deliveries and Themed collectibles and
                          special encounters      cosmetics

  Sinulog-inspired fiesta Festival food           Festival decorations
                          deliveries, crowded     and cosmetics
                          streets, community      
                          objectives              

  Bagyo season            Flooded routes and      Weather-themed
                          route-planning          collectibles and
                          challenges              equipment cosmetics
  -----------------------------------------------------------------------

Seasonal dates and content should be planned in advance. Events should
add gameplay variety rather than only temporary pay multipliers.

### 10.4 Special cooperative event example

**The Great Lechon Delivery** - A large special package appears at the
warehouse. - Multiple players cooperate to transport it. - Players
coordinate carrying and obstacle handling. - The order condition affects
the final outcome. - The server contributes successful deliveries to a
community milestone. - Eligible players receive a reward based on clear
participation criteria.

This is a proposed future event, not an MVP dependency.

## 11. Retention and long-term engagement

Retention should come from meaningful goals and enjoyable gameplay, not
pressure to log in every day.

### 11.1 Short-term goals

-   Complete another delivery.
-   Purchase the next affordable part.
-   Finish a daily objective.
-   Visit a new customer or neighborhood.

### 11.2 Medium-term goals

-   Purchase a new ride.
-   Improve the home.
-   Unlock a license.
-   Build familiarity with regular customers.
-   Complete a weekly challenge.

### 11.3 Long-term goals

-   Collect rides, parts, and cosmetics.
-   Complete advanced delivery challenges.
-   Reach reputation milestones.
-   Participate in seasonal activities.
-   Establish a franchise in a future update.
-   Visit and customize properties.

### 11.4 Returning-player experience

On return, players should be able to: - See their current progression
and next useful goals. - Understand active world conditions and
events. - Resume ordinary deliveries immediately. - Visit friends and
inspect their properties. - Participate in available community
objectives.

Do not rely on punitive streak loss, excessive login timers, or
limited-time rewards as the primary retention mechanism.

## 12. Prestige and franchise system --- future design

### 12.1 Concept

The proposed prestige identity is **Delivery Franchise**.

Players who complete the initial progression can establish a new branch
or franchise. The system should represent a new stage of the player's
delivery career, not a simple reset for a larger multiplier.

### 12.2 Potential requirements

To be tuned after launch: - Own a mansion. - Own an advanced ride. -
Reach a defined reputation level. - Complete a set of advanced
contracts. - Pay a franchise establishment fee.

### 12.3 Proposed reset policy

  -----------------------------------------------------------------------
  Progress                            Reset?
  ----------------------------------- -----------------------------------
  Main vehicle purchases              Yes, if confirmed by final prestige
                                      rules

  Vehicle parts                       Yes, if confirmed by final prestige
                                      rules

  Home tier                           Yes, if confirmed by final prestige
                                      rules

  Main cash balance                   To be determined; communicate
                                      clearly before reset

  Achievements                        No

  Cosmetics                           No

  Collection discoveries              No

  Franchise progression               No

  Permanent franchise unlocks         No
  -----------------------------------------------------------------------

The reset policy must be explicit before players commit. Do not
implement prestige until the base progression is tested and players have
a meaningful reason to use it.

### 12.4 Future franchise unlocks

Potential unlocks include: - Franchise headquarters customization. -
Specialized contracts. - New vehicle categories. - Business reputation
levels. - Advanced cooperative contracts. - Exclusive appearances. -
Additional districts.

Avoid a prestige system that only increases income. It should unlock new
decisions and experiences.

## 13. Roblox technical and production constraints

### 13.1 Technology direction

-   Roblox Studio.
-   Luau.
-   Rojo 7.7.1.
-   Rokit with pinned tool versions.
-   DataStores for persistence.
-   ServerScriptService for authoritative gameplay systems.
-   ReplicatedStorage for shared data and remotes.
-   StarterPlayerScripts for client input, presentation, and UI.

### 13.2 Server authority

The server owns: - Cash and purchases. - Order offers and acceptance. -
Delivery validation and rewards. - Order condition and damage. - Chaser
state when it affects gameplay outcomes. - Player progression and
goals. - Event state. - Persistent player data.

The client owns presentation and input: - UI. - Local effects and
animations. - Input handling. - Camera and visual feedback. - Requests
to perform server-validated actions.

**Rule: the client never tells the server how much it earned.**

### 13.3 Remote validation

The existing plan proposes a small set of remotes:

  ------------------------------------------------------------------------
  Remote            Kind              Client request     Server validation
  ----------------- ----------------- ------------------ -----------------
  AcceptOrder       RemoteFunction    Offer ID           Offer exists,
                                                         player is at hub,
                                                         carry capacity is
                                                         available, ride
                                                         meets
                                                         requirements

  Buy               RemoteFunction    Item ID            Item exists,
                                                         player can afford
                                                         it, shop is in
                                                         range

  Mount             RemoteEvent       Mount/dismount     Player owns ride
                                                         and is not in a
                                                         yard

  Intro             RemoteEvent       Name, skin,        Values are
                                      clothes            allowed and name
                                                         is filtered

  Notify            RemoteEvent       Server-to-client   Server sends
                                      notification       feedback such as
                                                         toasts, payment
                                                         breakdowns, and
                                                         bites
  ------------------------------------------------------------------------

All remote payloads require type, range, ownership, state, and
rate-limit validation as appropriate.

### 13.4 Persistence

Player data should include, at minimum, validated defaults for: -
Cash. - Owned rides and parts. - Equipped ride and parts. - Home tier
and decorations. - Reputation/progression, once finalized. - Goals and
relevant counters. - Collection/achievement state. - Settings needed for
the experience.

The implementation must handle: - Load failures and retries. - Save
failures and retries. - Session locking or equivalent protection against
concurrent sessions. - Player departure and server shutdown. - Data
versioning and safe migrations. - Invalid or missing saved fields.

Do not trust client-provided data when loading or saving progression.

### 13.5 Performance and mobile

-   Mobile-first controls and readable UI.
-   Controlled NPC and chaser populations.
-   Efficient AI update rates and spatial checks.
-   Avoid unnecessary physics complexity for rides.
-   Use StreamingEnabled appropriately.
-   Test instance/part counts on a real mobile device.
-   Test with multiple players, not only solo Studio play.

### 13.6 Asset and audio safety

-   Use owned, licensed, or permitted audio.
-   Check Creator Store assets for unwanted scripts and suspicious
    dependencies.
-   Do not use untrusted models containing unexpected `require`,
    `loadstring`, or environment-manipulation code.
-   Keep credits and asset provenance documented.

## 14. MVP scope

The MVP is the smallest release that proves the signature gameplay loop
and the essential progression.

### 14.1 Included in MVP

  -----------------------------------------------------------------------
  System                              MVP scope
  ----------------------------------- -----------------------------------
  World                               Original town blockout and core
                                      locations

  Orders                              Food and parcel orders

  Delivery                            Accept, carry, timer, gate parking,
                                      door validation, payment

  Chasers                             Existing dog size categories and a
                                      limited set of breeds

  Economy                             Server-authoritative pesos and
                                      purchases

  Vehicles                            Initial ride ladder and core parts

  Homes                               Initial home ladder and individual
                                      persistent property state

  Saving                              Reliable player data persistence

  Multiplayer                         Shared town and basic player
                                      interaction

  UI                                  Intro, HUD, order board, shops,
                                      notifications

  World                               Day/night and a stable subset of
                                      existing conditions

  Goals                               Basic daily objectives if they are
                                      stable and testable
  -----------------------------------------------------------------------

### 14.2 Deferred from MVP

-   Franchise rebirth.
-   Employee or staff management.
-   Player-owned delivery companies.
-   Complex pet progression.
-   Multiple additional districts.
-   Advanced seasonal event framework.
-   Extensive interior customization.
-   Shared jointly owned properties.
-   Large-scale community event infrastructure.
-   Multiple additional currencies.

### 14.3 MVP acceptance criteria

The MVP is not complete until: 1. A new player can understand and
complete a delivery. 2. The server validates order acceptance, delivery,
and payment. 3. Invalid or duplicate reward requests are rejected. 4.
Chasers work in multiplayer without breaking order state. 5. Players can
buy and visibly equip upgrades. 6. Home and progression data persist
across sessions. 7. Concurrent sessions cannot duplicate progression. 8.
Multiple players can use the same server reliably. 9. The experience is
playable on mobile. 10. Repeated deliveries remain enjoyable during
structured playtests.

## 15. Development roadmap

The project will proceed one phase at a time. Future phases must not be
treated as complete merely because their features are described in this
document.

  -----------------------------------------------------------------------
  Phase             Purpose           Main deliverable  Exit condition
  ----------------- ----------------- ----------------- -----------------
  1\. Concept       Finalize concept, Approved GDD      Owner reviews and
  validation & game experience,                         approves GDD
  design            loops, MVP, and                     
                    design risks                        

  2\. Technical     Establish project Technical         Foundation passes
  foundation &      structure,        Architecture      basic
  architecture      networking,       Document and      server/client and
                    persistence, and  functional        persistence tests
                    security          foundation        

  3\. Core gameplay Implement orders, Playable core     End-to-end
  development       deliveries,       prototype         delivery loop
                    chasers, rewards,                   works in
                    and UI                              multiplayer

  4\. Progression & Implement         Initial           Progression saves
  economy           purchases,        progression       and economy
                    upgrades, homes,  ecosystem         passes balance
                    and progression                     tests

  5\. World         Build the town    Expanded playable Core world and
  building &        and integrate     world             activities
  content expansion environmental                       perform reliably
                    content                             

  6\. Events &      Add recurring,    Functional event  Events start,
  live-service      random, and       framework         run, reward, and
  systems           seasonal event                      end correctly
                    infrastructure                      

  7\. Endgame &     Add advanced      Sustainable       Endgame playtests
  long-term         challenges,       endgame           show meaningful
  retention         collections, and                    goals
                    prestige where                      
                    justified                           

  8\. Testing,      Test              Release candidate Critical bugs and
  balancing &       functionality,                      exploit paths are
  optimization      security,                           addressed
                    economy, and                        
                    performance                         

  9\. Launch &      Release and       Public release    Monitoring and
  post-launch       operate the game  and update        update workflow
  operations        using player      process           is active
                    feedback and                        
                    analytics                           
  -----------------------------------------------------------------------

### 15.1 Phase 1 task tracker

  -----------------------------------------------------------------------
  Task              Priority          Status            Completion
                                                        criteria
  ----------------- ----------------- ----------------- -----------------
  Establish         Critical          Completed         Existing concept
  original concept                                      documented

  Define design     Critical          Completed         Four pillars
  pillars                                               established

  Confirm target    Critical          Completed         Casual experience
  experience                                            confirmed

  Confirm           Critical          Completed         Hybrid
  progression                                           progression
  direction                                             confirmed

  Confirm           High              Completed         Cooperative
  multiplayer                                           priority
  direction                                             confirmed

  Confirm session   High              Completed         20--40 minute
  target                                                target confirmed

  Confirm delivery  High              Completed         Partial
  failure                                               consequence
  philosophy                                            philosophy
                                                        confirmed

  Confirm property  High              Completed         Individual
  ownership                                             persistent homes
                                                        and visiting
                                                        confirmed

  Define core loop  Critical          Completed         Primary and
                                                        secondary loops
                                                        documented

  Define            High              Drafted           Categories and
  progression                                           stages
  architecture                                          documented;
                                                        balance remains
                                                        for playtesting

  Define economy    High              Drafted           Currency and
  architecture                                          sinks documented;
                                                        exact
                                                        stacking/caps
                                                        remain to
                                                        validate

  Define event      Medium            Drafted           Initial and
  ecosystem                                             future event
                                                        categories
                                                        documented

  Define MVP        Critical          Proposed          Scope and
                                                        acceptance
                                                        criteria
                                                        documented; owner
                                                        approval required

  Finalize GDD      Critical          Pending approval  Owner reviews and
                                                        approves this
                                                        document
  -----------------------------------------------------------------------

**Status definitions** - Not Started - In Progress - Blocked - Testing -
Completed

A design proposal is not the same as an implemented and tested feature.
Status must reflect actual work.

## 16. Critical risks and design decisions still open

  ------------------------------------------------------------------------
  Risk or open question   Why it matters          Required action
  ----------------------- ----------------------- ------------------------
  Early progression may   Casual players may      Playtest the first
  be too slow             leave before reaching   30--60 minutes and
                          upgrades                adjust prices/rewards

  Bonus stacking may      Advanced players may    Define formula order,
  inflate cash            discover extreme payout caps, and test cases
                          combinations            

  Failure consequences    Players may feel        Specify timeout, damage,
  may be unclear          unfairly punished       and total-loss outcomes

  Chaser AI may be        NPCs can affect server  Profile AI with multiple
  expensive               performance             players and active
                                                  chasers

  Persistent home lots    Seven physical lots are Define lot allocation
  may conflict            shared in a multiplayer and visitor permissions
                          server                  

  Team rewards may be     Players may claim       Define server-side
  exploitable             rewards without         eligibility and
                          contributing            contribution rules

  Event rewards may       Limited events can      Prefer
  inflate the economy     create large currency   cosmetics/collectibles
                          injections              and budget currency
                                                  rewards

  Prestige may feel       Resetting purchased     Test base endgame before
  punitive                items can undermine     finalizing reset rules
                          investment              

  Content scope may grow  Too many systems can    Protect MVP scope and
  too quickly             delay a playable        defer optional systems
                          release                 
  ------------------------------------------------------------------------

### Decisions that require later validation

The following are intentionally not finalized: - Exact reward formula
and bonus stacking/caps. - Exact failure payout and total-destruction
rules. - Final reputation thresholds and license unlocks. -
Team-delivery reward distribution. - Persistent property lot allocation
under full-server conditions. - Franchise requirements and reset
details. - Event cadence and reward budgets. - Final server player
cap. - Whether the launch version includes all existing world events or
a stable subset.

Do not silently invent values for these. Resolve them through
source-code inspection, implementation constraints, and playtesting.

## 17. Phase 1 completion and approval

### Confirmed decisions

  -----------------------------------------------------------------------
  Design decision                     Confirmed direction
  ----------------------------------- -----------------------------------
  Target experience                   Casual

  Progression                         Hybrid: vertical and horizontal

  Multiplayer                         Cooperative

  Average session target              20--40 minutes

  Failed delivery                     Partial payment/reduced tip and
                                      order-condition consequences

  Property ownership                  Individual persistent properties;
                                      players can visit others
  -----------------------------------------------------------------------

### Phase 1 deliverable

This document consolidates the current concept, confirmed decisions,
existing browser-game mechanics, proposed design direction, MVP
boundaries, and development roadmap.

**Phase 1 status: GDD prepared for owner review.**

The next action is to review and approve this GDD. Phase 2 must not
begin until the GDD is approved and any required changes are
incorporated.

------------------------------------------------------------------------

## Appendix A --- Existing browser-game reference values

These values are carried forward from the existing concept plan as
initial reference data.

### Orders

  Value                      Existing setting
  ------------------------ ------------------
  Food base pay                           ₱30
  Food base timer                   8 seconds
  Parcel base pay                         ₱25
  Parcel base timer                14 seconds
  Maximum distance bonus                 +40%
  Difficulty bonus              +12% per star
  Maximum tip                            +60%
  Night pay                              +15%
  Board offers                              3
  Offer duration                   30 seconds
  Maximum carry                      4 orders

### World conditions

  Condition           Existing setting
  ------------------- -------------------------------------------------
  Rain                Grip drops to 55%; pay rises 10%
  Brownout            Lights go out
  Fiesta              Pay rises 25%
  Undas               Pay rises 50%
  Citizen collision   At 7 m/s or more: ₱15 fine and 10% order damage

### Night jobs

-   Shady packages: dealer spawns at least 90 metres away; buyer is at
    least 120 metres from dealer.
-   Base pay: ₱130 plus up to 60% for distance.
-   Police patrol at 8 m/s and chase at 19 m/s.
-   Detection radius: 32 metres.
-   Escape condition: get 55 metres away for 3 seconds.
-   Arrest consequence in the existing design: 25% of cash and every
    carried order.

These risk values should be reviewed for the casual Roblox target before
being treated as final.

## Appendix B --- Source and design provenance

-   **Existing design values and world content:** the uploaded *Deliver
    a Parcel on Roblox* plan, dated 7 November 2026.
-   **Confirmed product direction:** decisions supplied by the project
    owner during Phase 1.
-   **Recommendations and future features:** design proposals in this
    GDD; they require review, implementation, and playtesting before
    being treated as final.
