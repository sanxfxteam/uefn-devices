using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }

MakeScoreManager<constructor><public>(InPlayer : player, InScoreManagerDevice : score_manager_device) := score_manager:
    MaybePlayer := option{InPlayer}
    MaybePlayerUI := option{GetPlayerUI[InPlayer]}

score_manager := class:
    <# Since we won't recreate the canvas during the score manager lifetime, do it once
    anytime an object of this type is created. #>
    block:
        set Canvas = canvas:
            Slots := array:
                canvas_slot:
                    Widget := stack_box:
                        Orientation := orientation.Vertical
                        Slots := array:
                            stack_box_slot:
                                Widget := TotalPickupPointsTextBlock
                            stack_box_slot:
                                Widget := PendingPickupPointsTextBlock
                            stack_box_slot:
                                Widget := PickupLevelTextBlock
                    Offsets := margin{ Top:=0.0, Left:=500.0 }

    AddScoreManagerToUI<public>() : void =
        if (PlayerUI := MaybePlayerUI?):
            PlayerUI.AddWidget(Canvas)
            UpdateUI()

    <# Adds PendingPickupPoints to TotalPickupPoints and resets PendingPickupPoints to 0.
    Returns the total number of Pickup Points added. #>
    AddPendingScoreToTotalScore<public>() : int =
        set TotalPickupPoints += PendingPickupPoints

        defer:
            set PendingPickupPoints = 0
            UpdateUI()

        PendingPickupPoints

    <# Adds the given amount of points to the pending points. #>
    AddPendingPickupPoints<public>(Points : int) : void =
        set PendingPickupPoints += Points
        UpdateUI()
   
    SetPickupLevel<public>(Level : int) : void =
        set PickupLevel = Level
        UpdateUI()

    <# Awards the score to the player via the ScoreManagerDevice, activating it. #>
    AwardScore<public>() : void =
        ScoreManagerDevice.SetScoreAward(TotalPickupPoints)
        if (AwardedPlayer := MaybePlayer?):
            ScoreManagerDevice.Activate(AwardedPlayer)
           
    MaybePlayer<internal> : ?player = false
    MaybePlayerUI<internal> : ?player_ui = false
    ScoreManagerDevice<internal> : score_manager_device = score_manager_device{}
    var Canvas<internal> : canvas = canvas{}
    TotalPickupPointsTextBlock<internal> : text_block = text_block{}
    PendingPickupPointsTextBlock<internal> : text_block = text_block{}
    PickupLevelTextBlock<internal> : text_block = text_block{}

    var TotalPickupPoints<private> : int = 0
    var PendingPickupPoints<private> : int = 0
    var PickupLevel<private> : int = 0
   
    UpdateUI<private>() : void =
        if (PlayerUI := PlayerUIOpt?):
            PickupLevelTextBlock.SetText("Pickup Level: {PickupLevel}")
            PendingPickupPointsTextBlock.SetText("Pending Points: {PendingPickupPoints}")
            TotalPickupPointsTextBlock.SetText("Total Points: {TotalPickupPoints}")