using { /Verse.org/Simulation }
using { /Fortnite.com/Devices }
using { /Fortnite.com/Vehicles }
using { /Fortnite.com/Characters }
using { /Fortnite.com/Playspaces }
using { /Verse.org/Native }
using { /Verse.org/Random }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/Curves }
using { /Verse.org/Simulation/Tags }

# Game zones tags
pickup_zone_tag<public> := class(tag):
pickup_zone_level_1_tag<public> := class(pickup_zone_tag):
pickup_zone_level_2_tag<public> := class(pickup_zone_tag):
pickup_zone_level_3_tag<public> := class(pickup_zone_tag):
delivery_zone_tag<public> := class(tag):

log_pizza_pursuit<internal> := class(log_channel){}

game_coordinator_device<public> := class(creative_device):
    @editable
    VehicleSpawner<public> : atk_spawner_device = atk_spawner_device{}

    # How long the countdown timer will start counting down from.
    @editable
    InitialCountdownTime<public> : float = 30.0

    @editable
    EndGame<public> : end_game_device = end_game_device{}

    # How many seconds to add to the countdown timer when a pickup is delivered.
    @editable
    DeliveryBonusSeconds<public> : float = 20.0

    @editable
    PickupMarker<public> : objective_marker = objective_marker{}

    @editable
    ScoreManagerDevice<public> : score_manager_device = score_manager_device{}

    @editable
    PizzaRemover<public> : item_remover_device = item_remover_device{}

    @editable
    # Maps how many points a pickup is worth based on its pickup level.
    PointsForPickupLevel<public> : []int = array{1, 2, 3}

    OnBegin<override>()<suspends> : void =       
         FindPlayer()
         SetupZones()
       
        # After entering the vehicle, the player could exit at any time; we
        # want to detect this every time it happens to put them back in the vehicle.
        VehicleSpawner.PlayerExitsVehicleEvent.Subscribe(HandlePlayerExitsVehicle)

        # We only want to be notified the first time the player enters the vehicle to start the game.
        # StartGameOnPlayerEntersVehicle will wait for that event and then start the gameplay loop.  
        StartGameOnPlayerEntersVehicle()

    Logger<private> : log = log{Channel := log_pizza_pursuit}
    var MaybePlayer<private> : ?player = false
    var CountdownTimer<private> : countdown_timer = countdown_timer{}
    var ScoreManager<private> : score_manager = score_manager{}
    DeliveryZoneSelector<private> : tagged_zone_selector = tagged_zone_selector{}
    var PickupZones<private> : []tagged_zone_selector = array{}

    FindPlayer<private>() : void =
        # Since this is a single player experience, the first player (0)
        # should be the only one available.
        Playspace := Self.GetPlayspace()
        if (FirstPlayer := Playspace.GetPlayers()[0]):
            set MaybePlayer = option{FirstPlayer}
            Logger.Print("Player found")
        else:
            # Log an error if we can't find a player.
            # This shouldn't happen because at least one player is always present.
            Logger.Print("Can't find valid player", ?Level := log_level.Error)

    SetupZones<private>() : void =
        # There's only one type of delivery zone, since they don't scale by difficulty level.
        DeliveryZoneSelector.InitZones(delivery_zone_tag{})

        # We use gameplay tags to select zones (represented by devices) based on their difficulty level.
        # Using an array makes it easier to modify difficulty levels: we can add more
        # levels, increase/decrease their granularity or change their order without touching the code.
        # Create one tagged_zone_selector for each difficulty level tag so all devices with the same tag (i.e. same difficulty level)
        # end up in the same selection pool.
        LevelTags : []pickup_zone_tag = array{pickup_zone_level_1_tag{}, pickup_zone_level_2_tag{}, pickup_zone_level_3_tag{}}
        set PickupZones = for (ZoneTag : LevelTags):
            NewZone := tagged_zone_selector{}
            NewZone.InitZones(ZoneTag)
            NewZone

    StartGameOnPlayerEntersVehicle<private>()<suspends> : void =
        VehiclePlayer := VehicleSpawner.PlayerEntersVehicleEvent.Await()
        Logger.Print("Player entered the vehicle")
        set MaybePlayer = option{ VehiclePlayer }
        StartGame()
       
    HandlePlayerExitsVehicle<private>(VehiclePlayer : player) : void =
        Logger.Print("Player exited the vehicle. Reassigning player to vehicle")
        VehicleSpawner.AssignDriver(VehiclePlayer)
           
    StartGame<private>()<suspends> : void =
        Logger.Print("Trying to start the game...")
        <# We construct a new countdown_timer that'll countdown from InitialCountdownTime once started.
        Also construct a new score_manager that'll keep track of the player's score and pickup level.
        The countdown_timer and score_manager require a player to show their UI to.
        We should have a valid player by now: the one that entered the vehicle, triggering the game start. #>
        if (ValidPlayer := MaybePlayer?):
            Logger.Print("Valid player, starting game...")

            set ScoreManager = MakeScoreManager(ValidPlayer, ScoreManagerDevice)
            ScoreManager.AddScoreManagerToUI()

            set CountdownTimer = MakeCountdownTimer(InitialCountdownTime, ValidPlayer)
            CountdownTimer.StartCountdown()

            # We wait for the countdown to end.
            # At the same time, we also run the Pickup and Delivery game loop that constitutes the core gameplay.
            race:
                HandleCountdownEnd(ValidPlayer)
                PickupDeliveryLoop()
        else:
            Logger.Print("Can't find valid player. Aborting game start", ?Level := log_level.Error)

    HandleCountdownEnd<private>(InPlayer : player)<suspends> : void =
        TotalTime := CountdownTimer.CountdownEndedEvent.Await()
        ScoreManager.AwardScore()
        EndGame.Activate(InPlayer)

    PickupDeliveryLoop<private>()<suspends> : void =
        MaxPickupLevel := PickupZonesTags.Length - 1
        FirstPickupZoneCompletedEvent := event(){}
        <# Defer disabling the MapIndicator so that terminating the PickupDeliveryLoop always ends up disabling the marker.
        Defer also executes if the PickupDeliveryLoop is canceled. #>
        defer:
            if (ValidPlayer := MaybePlayer?):
                PickupMarker.MapIndicator.DeactivateObjectivePulse(ValidPlayer)
            PickupMarker.MapIndicator.Disable()

        PickupMarker.MapIndicator.Enable()

        loop:
            var PickupLevel : int = 0
            var IsFirstPickup : logic = true

            <# Every time the loop restarts, we should reset the pickup level UI through the ScoreManager.
            The pickup level in the UI starts at 1 (not 0). Some players will be confused if it starts at 0.
            We index from 0, so PickupLevel=0 is Level 1 in the UI. #>
            ScoreManager.SetPickupLevel(PickupLevel + 1)

            race:
                loop:
                    if (PickupZone:base_zone = PickupZones[PickupLevel].SelectNext[]):
                        PickupZone.ActivateZone()
                        Sleep(1)
                        PickupMarker.MoveMarker(PickupZone.GetTransform(), ?OverTime := 0.0)
                        if (ValidPlayer := MaybePlayer?):
                            PickupMarker.MapIndicator.ActivateObjectivePulse(ValidPlayer)

                        <# This is the only defer we need for any PickupZone we activate. It will either deactivate the first PickupZone at the end of each outer loop,
                        or it'll deactivate any later PickupZone. That's because the expression is evaluated at the end, when the PickupZone variable has been bound to a newer zone. #>
                        defer:
                            PickupZone.DeactivateZone()

                        PickupZone.ZoneCompletedEvent.Await()
                        Logger.Print("Picked up", ?Level:=log_level.Normal)

                        <# We remove pizzas pickups from the player inventory to avoid stacking them and having them drop to the ground once the stack is full. #>
                        if (RemovingPlayer := MaybePlayer?):
                            PizzaRemover.Remove(RemovingPlayer)

                        # After the first pickup we can enable the delivery zone.
                        if (IsFirstPickup?):
                            set IsFirstPickup = false
                            FirstPickupZoneCompletedEvent.Signal()
                           
                        if (PickupPoints := PointsForPickupLevel[PickupLevel]):
                            ScoreManager.AddPendingPickupPoints(PickupPoints)

                        # Update the pickup level and ScoreManager.
                        if (PickupLevel < MaxPickupLevel):
                            set PickupLevel += 1
                            ScoreManager.SetPickupLevel(PickupLevel + 1)
                    else:
                        Logger.Print("Can't find next PickupZone to select.", ?Level := log_level.Error)
                        return # Error out of the PickupDeliveryLoop
                block:
                    FirstPickupZoneCompletedEvent.Await()

                    if (DeliveryZone := DeliveryZoneSelector.SelectNext[]):
                        DeliveryZone.ActivateZone()

                        # We defer zone deactivation so that canceling PickupDeliveryLoop also ends up deactivating any active delivery zone.
                        defer:
                            Logger.Print("Deactivating delivery zone.", ?Level:=log_level.Normal)
                            DeliveryZone.DeactivateZone()

                        DeliveryZone.ZoneCompletedEvent.Await()
                        Logger.Print("Delivered", ?Level:=log_level.Normal)

                        PointsCommitted := ScoreManager.AddPendingScoreToTotalScore()
                        BonusTime : float = DeliveryBonusSeconds * PointsCommitted
                        CountdownTimer.AddRemainingTime(BonusTime)
                    else:
                        Logger.Print("Can't find next DeliveryZone to select.", ?Level:=log_level.Error)
                        return # Error out of the PickupDeliveryLoop