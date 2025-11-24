return [[
-----------------------------------------------------------
dates are M/D/YYYY est

+ add
~ change
- remove
-----------------------------------------------------------
[6/13/2024]
	[1]
		~ lite version by antiskid


[4/30/2023]
	[1]
		~ fixed a slight remote problem
		~ raised keys to 2^256

[4/28/2023]
	[1]
		~ evil

[4/15/2023]
	[1]
		~ fix remote not refitting on the server bruhhh
		~ improve ui antideath (hopefully shouldnt crash anymore)
		~ removed extraneous remoteserver module from when i was raging
		~ change request timeout time to inf
		~ change remote to cr parent to nil as much as possible
		~ fresh set of moduleids
		~ changed some GenerateGUID() that did not need uniqueness to randomstring()

[4/9/2023]
	[1]
		~ fix highlighter not sanitizing controls
		~ update lexer to the new one that supports interpolated strings
		~ update year in mainmodule
		~ disable autolocalize on all ui elements

[3/29/2023]
	[1]
		fsev2 rescript :D
		+ an additional textbox antilog method
		+ runscript method will always return a response, allowing for better error handling
		+ gui tamper resistance (protects stuff like uiaspectratiocontraint attacks)
		~ changed the remote function to a two way remoteevent
		~ gui no longer flashes for a frame when it gets reparented
		~ changed mainmodule header text
		~ fixed loadcall metatable vulnerability
		- removed all custom environment globals except for owner

[1/2/2023]
	[1]
		~ fix the remote some more
	[2]
		~ fix tab sources being messed up by new thing

[1/1/2023]
	[1]
		+ more fake require ids lol
		+ it does an extra thing when focuslost now idk if itll do anything useful
		~ changed get remote method

[12/8/2022]
	[1]
		~ increased output spam
		~ changed fake require spam to real require spam
		~ moved tab loading onto its own thread to speed up main loading

[12/3/2022]
	[1]
		+ made tabs save
		~ patched a vulnerability where the client used to send the encryption key unencrypted over the remote for confirmation

[11/25/2022]
	[1] (NIGHTLY ONLY!!!)
		+ testing new textbox thing
		+ custom textbox cursor along with it since the new textbox thing got rid of the regular one :<
		+ added a nightly require path in the loader so i dont have to change the id

[11/11/2022]
 	trying to make something work ...
	[1]
		~ fix an error with dragify
		~ fix line highlight being stupid
		~ fix calling the return value of fse erroring

[10/26/2022]
	[1]
		+ the gui automatically reappears if youve used it in the same server before
			sorry for not adding this one the first time
		- removed replicatedstorage from the replicatedservices list bc there was interference
		- removed the changelog styling lol
	
[10/9/2022]
	[1] ----------------------------------------------------------------------------  |
	 |  + some more anti log measures, another one is still in the works but im dumb  |
	 |  ~ improved errors                                                             |
	 |  ----------------------------------------------------------------------------  |

[10/4/2022]
	[1] ------------- |
	 |	+ changelogs  |
	 |	+ mit lience  |
	[2] --------------------------------------------------------------------- |
	 |  ~ fix opening animation not scaling to resized window size            |
	 |  ~ fix main tab disappearing after first respawn after getting the gui |
	 |  ~ locked Archivable off for gui instances                             |
	 | ---------------------------------------------------------------------- |
	 
days before 10/4/2022 were days when fsev2 was in its initial
development
]]