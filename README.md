# DTPLoot
roll+ loot system addon for WoW

#--- Commands ---#

/dtploot[AnItemLink] OR /dtproll[AnItemlink]
        -> Starts loot process for linked item. Currently lasts until canceled.

/dtploot end OR /dtproll end
        -> Ends loot process for current item, displays winner.

/dtpbonus aCharacterName aNumber OR /dtbdb aCharacterName aNumber
        -> Sets a character's bounty bonus to the provided value.
                DOES NOTHING TO RANK BONUS

/dtpbonus reset OR /dtpdb reset
        -> Sets bounty bonus to 0 for all characters.
        Typically used once a week.

/dtpbonus show OR /dtpbonus all OR /dtpdb show OR /dtpdb all
        -> Shows all active bounties in officer chat.

#--- Notes ---#
Due to the way the WoW load sequence happens, this addon will require a couple of /reload or logouts until its database is fully built.
Using commands before that will return an error. If that happens to you, don't worry, you didn't break anything.


#--- Changelog ---#

v1.00 - First released 03/04/2020.
