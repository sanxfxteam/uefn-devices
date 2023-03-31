using { /Verse.org/Simulation }
using { /Verse.org/Random }
using { /Verse.org/Concurrency }
using { /Verse.org/Simulation/Tags }
using { /UnrealEngine.com/Temporary/SpatialMath }
using { /Fortnite.com/Devices }

<# A zone is an area of the map (represented by a device) that can be Activated/Deactivated and that provides events
to signal when the zone has been "Completed" (can't be completed anymore until next activation).
Zone "Completed" depends on the device type (ActivatorDevice) for the zone.
Suggested usage: ActivateZone() -> ZoneCompletedEvent.Await() -> DeactivateZone() #>
base_zone<public> := class:
    ActivatorDevice<public> : creative_object_interface
    ZoneCompletedEvent<public> : event(base_zone) = event(base_zone){}

    GetTransform<public>() : transform =
        ActivatorDevice.GetTransform()

    <# Activates the Zone.
    You should enable devices and any visual indicators for the zone here. #>
    ActivateZone<public>() : void =
        # The base zone can handle zones defined as item spawners or capture areas.
        # Try and cast to each type to see which we're dealing with.
        if (CaptureArea := capture_area_device[ActivatorDevice]):
            CaptureArea.Enable()
            spawn { WaitForZoneCompleted(option{CaptureArea.PlayerEntersEvent}) }
        else if (ItemSpawner := item_spawner_device[ActivatorDevice]):
            ItemSpawner.Enable()
            spawn { WaitForZoneCompleted(option{ItemSpawner.ItemPickedUpEvent}) }
   
    <# Deactivates the Zone.
    You should disable devices and any visual indicators for the zone here. #>
    DeactivateZone<public>() : void =
        if (CaptureArea := capture_area_device[ActivatorDevice]):
            CaptureArea.Disable()
        else if (ItemSpawner := item_spawner_device[ActivatorDevice]):
            ItemSpawner.Disable()
        ZoneDeactivatedEvent.Signal()

    <# This event is necessary to terminate the WaitForZoneCompleted coroutine if the zone is deactivated without being completed. #>
    ZoneDeactivatedEvent<protected> : event() = event(){}

    WaitForZoneCompleted<private>(ZoneDeviceCompletionEventOpt : ?awaitable(player))<suspends> : void =
        if (DeviceEvent := ZoneDeviceCompletionEventOpt?):
            race:
                block:
                    DeviceEvent.Await()
                    ZoneCompletedEvent.Signal(Self)
                ZoneDeactivatedEvent.Await()

MakeBaseZone<constructor><public>(InActivatorDevice : creative_object_interface) := base_zone:
    ActivatorDevice := InActivatorDevice

# The tagged_zone_selector creates zones based on triggers tagged with the tag passed to InitZones.
tagged_zone_selector<public> := class:
    var Zones<protected> : []base_zone = array{}

    InitZones<public>(ZoneTag : tag) : void =
        <# On creation of a zone selector, find all available zones
        and cache them so we don't consume time searching for tagged devices
        every time the next zone is selected. #>
        ZoneDevices := GetDevicesWithTag(ZoneTag)
        set Zones = for (ZoneDevice : ZoneDevices):
            MakeBaseZone(ZoneDevice)

    SelectNext<public>()<transacts><decides> : base_zone =
        Zones[GetRandomInt(0, Zones.Length-1)]