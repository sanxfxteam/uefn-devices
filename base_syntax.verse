## Demonstration of the base syntax of the language.
## Including some troubleshooting tips.

# Arrays

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

# Get a random element from an array
Index := GetRandomInt(0, CreatureSpawners.Length);

# Events

# Subscribing to an event
EliminationManager.EliminatedEvent.Subscribe(OnCreatureEliminated);

# Declaring an event
CountdownEndedEvent<public> : event(float) = event(float){}


# HUD

# Display the name of the player in a message
# Source: https://forums.unrealengine.com/t/how-to-get-the-display-name-of-a-player/840455
RewardMessage<localizes>(RoundNum:int):message = "Round #{RoundNum} complete! Get your reward  {playername}!";