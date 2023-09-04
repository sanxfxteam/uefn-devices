## Demonstration of the base syntax of the language.
## Including some troubleshooting tips.

# Arrays - https://dev.epicgames.com/documentation/en-us/uefn/array-in-verse

# Error: This invocation calls a function that has the 'decides' effect, which is not allowed by its context.(3512)
# Solution: 
if (NewPosition := SideChestsPositions[Index]):
  # do something with NewPosition
  Print("NewPosition: " + NewPosition);

# Adding an item to an array
set SideChestsPositions += array{Position};

# Go over an array
for (Index -> Spawner : CreatureSpawners):
  # do something with Spawner
  Spawner.Disable();

for (Spawner : CreatureSpawners):
  Spawner.Disable();

# Get a random element from an array
Index := GetRandomInt(0, CreatureSpawners.Length);

# Remove element form array - https://forums.unrealengine.com/t/how-to-remove-an-item-at-index-from-an-array-in-verse/833744
var MyDeviceArray:[]creative_device = array{}

if (NewArray := MyDeviceArray.RemoveElement[0]):
    set MyDeviceArray = NewArray

# For loop
for (i := 1..BankCoinsIncrement):
  Tracker.Increment(Agent);

# Int with float calculation
NewStoreLevel : int = Int[Score * 1.0 / 20.0];

# Float to Int
if:
  IntTime := Int[Time]

#enum
Value := enum_type.Value1;

# Maps - https://dev.epicgames.com/documentation/en-us/uefn/map-in-verse
# Declaration
WordCount : [string]int = map{"apple" => 0, "apple" => 1, "apple" => 2};
var CanvasMap:[player]canvas = map{};
# Adding an item to a map
set CanvasMap = ConcatenateMaps(CanvasMap, map{Player => Canvas});
# Recall
if (Canvas := CanvasMap[Player]):
  PlayerUI.RemoveWidget(Canvas);
# Removes an element from the given map and returns a new map without that element
RemoveKeyFromMap(ExampleMap:[player]canvas, ElementToRemove:player):[player]canvas=
  var NewMap:[player]canvas = map{}
  # Concatenate Keys from ExampleMap into NewMap, excluding ElementToRemove
  for (Key -> Value : ExampleMap, Key <> ElementToRemove):
      set NewMap = ConcatenateMaps(NewMap, map{Key => Value})
  return NewMap

# Events

# Subscribing to an event
EliminationManager.EliminatedEvent.Subscribe(OnCreatureEliminated);

# Declaring an event
CountdownEndedEvent<public> : event(float) = event(float){}

# Waiting for an event and adding one to a counter
loop:
  EliminationManager.EliminatedEvent().Await();
  set Count += 1;

# HUD

# Display the name of the player in a message
# Source: https://forums.unrealengine.com/t/how-to-get-the-display-name-of-a-player/840455
RewardMessage<localizes>(RoundNum:int):message = "Round #{RoundNum} complete! Get your reward  {playername}!";

# Functions
# Default function parameters ?

# Global / singletons
var GlobalAudioQueue:weak_map(session, audio_queue) = map{}

AudioQueuePlay(Player: agent, AudioPlayer: audio_player_device, Duration: float): void=
  if (AudioQueue := GlobalAudioQueue[GetSession()]):
    AudioQueue.Play(Player, AudioPlayer, Duration)
  else:
    AudioQueue := audio_queue{};
    if (set GlobalAudioQueue[GetSession()] = AudioQueue){}
    AudioQueue.Play(Player, AudioPlayer, Duration)
