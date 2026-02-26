local ZygorGuidesViewer=ZygorGuidesViewer
if not ZygorGuidesViewer then return end
if UnitFactionGroup("player")~="Alliance" then return end

ZygorGuidesViewer:RegisterGuide("Ares' WotLK 3.3.5a Guides\\Professions\\Mining 1-65 (Starter Hub)",[[
	author wow-professions.com
	type professions
	startlevel 5
	description Starter launcher for Alliance Mining 1-65 by race starting zone.
	step
		'Choose your Alliance 1-65 starter route:
		.' Elwynn Forest (Human) |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Mining 1-65\\Elwynn Forest"
		.' Dun Morogh (Dwarf/Gnome) |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Mining 1-65\\Dun Morogh"
		.' Darkshore (Night Elf) |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Mining 1-65\\Darkshore"
		.' Back to Professions landing page |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Profession 1-450 Coverage Plan"
]])

ZygorGuidesViewer:RegisterGuide("Ares' WotLK 3.3.5a Guides\\Professions\\Mining 1-65\\Elwynn Forest",[[
	author wow-professions.com
	type professions
	startlevel 5
	description Mining 1-65 starter segment for Elwynn Forest (Alliance/Human).
	step
		'Train Mining and buy a Mining Pick.
		#include "trainer_Mining"
		.skillmax Mining,75
		#include "vendor_Mining"
		.buy 1 Mining Pick##2901
	step
		loop Elwynn Forest,34,51;40,52;43,49;49,59;50,64;59,61;57,56;61,53;70,68;50,85;51,76;48,72;43,73;41,80;38,78;40,73;37,70;34,71;31,70;25,68;20,71;21,78;27,66;30,64;29,59;28,57;32,53 |until skill("Mining")>=65
		.' Cave nodes at 61,53 and 41,80 can be dangerous at low level.
		#include "follow_path_mine"
		skill Mining,65
	step
		'Continue with Mining 65-125 zone selection. |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Mining 65-125 (Common)"
]])

ZygorGuidesViewer:RegisterGuide("Ares' WotLK 3.3.5a Guides\\Professions\\Mining 1-65\\Dun Morogh",[[
	author wow-professions.com
	type professions
	startlevel 5
	description Mining 1-65 starter segment for Dun Morogh (Alliance/Dwarf/Gnome).
	step
		'Train Mining and buy a Mining Pick.
		#include "trainer_Mining"
		.skillmax Mining,75
		#include "vendor_Mining"
		.buy 1 Mining Pick##2901
	step
		.' Dun Morogh loop 1 (East route).
		loop Dun Morogh,62,48;66,50;73,49;75,54;82,54;81,57;77,60;77,62;74,61;72,58;71,61;68,60;67,59;70,56;68,56;64,59;62,61;58,58;57,55;55,55;62,52 |until skill("Mining")>=65
		.' Cave node at 70,56 can be dangerous at low level.
		#include "follow_path_mine"
		skill Mining,65
	step
		.' Dun Morogh loop 2 (West route).
		loop Dun Morogh,44,30;38,30;37,33;35,31;31,36;28,35;29,39;28,45;25,45;25,50;26,56;29,55;30,57;32,58;31,53;36,48;35,42;40,40 |until skill("Mining")>=65
		.' Cave node at 25,50 can be dangerous at low level.
		#include "follow_path_mine"
		skill Mining,65
	step
		'Continue with Mining 65-125 zone selection. |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Mining 65-125 (Common)"
]])

ZygorGuidesViewer:RegisterGuide("Ares' WotLK 3.3.5a Guides\\Professions\\Mining 1-65\\Darkshore",[[
	author wow-professions.com
	type professions
	startlevel 5
	description Mining 1-65 starter segment for Darkshore (Alliance/Night Elf).
	step
		'Train Mining and buy a Mining Pick.
		#include "trainer_Mining"
		.skillmax Mining,75
		#include "vendor_Mining"
		.buy 1 Mining Pick##2901
	step
		.' Start at Auberdine (38,44), then run this loop:
		loop Darkshore,42,45;43,51;46,50;48,37;54,33;54,28;59,24;61,20;61,7;57,18;53,18;51,22;46,21;43,22;43,35;40,37 |until skill("Mining")>=65
		#include "follow_path_mine"
		skill Mining,65
	step
		'Continue with Mining 65-125 zone selection. |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Mining 65-125 (Common)"
]])

ZygorGuidesViewer:RegisterGuide("Ares' WotLK 3.3.5a Guides\\Professions\\Mining 125-175\\Arathi Highlands (Alliance)",[[
	author wow-professions.com
	type professions
	startlevel 10
	description Mine Iron, Tin, and Gold in Arathi Highlands to 175 (Alliance variant).
	description This route is incomplete, untested, or placeholder and may contain errors.
	step
		'Requires Mining 125. Train Expert here if needed.
		skill Mining,125
		#include "trainer_Mining"
		.skillmax Mining,225
	step
		loop Arathi Highlands,49.1,51.1;53.3,36.7;50.0,38.7;47.6,37.5;34.6,43.9;53.8,77.1;69.2,74.8;81.1,35.4;39.7,43.0;38.9,47.0;35.7,41.8;42.5,34.0;39.2,26.8;31.1,20.0;27.6,19.3;29.8,31.3;24.1,27.8;24.1,33.6;20.2,33.2;23.5,44.3;30.5,51.7;31.6,56.2;32.7,61.8;34.0,64.9;37.5,57.7;39.2,61.8;39.7,68.8;41.8,72.1;42.7,76.4;52.0,76.7;54.2,73.8;55.1,66.6;62.1,72.1;64.6,65.9;65.5,73.2;70.4,71.1;72.5,60.8;71.2,48.6;80.0,39.1;79.3,34.0;77.1,32.1;76.2,29.0;65.6,27.4;63.9,31.9;59.5,32.5;59.8,41.6 |until skill("Mining")>=175 |tip Cave order west to east: 34.6,43.9; 53.8,77.1; 69.2,74.8; 81.1,35.4. Start from Refuge Pointe at 49.1,51.1 then 53.3,36.7. Low-level players should skip all 4 caves. Alliance detour near Hammerfall: 71.2,48.6 -> 65.6,27.4.
		#include "follow_path_mine"
		skill Mining,175
	step
		'Continue with Mining 175-245 zone selection. |confirm |next "Ares' WotLK 3.3.5a Guides\\Professions\\Mining 175-245 (Common)"
]])
