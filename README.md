#---
-	DTPLoot is an addon designed to help lazy officers handle a roll+bonus loot sytem.
#---

#--- Getting the addon to work ---#

* Put in Interface/Addons folder and enable ingame
* Enter world, reload once.
* run /dptbonus reset
* All commands should now work as intended, hope the server doesn't crash :)

#--- Commands ---#

/dtploot[AnItemLink] OR /dtproll[AnItemlink]
        -> Starts loot process for linked item. Currently lasts until canceled.

/dtploot end OR /dtproll end
        -> Ends loot process for current item, displays winner.


/dtpbonus aCharacterName aNumber OR /dtbdb aCharacterName aNumber
        -> Sets a character's bounty bonus to the provided value.
                DOES NOT CHANGE RANK BONUS

/dtpbonus reset OR /dtpdb reset
        -> Sets bounty bonus to 0 for all characters.

/dtpbonus update
	-> reset, then asks for updated bounty list in /officer chat.
        
/dtpbonus show OR list OR all
        -> Shows all active bounties in officer chat. USE TO ANSWER TO AN UPDATE REQUEST.

/dtpdb can be substituted to /dtpbonus with all the above.

#--- Notes ---#
Server crashes don't properly save your savedvariables, and this is where this addon stores data.
Any changes made to bonuses between your last UI reload and a server crash will be lost.
'tis therefore recommended that you /reloadui after every significant change.

#--- Changelog ---#

v1.2 	- Changed output when nobody rolls on an item.
	- Set bonus for raiders/corrupted officers to 10.
	- Bugs for the bug lord.
	
v1.1 	- Added update request functionality. Bug fixes. Introduced new bugs :)

v1.00 	- First released 03/04/2020.
