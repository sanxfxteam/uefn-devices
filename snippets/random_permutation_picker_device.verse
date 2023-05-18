using { /Fortnite.com/Devices }
using { /Verse.org/Random }
using { /Verse.org/Simulation }
using { /UnrealEngine.com/Temporary/Diagnostics }

# The random_permutation_picker device generates a random permutation of
# its Choices and then picks them one at a time, without item repetition, with Pick.
# When the last choice has been picked, a new permutation is generated.
random_permutation_picker_device := class(creative_device):
    @editable
    PickButton:button_device = button_device{}
    # The Choices array is the set of elements to be picked.
    @editable
    var<private> Choices:[]switch_device = array{}
   
    var<private> PickStartIndex<private>:int=0
   
    # Pick one of the Choices, without repetition.
    # The algorithm uses a form of the Fisher-Yates shuffle to generate a random permutation.
    # See https://en.wikipedia.org/wiki/Fisher%E2%80%93Yates_shuffle
    # for a description of the Fisher-Yates shuffle algorithm.
    Pick<public>()<transacts><decides>:switch_device=
        # Imagine a hat with all the Choices in it.
        # The hat is full at the start of the permutation.
        # PickStartIndex is the index of the first element in the hat.
        # We pick an element from the hat, remove it from the hat, and return it.
        # When the hat is empty, we refill it and start a new permutation.

        # Generate a random integer between PickStartIndex and Choices.Length-1, inclusive.
        # This is the index of the element to be picked.
        PickedIndex := GetRandomInt(PickStartIndex, Choices.Length-1)
        # Select the element at PickedIndex. We'll swap it with the element at PickStartIndex and return it.
        PickedElement := Choices[PickedIndex]
        # Swap the element at PickStartIndex with the element at PickedIndex.
        # This "removes" the PickedElement from the hat, so it won't be picked again in this permutation.
        set Choices[PickedIndex] = Choices[PickStartIndex]
        # The element at PickStartIndex stays in the hat, so it can still be picked.
        set Choices[PickStartIndex] = PickedElement
        # Increment PickStartIndex. This "removes" the picked element from the hat.
        set PickStartIndex += 1
        # If PickStartIndex is greater than or equal to Choices.Length (no more Choices to pick),
        # reset it to 0.
        if (PickStartIndex >= Choices.Length):
            # This "refills" the hat to start a new permutation.
            set PickStartIndex = 0
        # Return the picked element.
        PickedElement

    OnBegin<override>()<suspends>:void=
        # This is how you could use the random_permutation_picker_device.
        # Here, we use the PickButton to pick a switch_device from the Choices array.
        loop:
            Agent := PickButton.InteractedWithEvent.Await()
            if (Picked := Pick[]):
                Picked.ToggleState(Agent)      