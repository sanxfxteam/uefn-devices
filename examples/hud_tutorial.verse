using { /Fortnite.com/Devices }
using { /Fortnite.com/UI }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /UnrealEngine.com/Temporary/UI }
 
HUD_Tutorial := class(creative_device):
    @editable var MyButton : button_device = button_device{}
    @editable var AssignAllHUDSTrigger : trigger_device = trigger_device{}
    @editable var RemoveAllHUDSTrigger : trigger_device = trigger_device{}
 
 
    var MaybeMyUIPerPlayer : [player]?canvas = map{}
 
    OnBegin<override>()<suspends>:void=
        Print("HUD_Tutorial has begun")
        MyButton.InteractedWithEvent.Subscribe(HandleMyButton)
        AssignAllHUDSTrigger.TriggeredEvent.Subscribe(AssignAllHUDS)
        RemoveAllHUDSTrigger.TriggeredEvent.Subscribe(RemoveAllHUDS)
 
    AssignAllHUDS(Agent:?agent):void=
        Print("Assigning all huds")
        CurrentPlayers := GetPlayspace().GetPlayers()
        for(Player:CurrentPlayers):
            if(MyAgent := agent[Player]):
                HandleMyButton(MyAgent)
 
    HandleMyButton(Agent:agent):void=
        Print("MyButton was pressed")
        if(Player:=player[Agent], PlayerUI:=GetPlayerUI[Player]):
            #If the player has a canvas:
            if(MyUI:=MaybeMyUIPerPlayer[Player]?):
                Print("Player already has a HUD")
                PlayerUI.RemoveWidget(MyUI)
                if(set MaybeMyUIPerPlayer[Player] = false){}
            #If the player does not have a canvas:
            else:
                Print("Player does not have a HUD")
                var MyCanvas : canvas = MakeCanvas()
                PlayerUI.AddWidget(MyCanvas,player_ui_slot{InputMode:=ui_input_mode.All})
                if(set MaybeMyUIPerPlayer[Player] = option{MyCanvas}){}
 
    @editable Button1_Text : string = ""
    @editable Button1_Position : vector2 = vector2{}
    @editable Button1_Size : vector2 = vector2{}
 
    @editable Button2_Text : string = ""
    @editable Button2_Position : vector2 = vector2{}
    @editable Button2_Size : vector2 = vector2{}
 
 
    StringToMessage<localizes>(S:string):message="{S}"
 
    MakeCanvas():canvas=
 
        Button1 : button_loud = button_loud{}
        Button1.SetText(StringToMessage(Button1_Text))
        Button1.OnClick().Subscribe(HandleButton1)
 
        Button2 : button_regular = button_regular{}
        Button2.SetText(StringToMessage(Button2_Text))
        Button2.OnClick().Subscribe(HandleButton2)
 
        var MyCanvas : canvas = canvas:
            #add contents of canvas
            Slots := array:
                canvas_slot:
                    Widget:=Button1
                    ZOrder:=0
                    SizeToContent:=false
                    Offsets:=margin{Top:=Button1_Position.Y,Left:=Button1_Position.X,Bottom:=Button1_Size.Y,Right:=Button1_Size.X}
 
                canvas_slot:
                    Widget:=Button2
                    ZOrder:=1
                    SizeToContent:=false
                    Offsets:=margin{Top:=Button2_Position.Y,Left:=Button2_Position.X,Bottom:=Button2_Size.Y,Right:=Button2_Size.X}
 
        return MyCanvas
 
    @editable Button1_Outcome_Trigger : trigger_device = trigger_device{}
    HandleButton1(Wdata:widget_message):void=
        Print("Button1 Pressed")
        RemoveHUD(Wdata)
        if(Agent := agent[Wdata.Player]):
            Button1_Outcome_Trigger.Trigger(Agent)
 
    @editable Button2_Outcome_Trigger : trigger_device = trigger_device{}
    HandleButton2(Wdata:widget_message):void=
        Print("Button2 Pressed")
        RemoveHUD(Wdata)
        if(Agent := agent[Wdata.Player]):
            Button2_Outcome_Trigger.Trigger(Agent)
 
 
    RemoveAllHUDS(Agent:?agent):void=
        Print("Removing All HUDS")
        CurrentPlayers := GetPlayspace().GetPlayers()
        for(Player:CurrentPlayers):
            if(MyAgent:=agent[Player]):
                if(PlayerUI:=GetPlayerUI[Player], MyUI:=MaybeMyUIPerPlayer[Player]?):
                    PlayerUI.RemoveWidget(MyUI)
                    if(set MaybeMyUIPerPlayer[Player] = false){}
 
    RemoveHUD(Wdata:widget_message):void=
        Print("Removing HUD")
        if(Player:=Wdata.Player, PlayerUI:=GetPlayerUI[Player], SelectedButton:=Wdata.Source):
            if(MyUI:=MaybeMyUIPerPlayer[Player]?):
                PlayerUI.RemoveWidget(MyUI)
                if(set MaybeMyUIPerPlayer[Player] = false){}