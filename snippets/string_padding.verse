# SecondsRemaining is assumed to be non-negative
SecondsRemaining : int = 30
	
# Automatically convert the int representation to a string:
SecondsString:string = SecondsRemaining

# Set up the timer display string.
var Combined : string = "Time Remaining: "
	
# If the string is too long, replace it the maximum two-digit value, 99.
if (SecondsString.Length > 2):
    # Too much time on the clock! Set the string to a hard-coded max value.
    set Combined += "99"
else if (SecondsString.Length < 2):
    # Pad the display with a leading zero.
    set Combined += "0{SecondsString}"
else:
    # The string is already the exact length, so add it.
    set Combined += SecondsString