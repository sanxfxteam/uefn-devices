using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }

# See https://dev.epicgames.com/documentation/en-us/uefn/create-your-own-device-in-verse for how to create a verse device.

# A Verse-authored creative device that can be placed in a level
custom_character_device := class(creative_device):

    @editable IdleAnim : cinematic_sequence_device = cinematic_sequence_device{}
    @editable RunAnim : cinematic_sequence_device = cinematic_sequence_device{}

    @editable FGChar : creative_prop = creative_prop{}

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        AllPlayers := GetPlayspace().GetPlayers()
        if (Player := AllPlayers[0], Agent := agent[Player], Fort := Agent.GetFortCharacter[]):
            Fort.Hide()
            IdleAnim.Play(Agent)
            Fort.SprintedEvent().Subscribe(OnMoved)
            spawn:
                UpdateCharacter(Fort, vector3{Z:=-90.0, Y:=-100.0})

    UpdateCharacter(Player : fort_character, Offset : vector3)<suspends>:void=
        loop:
            Sleep(0.0)
            NewPos := Player.GetTransform().Translation + Offset
            if (FGChar.TeleportTo[NewPos, Player.GetTransform().Rotation]) {}


    OnMoved(MoveData : tuple(fort_character, logic)):void=
        if (Agent := MoveData(0).GetAgent[]):
            if (MoveData(1)?):
                IdleAnim.Stop(Agent)
                RunAnim.Play(Agent)
            else:
                RunAnim.Stop(Agent)
                IdleAnim.Play(Agent)