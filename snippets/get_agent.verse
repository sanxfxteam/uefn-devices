    # Gets an agent
    Playspace: fort_playspace := GetPlayspace();
    AllPlayers: []player = Playspace.GetPlayers();
    if (FirstPlayer: player = AllPlayers[0]):
      if (FortniteCharacter := FirstPlayer.GetFortCharacter[]):
        if (Agent: agent = FortniteCharacter.GetAgent[]):