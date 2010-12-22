(*
	# DESCRIPTION #
	
	This script "snoozes" the currently selected actions or projects by setting the start date to given number of days in the future.
	
	
	# LICENSE #
	
	Copyright © 2010 Dan Byler (contact: dbyler@gmail.com)
	Licensed under MIT License (http://www.opensource.org/licenses/mit-license.php)
	
	
	# CHANGE HISTORY #
	
	0.2c (2010-06-22)
	-	Actual fix for autosave
	
	0.2b (2010-06-21)
	-	Encapsulated autosave in "try" statements in case this fails
	
	0.2 (2010-06-15)
	-	Fixed Growl code
	-	Added performance optimization (thanks, Curt Clifton)
	-	Changed from LGPL to MIT license (MIT is less restrictive)
		
	0.1: Original release. (Thanks to Curt Clifton, Nanovivid, and Macfaninpdx for various pieces of code)

	
	# INSTALLATION #
	
	-	Copy to ~/Library/Scripts/Applications/Omnifocus
 	-	If desired, add to the OmniFocus toolbar using View > Customize Toolbar... within OmniFocus

	
	# KNOWN BUGS #
	
	-	When the script is invoked from the OmniFocus toolbar and canceled, OmniFocus returns an error. This issue does not occur when invoked from the script menu, a FastScripts or Quicksilver trigger, etc.
		
*)

property showAlert : false --if true, will display success/failure alerts
property useGrowl : true --if true, will use Growl for success/failure alerts
property defaultSnooze : 1 --number of days to snooze by default
property alertItemNum : ""
property alertDayNum : ""
property growlAppName : "Dan's Scripts"
property allNotifications : {"General", "Error"}
property enabledNotifications : {"General", "Error"}
property iconApplication : "OmniFocus.app"


tell application "OmniFocus"
	tell front document
		tell (first document window whose index is 1)
			set theSelectedItems to selected trees of content
			set numItems to (count items of theSelectedItems)
			if numItems is 0 then
				set alertName to "Error"
				set alertTitle to "Script failure"
				set alertText to "No valid task(s) selected"
				my notify(alertName, alertTitle, alertText)
				return
			end if
			
			display dialog "Snooze for how many days?" default answer defaultSnooze buttons {"Cancel", "OK"} default button 2
			set snoozeLength to (the text returned of the result) as integer
			set todayStart to (current date) - (get time of (current date))
			if snoozeLength is not 1 then
				set alertDayNum to "s"
			end if
			set selectNum to numItems
			set successTot to 0
			set autosave to false
			repeat while selectNum > 0
				set selectedItem to value of item selectNum of theSelectedItems
				set succeeded to my snooze(selectedItem, todayStart, snoozeLength)
				if succeeded then set successTot to successTot + 1
				set selectNum to selectNum - 1
			end repeat
			set autosave to true
			set alertName to "General"
			set alertTitle to "Script complete"
			if successTot > 1 then set alertItemNum to "s"
			set alertText to successTot & " item" & alertItemNum & " snoozed. The item" & alertItemNum & " will become available in " & snoozeLength & " day" & alertDayNum & "." as string
		end tell
	end tell
	my notify(alertName, alertTitle, alertText)
end tell

on snooze(selectedItem, todayStart, snoozeLength)
	set success to false
	tell application "OmniFocus"
		try
			set newStart to (todayStart + (86400 * snoozeLength))
			set start date of selectedItem to newStart
			set success to true
		end try
	end tell
	return success
end snooze

on notify(alertName, alertTitle, alertText)
	if showAlert is false then
		return
	else if useGrowl is true then
		--check to make sure Growl is running
		tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		if GrowlRunning = 0 then
			--try to activate Growl
			try
				do shell script "/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
				do shell script "~/Library/PreferencePanes/Growl.prefPane/Contents/Resources/GrowlHelperApp.app/Contents/MacOS/GrowlHelperApp > /dev/null 2>&1 &"
			end try
			delay 0.2
			tell application "System Events" to set GrowlRunning to ((application processes whose (name is equal to "GrowlHelperApp")) count)
		end if
		--notify
		if GrowlRunning ≥ 1 then
			try
				tell application "GrowlHelperApp"
					register as application growlAppName all notifications allNotifications default notifications allNotifications icon of application iconApplication
					notify with name alertName title alertTitle application name growlAppName description alertText
				end tell
			end try
		else
			set alertText to alertText & " 
 
p.s. Don't worry—the Growl notification failed but the script was successful."
			display dialog alertText with icon 1
		end if
	else
		display dialog alertText with icon 1
	end if
end notify
