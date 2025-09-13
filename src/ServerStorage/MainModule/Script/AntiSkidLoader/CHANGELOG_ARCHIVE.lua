--[[

latest changelog legend:

rush - rushed update

patch - bug fix/patched something or just minor changes

newantis - new antis

features - bigger update with more features or more commands

no_test - didn't test in Roblox Player

test_studio - tested in studio

test_im_def - tested Immediate and Deferred signalbehavior

test_player - tested in Roblox Player

test_evr - tested everything

legacy legend (wont use this legend anymore because its outdated):
'  tested TextChatService and LegacyChatService
"  tested LegacyChatService

Date format: DD:MM:YYYY

10.09.2025 - 13.09.2025 (DD:MM:YYYY) V14.4.12 patch, newantis
- added ;noscripts (alias ;noscr, ;descript)
- resetgui now clears StarterGui (this might trigger shutdown if someone runs antiskid and the old outdated abuse detection)
- isImmediate is now anonymous function
- Removed legacy code (things like funcs.forcedestroy bye bye forever)
- Gui detection should be less strict now (fixes this issue: https://github.com/loadstring1/antiskid-v14/issues/2)
- Decal detection should be less strict now
- Added anti malware.lua
- resetserver is now faster (fixes this issue: https://github.com/loadstring1/antiskid-v14/issues/4)
- new breakasset bypass method (check repo)

09.09.2025 (DD:MM:YYYY) V14.4.11 patch
- Bypass breakasset method that stupid owners of skidded require executors misuse for their own adventage
- Hello world from my new github repo btw!!!

02.09.2025 (DD:MM:YYYY) V14.4.10 newantis
- Added anti author
- g/gexe has new alias g/fse since its literally just fse

01.09.2025 (DD:MM:YYYY) V14.4.9 patch
- I tried fixing fps drop possibly related to anti kohl
- Anti kohl now kills that annoying stupid typing sound on client
- Anti kohl on serverside now artificially waits 5 seconds for clientsided antiskid to kick in (before destroying kohl)

25.07.2025 (DD:MM:YYYY) V14.4.8 features, patch
- Added SB UNC you can run it by using ;sbunc (;unc) command.
- unc check is more accurate when you test it in a private server because then nobody can manipulate the results.
- fixed zazol gui surviving antiskid
- fixed stuck notifications that never disappear

24.07.2025 (DD:MM:YYYY) V14.3.8 patch
- Improved anti adonis
- trolling ASRE with reupload ezezez

23.07.2025 (DD:MM:YYYY) V14.3.7 newantis, patch, test_studio, test_im_def
- Added anti tophat (kill during runtime and before it runs)
- Fixed anti nuke gui
- Attempted to fix anti sharkblood
- Added anti ultraskidded lord/redone ultraskidded lord (kill during runtime and before it runs)
- Added anti all seeing hand (because it is breaking guis)
- Added ;fly command (its a tool works on mobile/pc and supports FE)
- antiskid banlist merged with antiskid (forgot to mention this in previous update)
- Fixed Anti BanAsync breaking due to stupid roblox engine bug (it yielded pcall forever)
- Added ;backupstartergui
- Added ;backupgui
- Added ;restoregui
- Added ;restorestartergui
- From now on restorestartergui will restore guis without depending on ResetOnSpawn property.
- Added chat message when someone banned tries to join the server.
- Updated AI method for antiskid and its dependencies so it loads much faster now.

18.07.2025 (DD:MM:YYYY) V14.3.6 patch, test_studio, test_player
- patched leaked isa ripoff .tellme() from 2 years ago (very old leaked script)
- anti-slock temporarily removed bc it triggers false positives i have to fix that lol
- improved readability of notifications by adding UIStroke to TextLabels
- patched 90% of map changers and e god's kfc map changer
- patched supernull workspace gravity=10 script
- re-entrancy errors are now filtered away from ;serverlogs
- patched adonis with breakasset anything
- patched NFC (no filters chat) with breakasset anything
- patched loveingliamguy's nuke script
- also patched some other random leaked nuke scripts for good measure
- fixed AntiSkid's commands colliding with ASRE commands
- AntiSkid 30 fps drop problem has been fixed in ASRE.
- patched all possible env leaks (TODO: patch env leak in every individual command in next update)
- patched more guis and malicious messages
- improved ;exe stability and patched vulns in ;exe command
- changed text color to blue for better readability on chat
- ;exe command will now show you if your script errored or not

06.07.2025 (DD:MM:YYYY) V14.3.5 patch, test_stud, test_player
- patched neko guis
- patched basic textchatservice chathaxes (OnIncomingMessage, etc.)
- patched most remote detections
- updated remote communications anti death
- removed remoteserver from FSE lite in ;exe command
- added ;perfstats (;pstats) command shows server performance and client performance
- added ;checkcr (;cr) command that checks if your antiskid remote works
- fixed rs breaking modded fse (it was more of FSE problem than antiskid problem but im still listing this here in the changelog)
- added breakasset anything
- patched owl anti logger with breakasset (because it spams f9 console and lags server)
- patched exser with breakasset (because it gets script builders banned)
- patched abuse detection with breakasset (because it shutdowns server when you do StarterGui:ClearAllChildren() and its outdated)
- added ;kr (;killremotes) command
- added ;dummy (;d) command
- added ;cd (;cleardummies) command
- added ;slogs (;serverlogs) command (shows server logs but excludes requiring asset id)
- unpatched sans_gboard hub

04.07.2025 (DD:MM:YYYY) V14.3.4 patch, test_stud
- added ;cm (;clearmessages)
- added ;ch (;clearhints)
- added FSE exe after ;rs is done with resetting server
- patched obunga jumpscare by Mertish
- patched saul goodman jumpscare
- patched nuke gui
- added modded FSE that works for mobile players
- added g/ perfix


04.07.2025 (DD:MM:YYYY) V14.3.3 patch, test_stud, test_player, test_im_def
- Patched more skiddy guis
- Patched loadstr exposing callstack if it was enabled
- Fixed incorrect usage of parallel connection in AntiRemovePlrGUI
- Uncommented touchgui fix in resetserver (oops)
- Added 2 more services for remote parent
- Added parallel connection to AntiChange
- Anti LC was deleting lighting cannon scripts too late when SignalBehavior is set to Immediate (fixed in this update)
- UnbanAsync will now unban everyone when server shutdowns
- Added ;ps command (;privateserver)
- Patched env leak in AntiAdmin

03.07.2025 (DD:MM:YYYY) - V14.3.2 patch, test_stud, test_im_def, test_player
- Commands updated
- Antiskid module is now merged together client and server all in one (AntiSkid is now officially CR - client replicated)
- Fixed notification spam when skiddy map changer was detected
- Fixed AntiChange spamming warnings in studio while switching point of view from client to server
- Added server kick in AntiChange if PlayerGui can't be found after more than 100 tries
- Added loadstr support for ;exe command
- ;rs will no longer reset textchatservice due to coregui errors and because textchatcommands are impossible to refit (you can still use ;resetchat to force reset textchatservice)
- ;fixmouse should actually reset mouse icon now as expected
- Fixed shift lock problems during ;resetserver in one specific exe game
- Added parallel connections
- All of HD admin's and Kohl's commands will be disabled and guis deleted instantly if detected by antiskid
- Added anti kohls admin and updated AntiAdmin module
- Fixed SkidDetection getdescendants loop because it did not check if instance ClassName is Sky
- Added user whitelist
- Added ;shutdown command (only for whitelisted users)

18.06.2025 (DD:MM:YYYY) - V14.2.2 rush, patch, test_stud, no_test
- Added anti banasync (will unban everyone in loop)
- Changed way of how checkinstance works
- Fixed TouchGui for mobile players who couldn't move after resetserver or after antiskid showed its own gui

- In next version expect commands2 rewritten
See you later next version will be antiskid v14.3.2

17.06.2025 (DD:MM:YYYY)  - V14.2.1 =\
- Reset character should be way faster now
- Updated anti delusional neko
- Added more optimization to antis
- Anti HD admin is back
- Notifications revamped
- Fixed anti mesh from antiskid v12 breaking due to cmdhandler changes (migrated to antis2)
- Removed support for LegacyChatService
- Removed LegacyChatService from reset server command
- Fixed duplicated notifications when using reset server with new revamped notification system
- Command cooldown lowered to 5 seconds
- Added online script environment that got all native roblox functions to ;exe command
- Fixed memory leak in R6 and R15 command that incorrectly cleared cache when player left the server
- Fixed notification spam (hopefully once and forever)
- Notification text is now selectable
- Removed antis: anti you, lc voiding, anti abuse detection, anti cr trussman, anti virus ads
- Fully rewritten antis and old antis have been removed
- Changed notification text font
- Added anti 666
- Lifetime of a loop script ran thru ;exe command will be maximum 10 seconds after those 10 seconds thread of that script will be killed
- Added logo for antiskid
- Added anti patrick

!!NEW COMMANDS:
- Added online FSE executor back. Use ;gexe command to get GUI fse executor.
- Added ;fixmouse that fixes your mouse icon and resets it to default icon if skid scripts broke it
- Added ;resetlighting (alias ;rl)
- Added ;resetsounds (aliases ;ms ;mutesounds)
- Added ;playerlist (aliases ;plrlist)
- Added ;blockhttp (aliases ;bh)
- Added ;cmds commands that lists all existing commands


16.06.2024 - V14.1.1   \'=
- Fixed legacy chat not showing up after ;rs and ;resetchat command was executed
- Fixed slow messages when antiskid replied to your commands on legacy chat
- Fixed 40 second cooldown when using ;resetchat on legacy chat (its 20 seconds like its supposed to be)
- Resetting legacy chat should feel faster than before
- AntiSkid commands are now compatible with Immediate and Deferred signal behavior
- I am slowly migrating to Antis2 from 24.02.2024 update. (antis rewrite)
- ;r6, ;r15, ;autor6, ;autor15 will remember your position when switching between rig types
- Disabled commands are now back (;resetgui and ;resetchat)
- added ;notif command - say ;notif to disable gui notification and ;notif true to enable gui notifications if you disabled them
- This bug fix was one of the most annoying bug fixes i had to do

13.06.2024 - V14.1.0 *
- Commands return
- FSE Lite is debloated FSE without GUI. Its based on commands and you can use it by running ;exe print("hello world")
- ;exe command is powered by FSE all credits to ceat_ceat
- added autor6/autor15 command
- added r6/r15 command
- added ;resetchat command
- added ;resetgui command
- fixed invisible notification background
- added classic maps to ;resetmap command
- fixed devconsole breaking when antiskid was ran
- fixed false positives for camera breaking - this change most likely removed lcv2 voiding due to false positives
- added ;serverhop command (alias ;shop)
- returned message on how to run this script (its right below this changelog)

24.02.2024
- Removed license
- Removed local FSE copy
- Preload online version of FSE
- Added anti tophat
- Updated anti "abuse detection"
- Updated anti hd admin
- Updated anti delusional neko

10.09.2023
- Removed GPG signature
- Removed PGP signature
- GUI will not even show in lua assembling (place 1 and place 2) because mau just made something that automaticially removes it
- im not gonna play cat and mouse game and all i did in this update is just make it so the gui doesnt even get created in lua assembling


]]