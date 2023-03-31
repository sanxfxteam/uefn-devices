using { /Fortnite.com/Characters }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Game }
using { /Fortnite.com/Teams }
using { /Verse.org/Simulation }


player_map := [player]int # This is a type alias!

team_elimination_game := class(creative_device):

    @editable
    EndGameDevice : end_game_device = end_game_device{}

    @editable
    var WeaponGranters : []item_granter_device = array{}

    @editable
    var PlayerSpawners : []player_spawner_device = array{}

    @editable
    var Sentries : []sentry_device = array{}

    var EliminationsToEndGame : int = 0

    var Teams : []team = array{}

    # Map of Team Maps, where the key is the team and the value is a map of
    # player->int key-value pairs
    var TeamMap : [team]player_map = map{}  

    OnBegin<override>()<suspends> : void =
        set Teams = GetPlayspace().GetTeamCollection().GetTeams()
        set EliminationsToEndGame = WeaponGranters.Length
        Print("Beginning to assign players")

        PopulateTeamsAndPlayers()   

        for (Spawner : PlayerSpawners):
            Spawner.SpawnedEvent.Subscribe(OnPlayerSpawn) # Subscribe to each player spawn pad

        for (Sentry : Sentries):
            Sentry.EliminatedEvent.Subscribe(TestPlayerEliminated) # Subscribe to each Sentry

        # Subscribe to new players joining the game

        GetPlayspace().PlayerAddedEvent().Subscribe(OnPlayerAdded)

    PopulateTeamsAndPlayers() : void =
        Print("Beginning to populate players")
        for (Team : Teams, TeamPlayers := GetPlayspace().GetTeamCollection().GetAgents[Team]):
            var PlayerMap : player_map = map {}
            for (Agent : TeamPlayers, TeamPlayer := player[Agent], FortCharacter := Agent.GetFortCharacter[]): 
                if(set PlayerMap[TeamPlayer] = 0, WeaponTier := PlayerMap[TeamPlayer]): 
                    Print("Assigned Player to PlayerMap with Tier {WeaponTier}")
                FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated) 
            if(set TeamMap[Team] = PlayerMap):
                Print("Successfully set this team in the TeamMap")

    # Handles a new player joining the game

    OnPlayerAdded(InPlayer : player) : void =
        Print("A New Player Joined!")
        if:
            Team := GetPlayspace().GetTeamCollection().GetTeam[InPlayer]
            FortCharacter := InPlayer.GetFortCharacter[]
            var PlayerMap : player_map = TeamMap[Team]
            set PlayerMap[InPlayer] = 0
            set TeamMap[Team] = PlayerMap
        then:
            GrantWeapon(option{InPlayer}, 0)
            Print("Set new player weapon tier to 0 in the TeamMap")
            FortCharacter.EliminatedEvent().Subscribe(OnPlayerEliminated) # subscribe to this player's elimination event

    # Grants players weapons based on their WeaponTier when they spawn

    OnPlayerSpawn(InPlayer : agent) : void =
        Print("A player just spawned!")
        if:
            PlayerTeam := GetPlayspace().GetTeamCollection().GetTeam[InPlayer]
            WeaponTier:int := TeamMap[PlayerTeam][InPlayer]
        then:
            GrantWeapon(option{Agent}, WeaponTier)
            Print("Spawned Player was granted a gun of tier {WeaponTier}")

    OnPlayerEliminated(Result : elimination_result) : void =
        Print("A Player was eliminated!")
        Eliminator := Result.EliminatingCharacter
        if (FortCharacter := Eliminator?, EliminatorAgent := FortCharacter.GetAgent[]):
            GiveNextWeapon(EliminatorAgent)

    # Allows testing of GiveNextWeapon by spoofing Sentries as Players

    TestPlayerEliminated(Agent: ?agent) : void =
        Print("Sentry Down!")
        if(TeamPlayer := Agent?):
            GiveNextWeapon(TeamPlayer)

    GiveNextWeapon(EliminatingPlayer : agent) : void =
        Print("Finding a player to promote")
        var WeaponTier : int = 0
        var MaybePlayerToGrant : ?agent = option{EliminatingPlayer} # The player to grant a gun to
        var MaybePlayerTeam : ?team = option{GetPlayspace().GetTeamCollection().GetTeam[EliminatingPlayer]} # The team this player is on

        if(PlayerTeam := MaybePlayerTeam?, set WeaponTier = TeamMap[PlayerTeam][EliminatingPlayer]):
            for(Teammate -> TeammateTier : TeamMap[PlayerTeam], TeammateTier < WeaponTier):
                Print("Found a Teammate with a lower Tier at Tier {TeammateTier}")
                if(set WeaponTier = TeamMap[PlayerTeam][Teammate]):
                    set MaybePlayerToGrant = option{Teammate}

        set WeaponTier = WeaponTier + 1
        if(PlayerTeam := MaybePlayerTeam?, PlayerToGrant := player[MaybePlayerToGrant?], set TeamMap[PlayerTeam][PlayerToGrant] = WeaponTier):
            Print("Eliminating Player Tier is now {WeaponTier}")

        if(WeaponTier >= EliminationsToEndGame):
            EndGame(EliminatingPlayer)

        GrantWeapon(MaybePlayerToGrant, WeaponTier)
        
    GrantWeapon(InPlayer : ?agent, WeaponTier : int) : void =
        Print("Promoting Player to Tier {WeaponTier}")
        if(ItemGranter := WeaponGranters[WeaponTier], GrantedPlayer := InPlayer?):
            ItemGranter.GrantItem(GrantedPlayer)

    EndGame(InPlayer : agent) : void =
        Print("Player reached final Weapon Tier, activating EndGameDevice")
        EndGameDevice.Activate(InPlayer)