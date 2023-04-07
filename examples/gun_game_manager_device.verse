using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /Fortnite.com/Teams }
using { /Fortnite.com/Game }
using { /Fortnite.com/Characters }
using { /UnrealEngine.com/Temporary/Diagnostics }

# This code is a UEFN Fortnite "Device" for managing a Gun Game feature
# where players fight online and get a new weapon after each elimination
# https://gist.github.com/spentak/816d340200c7dafd7673e7f915b31b5b

# A Verse-authored creative device that can be placed in a level
gun_game_manager_device := class(creative_device):

    # Map data structure that stores players as the key
    # and current WeaponTier as the value
    var PlayerMap : [player]int = map{}

    # Item granters stored in an array so we can give the player
    # new weapons
    @editable
    var WeaponGranters : []item_granter_device = array{}

    # Array of bots for beating up and testing
    @editable
    var Sentries : []sentry_device = array{}

    # This is how we end the game later
    @editable
    EndGameDevice : end_game_device = end_game_device{}

    # Needed to let the game know when to end
    var ElimsToEndGame : int = 0

    # Runs when the device is started in a running game
    OnBegin<override>()<suspends>:void=
        set ElimsToEndGame = WeaponGranters.Length;
        InitPlayers()
        InitTestMode()

    InitPlayers() : void=
        AllPlayers := GetPlayspace().GetPlayers()
        for (Player : AllPlayers, FortCharacter := Player.GetFortCharacter[]):
            if (set PlayerMap[Player] = 0, WeaponTier := PlayerMap[Player]):
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated)
                GrantWeapon(Player, WeaponTier)

    GrantWeapon(Player : player, WeaponTier: int) : void=
        Print("Attempting to grant weapon")
        if (ItemGranter := WeaponGranters[WeaponTier]):
            Print("Granted item to player")
            ItemGranter.GrantItem(Player)

    OnPlayerEliminated(Result : elimination_result) : void=
        Eliminator := Result.EliminatingCharacter
        if (FortCharacter := Eliminator?, EliminatingAgent := FortCharacter.GetAgent[]):
            Print("We need to promote player")

    PromotePlayer(Agent : agent) : void=
        var WeaponTier : int = 0
        if (Player := player[Agent], PlayerWeaponTier := PlayerMap[Player]):
            set WeaponTier = PlayerWeaponTier + 1
            CheckEndGame(Agent, WeaponTier)
            
        if (Player := player[Agent], set PlayerMap[Player] = WeaponTier):
            GrantWeapon(Player, WeaponTier)

    
    InitTestMode() : void=
        for (Sentry : Sentries):
            Sentry.EliminatedEvent.Subscribe(TestPlayerElimination)
    
    TestPlayerElimination(Agent : ?agent) : void=
        Print("Sentry eliminated!")
        if (Player := Agent?):
            PromotePlayer(Player)


    CheckEndGame(Player : agent, WeaponTier : int) : void=
        if (WeaponTier >= ElimsToEndGame):
            EndGameDevice.Activate(Player)