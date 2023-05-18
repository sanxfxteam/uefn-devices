#https://dev.epicgames.com/documentation/en-us/uefn/creating-in-game-ui-in-verse?application_version=1.0
using { /Fortnite.com/Devices }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/UI }
using { /Fortnite.com/UI }
using { /UnrealEngine.com/Temporary/SpatialMath}

widget_ui_device := class(creative_device):

  # Set the Button device in the Editor to reference the device in the level
  @editable
  MyButton : button_device = button_device{}

  # A localizable message to display as text in the UI
  TextForMyUI<localizes> : message = "Hello, world!"

  # A mapping between the Player and the widget that may have been added to their UI
  var MaybeMyUIPerPlayer : [player]?text_block = map{}

  # Runs when the device is started in a running game
  OnBegin<override>()<suspends> : void =
      MyButton.InteractedWithEvent.Subscribe(HandleButtonInteraction)

  # A custom UI can only be associated with a specific player, and only that player can see it
  HandleButtonInteraction(Agent : agent) : void =
      # Agents can be a player or AI, but you can only get the UI of a player
      # so you must cast the Agent, who interacted with the Button device, to the player type
      if (InPlayer := player[Agent], PlayerUI := GetPlayerUI[InPlayer]):
          if (MyUI := MaybeMyUIPerPlayer[InPlayer]?):
              PlayerUI.RemoveWidget(MyUI)
              if (set MaybeMyUIPerPlayer[InPlayer] = false) {}
          else:
              NewUI := text_block{DefaultText := TextForMyUI}
              PlayerUI.AddWidget(NewUI)
              if (set MaybeMyUIPerPlayer[InPlayer] = option{NewUI}) {}