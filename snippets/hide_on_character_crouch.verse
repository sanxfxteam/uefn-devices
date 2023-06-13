using { /Fortnite.com/Devices }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Simulation }
using { /Verse.org/Verse }

hello_crouch_device := class(creative_device):
    OnCrouch(MyChar:fort_character,Logic:logic):void=
        if(Logic?):
            Print("Hide")
            MyChar.Hide()
        else:
            MyChar.Show()
            Print("show")
    OnBegin<override>()<suspends>:void=
        Playspace: fort_playspace = GetPlayspace()
        AllPlayers: []player = Playspace.GetPlayers()
        if (FirstPlayer : player = AllPlayers[0]):
            if (FortniteCharacter : fort_character = FirstPlayer.GetFortCharacter[]):
                FortniteCharacter.CrouchedEvent().Subscribe(OnCrouch)
                Print("Try crouching")