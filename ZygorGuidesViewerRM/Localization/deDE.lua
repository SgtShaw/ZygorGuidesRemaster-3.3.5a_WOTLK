if GetLocale()~="deDE" then return end

-- These are the main viewer's lines.

local COLOR_TIP_MOUSE = "|cffeedd99"
local COLOR_TIP_HINT = "|cff99ff00"
local COLOR_TIP = "|cff00ff00"

ZygorGuidesViewer_L("Main", "deDE", function() return {
	["name"] = "|cffffff88Z|cffffee66y|cffffdd44g|cffffcc22o|cffffbb00r |cffffaa00Guide-Betrachter|r",
	["name_plain"] = "Zygor Guide-Betrachter",
	["desc"] = "Haupteinstellungen fuer Zygor Guides Viewer %s.|n",

	['welcome_guides'] = "%d Guides sind geladen.",

	["opt_guide"] = "Guide auswaehlen:",
	["opt_guide_steps"] = "Schritte: %d",
	["opt_guide_author"] = "Autor: %s",
	["opt_guide_next"] = "Naechster in der Reihe: %s",

	["opt_report"] = "Fehlerhaften Schritt melden",
	["opt_report_desc"] = "Erstellt einen Fehlerbericht mit den Details des aktuell angezeigten Schritts. Kopieren/einfuegen und an die Guide-Autoren senden.",

	["opt_visible"] = "Zygor Guides Viewer-Fenster anzeigen",
	["opt_visible_desc"] = "",
	["opt_hideincombat"] = "Guides im Kampf ausblenden",
	["opt_hideincombat_desc"] = "Blendet alle Guide-Fenster waehrend des Kampfes aus, wenn der Bildschirm zu voll wird.",
	
	--["opt_group_main"] = "Main window settings",
	["opt_opacitymain"] = "Deckkraft",
	["opt_opacitymain_desc"] = "Deckkraft des Hauptfensters.",
	["opt_framescale"] = "Skalierung",
	["opt_framescale_desc"] = "Fenstergroesse nach deinen Vorlieben anpassen.",
	["opt_fontsize"] = "Textgroesse",
	["opt_fontsize_desc"] = "Bevorzugte Textgroesse. Die Fensterskalierung beeinflusst diesen Wert ebenfalls.",
	["opt_fontsecsize"] = "Sekundaere Textgroesse",
	["opt_fontsecsize_desc"] = "Bevorzugte sekundaere Textgroesse fuer zusaetzliche Beschreibungen und Hinweise.",
	["opt_backcolor"] = "Hintergrundfarbe",
	["opt_backcolor_desc"] = "Hintergrundfarbe des Fensters.",

	["opt_group_window"] = "Fensterfunktionen",
	--["opt_minimapnotedesc"] = "Show waypoint caption",
	--["opt_minimapnotedesc_desc"] = "Show the relevant waypoint's caption not only on the waypoint's tooltip, but on the mini window as well.",
	--["opt_showgoals"] = "Show step goals",
	--["opt_showgoals_desc"] = "Show step completion goals in the mini window",
	--["opt_autosizemini"] = "Auto-size",
	--["opt_autosizemini_desc"] = "Automatically adjust the height of the mini window.",
	["opt_miniresizeup"] = "Nach oben vergroessern",
	["opt_miniresizeup_desc"] = "Dreht die Erweiterungsrichtung um, sodass das Fenster nach oben statt nach unten waechst. Nuetzlich am unteren Bildschirmrand.",
	["opt_opacitymini"] = "Hintergrund-Deckkraft",
	["opt_opacitymini_desc"] = "Deckkraft des Schrittfenster-Hintergrunds.",

	--["opt_showallsteps"] = "Collapsed mode",
	--["opt_showallsteps_desc"] = "Display only the current step and some next steps, instead of the whole guide",

	["opt_showcountsteps"] = "Schritte anzeigen:",
	["opt_showcountsteps_desc"] = "Anzahl der anzuzeigenden Schritte.\n|cffffffaaAlle|r zeigt alle Schritte in einer scrollbaren Liste.\n|cffffffaa1-5|r zeigt den aktuellen Schritt oben und passt die Fenstergroesse automatisch fuer einige folgende Schritte an.",
	["opt_showcountsteps_all"] = "Alle",

	["opt_group_map"] = "Wegpunkte",
	["opt_group_map_desc"] = "Diese Einstellungen steuern, wie Zygor Guides Viewer mit Karten-Addons zusammenarbeitet.",
	["opt_group_map_waypointing"] = "Wegpunkt-Addon",
	["opt_group_map_waypointing_desc"] = "Waehle das Addon, das Wegpunkte fuer Zygor Guides Viewer verwalten soll.",
	["opt_group_addons_builtin"] = "Integrierte Wegpunkte",
	["opt_group_addons_tomtom"] = "TomTom (Addon)",
	["opt_group_addons_cart2"] = "Cartographer 2 (Addon)",
	["opt_group_addons_cart3"] = "Cartographer 3 (Addon)",
	["opt_group_addons_metamap"] = "MetaMap (Addon)",
	["opt_group_addons_none"] = "keins",
	["opt_debug"] = "Fehlersuche",
	["opt_debug_desc"] = "Debug-Informationen anzeigen.",
	["opt_debugging"] = "Fehlersuche",
	["opt_debugging_desc"] = "Debugging-Optionen.",
	--["opt_browse"] = "Toggle windows",
	 --["opt_browse_desc"] = "Toggle the visibility of either of Zygor's Guides windows.",

	["opt_autoskip"] = "Automatisch weiter",
	["opt_autoskip_desc"] = "Springt automatisch zum naechsten Schritt, wenn alle Bedingungen erfuellt sind. Einige komplexe Schritte muessen eventuell weiterhin manuell uebersprungen werden.",

	["opt_goalicons"] = "Schritt-Symbole anzeigen",
	["opt_goalicons_desc"] = "Symbole entsprechend dem Fortschrittsstatus anzeigen.",
	["opt_goalcolorize"] = "Abgeschlossene Schrittzeilen einfaerben",
	["opt_goalcolorize_desc"] = "Abgeschlossene Schrittzeilen vollstaendig gruen einfaerben.",
	["opt_goalbackprogress"] = "Farben nach Fortschrittsprozent anwenden",
	["opt_goalbackprogress_desc"] = "Teilfortschritt als Zwischenfarben zwischen unvollstaendig und vollstaendig anzeigen.|nWenn aus, werden nur die Farben fuer 'unvollstaendig' und 'vollstaendig' verwendet.",

	["opt_group_step"] = "Schrittziele",

	["opt_goalbackcolor_desc"] = "Fortschrittsfarben:",
	["opt_goalbackgrounds"] = "Hintergruende einfaerben",
	["opt_goalbackgrounds_desc"] = "Hintergruende der Schrittzeilen gemaess Fortschritt einfaerben.",
	["opt_goalbackcomplete"] = "Vollstaendig",
	["opt_goalbackcomplete_desc"] = "Diese Farbe fuer vollstaendige Ziele verwenden.",
	["opt_goalbackincomplete"] = "Unvollstaendig",
	["opt_goalbackincomplete_desc"] = "Diese Farbe fuer unvollstaendige Ziele verwenden.",
	["opt_goalbackimpossible"] = "Unmoeglich",
	["opt_goalbackimpossible_desc"] = "Diese Farbe fuer derzeit unmoegliche Ziele verwenden.",

	['opt_tooltipsbelow'] = "Zusaetzliche Infos in der Zeile anzeigen",
	['opt_tooltipsbelow_desc'] = "Zusaetzliche Informationen zu bestimmten Schrittzeilen koennen direkt in der Zeile oder als Tooltip beim Ueberfahren angezeigt werden.",

	["opt_flash_desc"] = "Fortschrittsbenachrichtigung:",
	["opt_goalcompletionflash"] = "Ziel bei Abschluss aufblitzen lassen",
	["opt_goalcompletionflash_desc"] = "Verwendet einen visuellen Aufblitz-Effekt, wenn ein einzelnes Ziel abgeschlossen wird.",
	["opt_goalupdateflash"] = "Ziel bei Fortschritt aufblitzen lassen",
	["opt_goalupdateflash_desc"] = "Verwendet einen visuellen Aufblitz-Effekt, wenn ein einzelnes Ziel Fortschritt erhaelt.",
	["opt_flashborder"] = "Fenster bei Schrittabschluss aufblitzen lassen",
	["opt_flashborder_desc"] = "Laesst das gesamte Fenster aufblitzen, wenn ein Schritt abgeschlossen wird.",

	--["opt_colorborder"] = "Color step window border",
	--["opt_colorborder_desc"] = "Use the step window border's color to indicate completion of the whole step.",

	["opt_group_display"] = "Anzeige",
	["opt_group_display_desc"] = "Lege fest, wie die Guides angezeigt werden sollen.",

	["opt_group_data"] = "Gespeicherte Guides",
	["opt_group_data_desc"] = "Zygor Guides Viewer kann kommerzielle Guides intern speichern, die nicht als eigenstaendige Addons verteilt werden duerfen.",
	["opt_group_data_guide"] = "Intern gespeicherte Guides:",
	["opt_group_data_guide_desc"] = "Waehle einen gespeicherten Guide aus dieser Liste, um ihn zu bearbeiten oder zu loeschen. Diese Liste zeigt KEINE separat geladenen Addons.",
	["opt_group_data_del"] = "Guide loeschen",
	["opt_group_data_del_desc"] = "Loescht den ausgewaehlten Guide aus dem internen Speicher.",
	["opt_group_data_edit"] = "Guide bearbeiten",
	["opt_group_data_edit_desc"] = "Laedt den ausgewaehlten Guide in das Editorfenster unten, um ihn direkt zu bearbeiten.",
	["opt_group_data_entry"] = "Guide-Daten:",
	["opt_group_data_entry_desc"] = "Fuege hier einen neuen Guide ein (die Schritte muessen in folgendes Format:|nguide Title Of Guide|nsteps...|nsteps...|nend\n); das Einfuegen und Parsen eines grossen Guides (>30kB) kann einige Sekunden dauern.",

	['opt_windowlocked'] = "Fenster sperren",
	['opt_windowlocked_desc'] = "Sperrt das Fenster, sodass es nicht mehr mit der Maus verschoben werden kann.\nNur Schaltflaechen bleiben aktiv.",
	['opt_hideborder'] = "Rahmen automatisch ausblenden",
	['opt_hideborder_desc'] = "Blendet Rahmen und Schaltflaechen automatisch aus, wenn die Maus nicht ueber dem Fenster ist.\nFahre kurz ueber den Fenstertitel, um sie wieder einzublenden.",

	['opt_skin'] = "Fenster-Designfarbe",
	['opt_skin_desc'] = "Waehle eine Farbe fuer die Fensterdekoration passend zur Benutzeroberflaeche.",
	['opt_skin_violet'] = "|cffee55ffViolett",
	['opt_skin_green'] = "|cff88ff88Gruen",
	['opt_skin_blue'] = "|cff99aaffBlau",
	['opt_skin_orange'] = "|cffffbb00Orangefarben",

	['opt_backopacity'] = "Hintergrund-Deckkraft",
	['opt_backopacity_desc'] = "Deckkraft des Fensterhintergrunds.",



	--["mainframe_guide"] = "Select a guide:",
	--["mainframe_notloaded"] = "No leveling guides are loaded.|n|nPlease go to http://zygorguides.com to purchase Zygor's 1-80 Leveling Guides, or load some third-party guides.|n|nIf you're sure you have installed some guides, ask their authors for installation troubleshooting.",
	--["mainframe_notselected"] = "%d guides are loaded.|nPlease select a guide from the list above.",


	["report_title"] = "Druecke Ctrl+C, um diesen Bericht zu kopieren.|nSende ihn dann an den Autor von |cffffffff%s|r,|nan |cffffffff%s|r.",
	["report_notitle"] = "|cffff8888(unbenannter Guide?)|r",
	["report_noauthor"] = "|cffff8888(keine Adresse verfuegbar)|r",


	["opt_mapbutton"] = "Minikarten-Schaltflaeche anzeigen",
	["opt_mapbutton_desc"] = "Zeigt die Schaltflaeche von Zygor Guides Viewer neben der Minikarte an",

	["minimap_tooltip"] = COLOR_TIP_MOUSE.."Klick|r zum Ein-/Ausblenden des Guide-Fensters|n"..COLOR_TIP_MOUSE.."Rechtsklick|r fuer Einstellungen|n", --..COLOR_TIP_MOUSE.."Drag|r to move icon"


	["waypointaddon_set"] = "Wegpunkt-Addon ausgewaehlt: %s",
	["waypointaddon_connecting"] = "Verbinde mit Wegpunkt-Addon: %s",
	["waypointaddon_connected"] = "Erfolgreich mit %s verbunden.",
	["waypointaddon_fail"] = "Verbindung mit %s fehlgeschlagen.",
	['waypoint_step'] = "Stufe %s",

	["checkmap"] = "Pruefe deine Karte.",

	["initialized"] = 'Initialisiert.',

	["miniframe_notloaded"] = "Keine Leveling-Guides sind geladen.|n|nBesuche http://zygorguides.com, um Zygors 1-80 Leveling Guides zu kaufen, oder lade Guides von Drittanbietern.|n|nWenn du sicher bist, dass Guides installiert sind, frage deren Autoren nach Installationshilfe.",
	["miniframe_notselected"] = "Derzeit ist kein Guide ausgewaehlt.\nKlicke auf die blinkende Schaltflaeche oben, um einen Guide auszuwaehlen.",

	['frame_locked'] = "Fenster gefixiert",
	['frame_unlock'] = COLOR_TIP_MOUSE.."Linksklick|r zum freigeben",
	['frame_unlocked'] = "Fenster frei",
	['frame_lock'] = COLOR_TIP_MOUSE.."Linksklick|r zum fixieren",
	['frame_settings'] = "Optionen",
	['frame_settings1'] = COLOR_TIP_MOUSE.."Linksklick|r fuer Menue",
	['frame_settings2'] = COLOR_TIP_MOUSE.."Rechtsklick|r für Optionen",
	['frame_minimized'] = "Zeigt |cffffffff%d|r Schritt(e)",
	['frame_maximized'] = "Zeigt alle Schritte",
	['frame_minimize'] = COLOR_TIP_MOUSE.."Linksklick|r für nur |cffffffff%d|r anzeigen",
	['frame_maximize'] = COLOR_TIP_MOUSE.."Linksklick|r für alles anzeigen",
	['frame_stepnav_prev'] = "Vorheriger Schritt",
	['frame_stepnav_prev_click'] = COLOR_TIP_MOUSE.."Linksklick|r: zurück",
	['frame_stepnav_next'] = "Naechster Schritt",
	['frame_stepnav_next_click'] = COLOR_TIP_MOUSE.."Linksklick|r: weiter",
	['frame_stepnav_next_right'] = COLOR_TIP_MOUSE.."Rechtsklick|r: vorspulen",
	['frame_section'] = "Aktueller Guide",
	['frame_section_click'] = COLOR_TIP_MOUSE.."Klick|r zum Auswaehlen",


	['tooltip_tip'] = COLOR_TIP_HINT.."%s|r",
	['tooltip_waypoint'] = COLOR_TIP_MOUSE.."Klick|r"..COLOR_TIP.." um Wegpunkt zu setzen: |cffffaa00%s|r",
	['tooltip_waypoint_coords'] = "Position: |cffffaa00%s|r",

	["message_errorloading_full"] = "|cffff4444Fehler|r beim Laden von Guide |cffaaffaa%s|r\nZeile %d: %s\nFehler: %s",
	["message_errorloading_brief"] = "|cffff4444Fehler|r beim Laden von Guide |cffaaffaa%s|r",
	["message_loadedguide"] = "Guide aktiviert: |cffaaffaa%s|r",
	["message_missingguide"] = "|cffff4444Fehlender|r Guide: |cffaaffaa%s|r",
	["title_noguide"] = "Zygor Guides Viewer (kein Guide geladen)",


	['step_num'] = "|cffaaaaaa%s|cff888888.|r ",
	['step_level'] = "|cffaaccaaStufe: |cffcceecc%s|cffaaccaa|r ",

	["questtitle"] = "`%s'",
	["questtitle_part"] = "`%s' (teil %s)",
	["coords"] = "%d,%d",
	["map_coords"] = "%s %d,%d",

	["stepgoal_home"] = "Setze dein Zuhause auf %s",
	["stepgoal_flightpath"] = "Nimm den Flugpunkt %s",

	["stepgoal_accept"] = "Nehme %s an",
	["stepgoal_turn in"] = "Gebe %s ab",
	["stepgoal_talk to"] = "Spreche mit %s",
	["stepgoal_kill"] = "Töte %s",
	["stepgoal_kill #"] = "Töte %s %s",
	["stepgoal_goal"] = "%s",
	["stepgoal_goal #"] = "%s %s",
	["stepgoal_get"] = "Besorge %s",
	["stepgoal_get #"] = "Besorge %s %s",
	["stepgoal_ding"] = "Du solltest jetzt Stufe %s sein.|n    Falls nicht, kaempfe noch etwas bis du sie erreicht hast.",
	["stepgoal_go to"] = "Gehe zum %s",
	["stepgoal_also at"] = "Also an %s",
	["stepgoal_hearth to"] = "Ruhestein nach %s",
	["stepgoal_collect"] = "Sammle %s",
	["stepgoal_collect #"] = "Sammle %s %s",
	["stepgoal_buy"] = "Kaufe %s %s",
	["stepgoal_fpath"] = "Nimm den Flugpunkt %s",
	["stepgoal_use"] = "Benutze %s",
	["stepgoal_home"] = "Mache %s zu deinem Zuhause",
	["stepgoal_petaction"] = "Benutze Tieraktion %s",
	["stepgoal_havebuff"] = "Erhalte Buff/Debuff '%s'",
	["stepgoal_nobuff"] = "Verliere Buff/Debuff '%s'",
	["stepgoal_invehicle"] = "Steige in ein Fahrzeug",
	["stepgoal_outvehicle"] = "Verlasse das Fahrzeug",
	["stepgoal_equipped"] = "Lege %s an",
	["stepgoal_at_suff"] = " (%s)",

	["completion_collect"] = "(%s/%s)",
	["completion_goal"] = "(%s/%s)",
	["completion_ding"] = "(%s%%)",
	--["completion_(done)"] = "(done)",

--[[
	["stepgoalshort_complete"] = "fertig",
	["stepgoalshort_incomplete"] = "offen",
	["stepgoalshort_questgoal"] = "(%d/%d)",
	["stepgoalshort_level"] = "(%d%%)",
--]]

	["step_req"] = "Schritt nur gueltig fuer: %s",


	["map_highlight"] = "Hervorheben",

	["stepreq"] = "Schritt Klassen-/Rassenanforderung: ",
	["stepreqor"] = " oder ",

	["opt_do_searchforgoal"] = "Erfuellbares Ziel finden",
	["searching_for_goal_success"] = "Ein erfuellbares Ziel wurde fuer dich gefunden: %s. Das kann ein guter Einstiegspunkt im Guide sein.",
	["searching_for_goal_failed"] = "Kein erfuellbares Ziel gefunden. Probiere einen anderen Guide oder Abschnitt, nimm ein paar Quests an oder starte die Suche vom Abschnittsbeginn (die Suche geht nur vorwaerts).",

	["going"] = "%d%% bis %s",
	["miniframe_loading"] = "Lade Guides: %d%%",
	["menu_last"] = "Zuletzt verwendete Guides",
	["menu_last_entry"] = "%s |cffaaffaa%d|r",
	["gb_window_title"] = "Guide Browser",
	["gb_addon_title"] = "Zygor Guides Viewer Remastered",
	["gb_root"] = "Root",
	["gb_search"] = "Search",
	["gb_folders"] = "Folders",
	["gb_guides"] = "Guides",
	["gb_load_guide"] = "Load Guide",
	["gb_open_legacy"] = "Open Legacy Picker",
	["gb_path_format"] = "Path: %s",
	["gb_select_guide"] = "Select a guide",
	["gb_select_guide_from_list"] = "Waehle einen Guide aus der Liste.",
	["gb_select_settings_page"] = "Waehle eine Einstellungsseite",
	["gb_all_guides"] = "Alle Guides",
	["gb_other"] = "Andere",
	["gb_unknown"] = "unbekannt",
	["gb_none"] = "keine",
	["gb_folder_format"] = "Ordner: %s",
	["gb_progress_format"] = "Fortschritt: %d%%",
	["gb_guides_count_format"] = "%d Guides",
	["gb_current_meta_format"] = "Step %d / %d  |  %s",
	["gb_detail_meta_format"] = "Steps: %d\nAuthor: %s\nNext: %s",
	["gb_tab_home"] = "Start",
	["gb_tab_featured"] = "Empfohlen",
	["gb_tab_current"] = "Aktuell",
	["gb_tab_recent"] = "Zuletzt",
	["gb_tab_options"] = "Optionen",
	["gb_cat_leveling"] = "Leveling",
	["gb_cat_dungeons"] = "Dungeons",
	["gb_cat_daily"] = "Daily",
	["gb_cat_events"] = "Events",
	["gb_cat_reputations"] = "Reputations",
	["gb_cat_gold"] = "Gold",
	["gb_cat_professions"] = "Professions",
	["gb_cat_petsmounts"] = "Pets & Mounts",
	["gb_cat_titles"] = "Titles",
	["gb_cat_achievements"] = "Achievements",
	["gb_cat_misc"] = "Misc",
	["gb_cat_favorites"] = "Favorites",
	["gb_opt_guides"] = "Guides",
	["gb_opt_desc_guides"] = "Guide-Auswahl, Daten des aktiven Guides und grundlegende Guide-Steuerung.",
	["gb_opt_stepdisplay"] = "Schrittanzeige",
	["gb_opt_desc_stepdisplay"] = "Viewer-Optik, Fensterlayout, Skin/Schriften und Anzeige von Schritten und Zielen.",
	["gb_opt_progress"] = "Fortschritt",
	["gb_opt_desc_progress"] = "Schrittfortschritt, Ueberspringregeln und Abschlussverhalten.",
	["gb_opt_travel"] = "Reisesystem",
	["gb_opt_desc_travel"] = "Wegpunkt-Anbieter und Verhalten des Reisesystems.",
	["gb_opt_map"] = "Karten & Wegpunkte",
	["gb_opt_desc_map"] = "Pfeilstil, Minimap-/Kartenmarker und Wegpunkt-Optik.",
	["gb_opt_notifications"] = "Benachrichtigungen",
	["gb_opt_desc_notifications"] = "Hinweise fuer Fortschritt und Abschluss.",
	["gb_opt_actionbuttons"] = "Aktionsschaltflaechen",
	["gb_opt_desc_actionbuttons"] = "Verhalten klickbarer Schritt-/Zielanzeigen.",
	["gb_opt_convenience"] = "Questing",
	["gb_opt_desc_convenience"] = "Automatisches Annehmen/Abgeben und Komfortfunktionen.",
	["gb_opt_accessibility"] = "Barrierefreiheit",
	["gb_opt_desc_accessibility"] = "Optionen fuer Farbensichtbarkeit und bessere Lesbarkeit.",
	["gb_opt_profile"] = "Profile",
	["gb_opt_desc_profile"] = "Profilverwaltung pro Charakter/global sowie Kopier-/Reset-Werkzeuge.",
	["gb_opt_about"] = "Info",
	["gb_opt_desc_about"] = "Version, Support und Diagnose-/Fehlerberichtswerkzeuge.",
	["gb_opt_advanced"] = "Erweitert",
	["gb_opt_desc_advanced"] = "Debug-Werkzeuge, Diagnose und entwicklernahe Steuerungen.",
	["gb_opt_general"] = "Allgemein",
	["gb_opt_desc_general"] = "Allgemeine Einstellungen.",
	["gb_title_viewer"] = "Viewer",
	["gb_options_viewer_desc"] = "Grundverhalten des Viewers, Guide-Laden und Basissteuerung des Addons.",
	["gb_hint_search_settings"] = "Tipp:\nNutze links die Suche, um schnell eine Einstellungsseite zu finden.",
	["gb_hint_options_filter"] = "Tipp:\nDie Suche links filtert Einstellungsseiten.\nNutze 'Vollstaendige Optionen oeffnen' fuer die Blizzard-Ansicht.",
	["gb_empty_no_guides_search"] = "Keine Guides passen zu dieser Suche.",
	["gb_empty_no_guides_category"] = "Keine Guides in dieser Kategorie.",
	["gb_empty_no_current_guide"] = "Kein aktueller Guide geladen.",
	["gb_empty_no_current_guide_short"] = "Kein aktueller Guide geladen",
	["gb_empty_no_recent_guides"] = "Noch keine kuerzlich genutzten Guides.",
	["gb_empty_no_featured_match"] = "Keine empfohlenen Vorschlaege passen zu diesem Filter.",
	["gb_empty_no_featured_suggestions"] = "Keine empfohlenen Vorschlaege",
	["gb_empty_no_favorites"] = "Noch keine Favoriten-Guides.",
	["gb_no_guide_selected"] = "Kein Guide ausgewaehlt",
	["gb_action_clear_search"] = "Clear search",
	["gb_action_show_all_categories"] = "Show all categories",
	["gb_action_go_home"] = "Go to Home",
	["gb_action_open_home"] = "Open Home",
	["gb_action_reset_snoozed"] = "Reset snoozed suggestions",
	["gb_action_clear_search_restore"] = "Clear search to restore suggestions",
	["gb_action_reset_snoozed_restore"] = "Reset snoozed suggestions to restore recommendations",
	["gb_action_try_home"] = "Try Home to browse all categories",
	["gb_action_browse_all_from_home"] = "Browse all guides from Home",
	["gb_action_back_to_guides"] = "Back to Guides",
	["gb_action_open_full_options"] = "Open Full Options",
	["gb_action_go_current_folder"] = "Go to Current Guide Folder",
	["gb_action_resume"] = "Resume",
	["gb_action_restart"] = "Restart",
	["gb_nav_navigation"] = "Navigation",
	["gb_nav_back"] = "Back",
	["gb_nav_reset_to_root"] = "Reset to Category Root",
	["gb_featured_bucket_next"] = "Next Up",
	["gb_featured_bucket_progress"] = "In Progress",
	["gb_featured_bucket_level"] = "Around Your Level",
	["gb_featured_bucket_featured"] = "Featured Routes",
	["gb_featured_confidence_strong"] = "Strong",
	["gb_featured_confidence_good"] = "Good",
	["gb_featured_confidence_fallback"] = "Fallback",
	["gb_roadmap"] = "Roadmap",
	["gb_roadmap_bucket_format"] = "%s Roadmap",
	["gb_bucket_preview_next_with_title"] = "Continue your chain: %s",
	["gb_bucket_preview_next"] = "Continue your chain",
	["gb_bucket_preview_progress_with_title"] = "Resume: %s",
	["gb_bucket_preview_progress"] = "Resume in-progress guides",
	["gb_bucket_preview_level_with_title"] = "Start level-fit: %s",
	["gb_bucket_preview_level"] = "Start level-fit guides",
	["gb_bucket_preview_featured_with_title"] = "Optional route: %s",
	["gb_bucket_preview_featured"] = "Optional routes and extras",
	["gb_meta_action"] = "Action",
	["gb_meta_suggestion"] = "Suggestion",
	["gb_meta_suggested"] = "Suggested",
	["gb_meta_current"] = "Current",
	["gb_meta_recommended"] = "recommended",
	["gb_meta_other_useful_option"] = "other useful option",
	["gb_meta_current_selection"] = "current selection",
	["gb_meta_suggestions_snoozed"] = "suggestions may be snoozed",
	["gb_meta_restore_recommendations"] = "restore recommendations",
	["gb_meta_filter_no_matches"] = "filter has no matches",
	["gb_meta_see_full_recommendations"] = "see full recommendations",
	["gb_meta_no_bucket_suggestions"] = "no suggestions in this bucket",
	["gb_meta_full_category_access"] = "full category access",
	["gb_meta_suggested_from"] = "Suggested from: %s",
	["gb_meta_confidence"] = "Confidence: %s",
	["gb_meta_why_prefix"] = "Why: ",
	["gb_meta_gain_prefix"] = "Gain: ",
	["gb_reason_recently_used"] = "recently used",
	["gb_reason_incomplete"] = "incomplete",
	["gb_reason_your_level_range"] = "your level range",
	["gb_reason_near_your_level"] = "near your level",
	["gb_reason_your_class"] = "your class",
	["gb_reason_your_race"] = "your race",
	["gb_reason_your_profession"] = "your profession",
	["gb_reason_favorite"] = "favorite",
	["gb_reason_current_chain"] = "current chain",
	["gb_reason_chain_step_format"] = "chain step +%d",
	["gb_reason_inferred_continuation"] = "inferred continuation",
	["gb_reason_chapter_continuation"] = "chapter continuation",
	["gb_tooltip_featured_controls"] = "Featured suggestion controls",
	["gb_tooltip_featured_click"] = "Click the X: snooze for 24 hours",
	["gb_tooltip_featured_shift_click"] = "Shift-click X: hide for this session",
	["gb_tooltip_featured_restore"] = "Press R or use reset in options to restore.",
	["gb_tooltip_snooze"] = "Snooze suggestion",
	["gb_tooltip_snooze_click"] = "Click: hide for 24 hours",
	["gb_tooltip_snooze_shift_click"] = "Shift-click: hide for this session",
	["gb_tooltip_why_prefix"] = "Why: ",
	["gb_tooltip_gain_prefix"] = "Gain: ",
	["gb_tooltip_confidence_prefix"] = "Confidence: ",
	["gb_tooltip_chain_prefix"] = "Chain: ",
	["gb_tooltip_fallback_recommendation"] = "Fallback recommendation",
	["gb_current_guide"] = "Aktueller Guide",
	["gb_options_fallback_embed_unavailable"] = "Eingebettete Optionen nicht verfuegbar. Klicke erneut auf Optionen, um die Blizzard-Interfaceoptionen zu oeffnen.",
	["gb_options_fallback_missing_widgets"] = "Eingebettete Optionen nicht verfuegbar. AceGUI-Einbettungswidgets fehlen.",
	["gb_options_fallback_render_error"] = "Eingebettete Optionen konnten nicht dargestellt werden: %s",
	["opt_legacyguideddropdown"] = "Klassisches Guide-Dropdown",
	["opt_featured_header"] = "Empfohlene Vorschlaege",
	["opt_featured_enablefallback"] = "Ersatzvorschlaege aktivieren",
	["opt_featured_enablefallback_desc"] = "Wenn ein Empfehlungsbereich keine direkten Treffer hat, einige nuetzliche Ersatz-Guides anzeigen.",
	["opt_featured_hiderecentcompleted"] = "Kuerzlich abgeschlossene Guides ausblenden",
	["opt_featured_hiderecentcompleted_desc"] = "Ganz frisch abgeschlossene Guides aus intelligenten Empfehlungen ausblenden.",
	["opt_featured_showconfidence"] = "Sicherheitsstufen anzeigen",
	["opt_featured_showconfidence_desc"] = "Strong/Good/Fallback-Markierungen in empfohlenen Zeilen anzeigen.",
	["opt_featured_resethidden"] = "Ausgeblendete Vorschlaege zuruecksetzen",
	["opt_featured_resethidden_desc"] = "Alle mit dem Schliessen-Button ausgeblendeten Vorschlaege wiederherstellen.",
	["opt_disablerouteloopstacking"] = "Routen-/Schleifen-Stapelung deaktivieren",
	["opt_disablerouteloopstacking_desc"] = "Verhindert, dass Routen und Schleifen im gleichen Empfehlungsbereich gestapelt werden.",
	["opt_accessibility_intro"] = "Passe Optionen fuer Farbensichtbarkeit und Textlesbarkeit an.",
	["opt_colorblindmode"] = "Farbenblind-Modus",
	["opt_colorblindmode_desc"] = "Ersetzt Guide-, Pfeil- und Distanzfarben durch farbenblindfreundliche Paletten und erzwingt kontrastreichere Pfeil-Begriffsfarben.",
	["opt_colorblindmode_off"] = "Aus",
	["opt_colorblindmode_protanopia"] = "Protanopie",
	["opt_colorblindmode_deuteranopia"] = "Deuteranopie",
	["opt_colorblindmode_tritanopia"] = "Tritanopie",
	["opt_colorblindmode_global"] = "Global",
	["opt_colorblindmode_custom"] = "Benutzerdefiniert",
	["opt_arrowcolor_far"] = "Weit",
	["opt_arrowcolor_mid"] = "Mittel",
	["opt_arrowcolor_near"] = "Nah",
	["opt_simplifyarrownouncolors"] = "Vereinfachte Pfeil-Begriffsfarben",
	["opt_simplifyarrownouncolors_desc"] = "Sauberere, kontrastreichere Farben fuer Pfeilbeschriftungen verwenden.",
	["opt_about_heading"] = "Zygor Guides Viewer Remastered fuer WoTLK 3.3.5a",
	["opt_about_support"] = "Support",
	["opt_about_diag"] = "Tipp: `/zygor status` und `/zygor debug` helfen bei der Fehlersuche.",
	["opt_showminimapicons"] = "Minimap-Symbole anzeigen",
	["opt_showminimapicons_desc"] = "Symbole auf der Minimap anzeigen",
	["opt_iconalpha"] = "Symbol-Alpha",
	["opt_iconalpha_desc"] = "Transparenz der Kartennotiz-Symbole",
	["opt_iconsize"] = "Symbolgroesse",
	["opt_iconsize_desc"] = "Groesse der Symbole auf der Karte",
	["opt_arrowshow"] = "Pfeil anzeigen",
	["opt_arrowshow_desc"] = "Den internen Wegpunkt-Pfeil anzeigen oder ausblenden.",
	["opt_arrowcolormode_direction"] = "Richtung",
	["opt_arrowcolormode_distance"] = "Distanz",
	["opt_arrowtextoutline"] = "Pfeiltext-Kontur",
	["opt_arrowtextoutline_desc"] = "Konturstaerke fuer den Wegpunkt-Pfeiltext waehlen.",
	["opt_arrowtextoutline_default"] = "Standard",
	["opt_arrowtextoutline_strong"] = "Stark",
	["opt_arrowtextoutline_reduced"] = "Reduziert",
	["opt_remasterpointeronlegacy"] = "Remastered-Zeiger auf Legacy-Skins nutzen",
	["opt_remasterpointeronlegacy_desc"] = "Wenn aktiviert, verwenden Legacy-Skins den remasterten Wegpunkt-Pfeil.",
	["opt_resetarrowposition"] = "Pfeilposition zuruecksetzen",
	["opt_resetarrowposition_desc"] = "Setzt den Wegpunkt-Pfeil auf die Standardposition zurueck.",
	["opt_foglightdebug"] = "(Debug) Foglight pruefen",
	["opt_foglightdebug_desc"] = "Foglight fuer die aktuelle Karte pruefen",
	["opt_travelsystem_intro"] = "Waehle, wie Reise- und Wegpunkt-Anbieter behandelt werden.",
	["opt_mapswaypoints_intro"] = "Konfiguriere Kartenmarker und die Optik des internen Pfeils.",
	["opt_notifications_intro"] = "Konfiguriere visuelle Benachrichtigungshinweise waehrend des Fortschritts.",
	["opt_actionbuttons_intro"] = "Konfiguriere Zielsymbole und die Darstellung interaktiver Schritte.",
	["opt_actionbar_enable"] = "Enable Action Bar",
	["opt_actionbar_enable_desc"] = "Show a movable action bar for the current step's actionable goals.",
	["opt_actionbar_onlywhenneeded"] = "Show Only When Needed",
	["opt_actionbar_onlywhenneeded_desc"] = "Hide the action bar when the current step has no actionable buttons.",
	["opt_actionbar_locked"] = "Lock Action Bar Position",
	["opt_actionbar_locked_desc"] = "Prevent the action bar from being dragged.",
	["opt_actionbar_scale"] = "Action Bar Scale",
	["opt_actionbar_scale_desc"] = "Scale of the action bar.",
	["opt_actionbar_size"] = "Button Size",
	["opt_actionbar_size_desc"] = "Size of each action bar button.",
	["opt_actionbar_spacing"] = "Button Spacing",
	["opt_actionbar_spacing_desc"] = "Spacing between action bar buttons.",
	["opt_actionbar_pinside"] = "Pinned Side",
	["opt_actionbar_pinside_desc"] = "Choose which side of the viewer the snapped action bar should attach to.",
	["opt_actionbar_pinside_top"] = "Top",
	["opt_actionbar_pinside_bottom"] = "Bottom",
	["opt_actionbar_pinside_left"] = "Left",
	["opt_actionbar_pinside_right"] = "Right",
	["opt_actionbar_resetanchor"] = "Reset Action Bar Position",
	["opt_actionbar_resetanchor_desc"] = "Reset the action bar to its default snapped position.",
	["opt_actionbar_markers"] = "Enable Target Markers",
	["opt_actionbar_markers_desc"] = "Attempt to place raid target markers on talk and kill targets when possible.",
	["opt_targetpreview_header"] = "Target Preview",
	["opt_targetpreview_intro"] = "Show a movable preview pane for the current talk or kill target.",
	["opt_targetpreview_enable"] = "Enable Target Preview",
	["opt_targetpreview_enable_desc"] = "Show a movable preview pane for the current step's talk and kill targets.",
	["opt_targetpreview_onlywhenneeded"] = "Show Only When Relevant",
	["opt_targetpreview_onlywhenneeded_desc"] = "Hide the preview pane when the current step has no talk or kill target to preview.",
	["opt_targetpreview_locked"] = "Lock Preview Position",
	["opt_targetpreview_locked_desc"] = "Prevent the target preview pane from being dragged.",
	["opt_targetpreview_scale"] = "Preview Scale",
	["opt_targetpreview_scale_desc"] = "Scale of the target preview pane.",
	["opt_targetpreview_width"] = "Preview Width",
	["opt_targetpreview_width_desc"] = "Width of the target preview pane.",
	["opt_targetpreview_height"] = "Preview Height",
	["opt_targetpreview_height_desc"] = "Height of the target preview pane.",
	["opt_targetpreview_pinside"] = "Pinned Side",
	["opt_targetpreview_pinside_desc"] = "Choose which side of the viewer the snapped target preview should attach to.",
	["opt_targetpreview_mode"] = "Preview Mode",
	["opt_targetpreview_mode_desc"] = "Choose whether the preview prefers a live 3D model, a styled info card, or both.",
	["opt_targetpreview_mode_hybrid"] = "Hybrid",
	["opt_targetpreview_mode_model"] = "3D Only",
	["opt_targetpreview_mode_card"] = "Info Card Only",
	["opt_targetpreview_resetanchor"] = "Reset Target Preview Position",
	["opt_targetpreview_resetanchor_desc"] = "Reset the target preview pane to its default snapped position.",
	["targetpreview_title"] = "Drag to move Target Preview",
	["targetpreview_title_locked"] = "Target Preview",
	["targetpreview_role_talk"] = "Talk to",
	["targetpreview_role_kill"] = "Kill",
	["targetpreview_hint"] = "Target this creature to preview its 3D model.",
	["targetpreview_hint_empty"] = "No talk or kill target is active on this step.",
	["targetpreview_empty_name"] = "No Target",
	["actionbutton_bar_title"] = "Drag to move Action Buttons",
	["actionbutton_bar_title_locked"] = "Action Buttons",
	["actionbutton_tooltip_talk"] = "Target %s and try to mark it with a green triangle.",
	["actionbutton_tooltip_kill"] = "Target %s and try to mark it with a skull.",
	["actionbutton_tooltip_script"] = "Run the current step script macro.",
	["actionbutton_tooltip_petaction"] = "Use the suggested pet action.",
	["frame_toolbar_guides"] = "Guides",
	["frame_toolbar_guides_click"] = "zum Oeffnen des Guide-Menues",
	["frame_toolbar_guides_right"] = "zum Oeffnen des Guide-Managers",
	["frame_toolbar_close"] = "Schliessen",
	["frame_toolbar_close_click"] = "zum Schliessen",
	["frame_toolbar_settings"] = "Optionen",
	["frame_toolbar_settings_click"] = "fuer das Schnellmenue",
	["frame_toolbar_settings_right"] = "zum Oeffnen der Guide-Manager-Optionen",
	["frame_toolbar_stepview"] = "Schrittansicht",
	["frame_toolbar_stepview_showall"] = "um alle anzuzeigen",
	["frame_toolbar_stepview_showonly"] = "um nur |cffffffff%s|r anzuzeigen",
	["frame_toolbar_stepview_setcount"] = "um die Schrittzahl festzulegen",
	["frame_toolbar_unlock"] = "Fenster entsperren",
	["frame_toolbar_unlock_click"] = "zum Entsperren",
	["frame_toolbar_lock"] = "Fenster sperren",
	["frame_toolbar_lock_click"] = "zum Sperren",
	["frame_title_default"] = "Zygor Guides",
	["frame_tab_guides"] = "Guides",
	["frame_tab_spots"] = "Spots",

	["completion_done"] = "(fertig)",
	["completion_rep"] = "(%s)",

	["req_not"] = "nicht %s",

	["stepgoal_rep"] = "Werde %s bei %s",
	["stepgoal_achieve"] = "Erhalte Erfolg '%s'",
	["stepgoal_achievesub"] = "Schliesse '%s' fuer den Erfolg '%s' ab",
	["stepgoal_skill"] = "Lerne %s bis Stufe %s",
	["stepgoal_skillmax"] = "Steigere %s auf die maximale Stufe %s",
	["stepgoal_learn"] = "Lerne, %s herzustellen",
	["stepgoal_or"] = "  - oder -",

	["binding_prev"] = "Vorheriger Schritt",
	["binding_next"] = "Naechster Schritt",
	["binding_actionbutton1"] = "Action Button 1",
	["binding_actionbutton2"] = "Action Button 2",
	["binding_actionbutton3"] = "Action Button 3",
	["binding_actionbutton4"] = "Action Button 4",
	["binding_actionbutton5"] = "Action Button 5",

	["waypointaddon_detecting"] = "Versuche, Wegpunkt-Addon automatisch zu erkennen...",
	["waypointaddon_disconnected"] = "Verbindung zu |cffddeeff%s|r getrennt.",
	["pointer_corpselabel1"] = "Ex-du",
	["pointer_corpselabel2"] = "Wer wegrennt, lebt laenger...",
	["pointer_corpselabel3"] = "Da war wohl ein Gegner zu viel.",
	["pointer_corpselabel4"] = "Eimer-Treter - hier entlang",
	["pointer_corpselabel5"] = "Denk lieber nicht an die Reparaturkosten.",

	["opt_group_map_hidearrowwithguide"] = "Pfeil beim Schliessen des Viewers ausblenden",
	["opt_group_map_hidearrowwithguide_desc"] = "Aktiviere dies, damit der Pfeil der Sichtbarkeit des Guide-Fensters folgt.\nDeaktiviert lassen, wenn der Pfeil sichtbar bleiben soll, wenn du Guides ausblendest.",
	["opt_group_addons_internal"] = "Integrierte Wegpunkte",
	["opt_group_addons_carbonite"] = "Carbonite (Addon)",
	["opt_stepnumber"] = "Schrittnummern anzeigen",
	["opt_stepnumber_desc"] = "Zeige Schrittnummern und empfohlene Stufen fuer jeden Schritt an.\nDeaktiviere dies, um Bildschirmplatz zu sparen.",
	["opt_hidestepborders"] = "Rahmen ausblenden",
	["opt_hidestepborders_desc"] = "Blendet die grafischen Rahmen um Schritte aus.",
	["opt_stepbackopacity"] = "Hintergrund-Deckkraft",
	["opt_stepbackopacity_desc"] = "Deckkraft des Schrittfenster-Hintergrunds.\nDie Hintergrundfarbe richtet sich nach dem Fortschritt und wird abgedunkelt.",
	["opt_goalbackprogressing"] = "Mitte",
	["opt_goalbackprogressing_desc"] = "Diese Farbe markiert Ziele bei 50% Fortschritt.",
	["opt_progressbackcolor_desc"] = "Schrittfarben:",
	["opt_goalbackaux"] = "Reise",
	["opt_goalbackaux_desc"] = "Diese Farbe fuer Reiseschritte verwenden.",
	["opt_goalbackobsolete"] = "Veraltet",
	["opt_goalbackobsolete_desc"] = "Diese Farbe fuer veraltete Ziele oder Schritte verwenden.",
	["opt_resetwindow"] = "Fenster zuruecksetzen",
	["opt_resetwindow_desc"] = "Wenn das Fenster ausserhalb des Bildschirms liegt, setzt diese Schaltflaeche es zurueck in die Mitte.",
	["opt_trackchains"] = "Questketten verfolgen",
	["opt_trackchains_desc"] = "Markiert Quest-Annahme-Schritte als nicht verfuegbar, wenn eine vorherige Quest nicht abgeschlossen wurde.\n\nDie Questketten-Datenbank enthaelt auch \"lockere Ketten\"; dadurch kann eine Questannahme manchmal als nicht verfuegbar erscheinen, obwohl sie angenommen werden kann.",
	["opt_guidesinhistory"] = "Anzahl zuletzt genutzter Guides",
	["opt_guidesinhistory_desc"] = "Zeigt diese Anzahl kuerzlich genutzter Guides an.",
	["opt_skin_remaster"] = "|cffc7d9ffRemaster (Standard)",
	["opt_group_progress"] = "Dynamischer Fortschritt",
	["opt_group_progress_desc"] = "Zur Optimierung des Levelns kann dieses Addon Quests dynamisch ueberspringen, die dir auf deiner Stufe wenig bringen.",
	["opt_levelsahead"] = "Stufen voraus erlauben",
	["opt_levelsahead_desc"] = "Diese Einstellung steuert, wie weit du dem Guide voraus sein willst.\nMit 0 werden Quests unterhalb deiner Stufe normalerweise uebersprungen (wenn sie keine Folgequests haben).\nMit 1 oder mehr werden nur Quests uebersprungen, die mehr als diese Anzahl Stufen unter dir liegen.",
	["opt_showobsolete"] = "Veraltete Schritte markieren",
	["opt_showobsolete_desc"] = "Markiert veraltete Schritte mit grauem Hintergrund.\nSchritte gelten als veraltet, wenn sie fuer deine Stufe zu niedrig sind.",
	["opt_skipobsolete"] = "Veraltete Schritte ueberspringen",
	["opt_skipobsolete_desc"] = "Ueberspringt veraltete Schritte automatisch.",
	["opt_skipauxsteps"] = "Reiseschritte ueberspringen",
	["opt_skipauxsteps_desc"] = "Ueberspringt Reiseschritte automatisch, wenn danach bereits abgeschlossene oder veraltete Schritte folgen.\nDamit wird vermieden, dass du weit reist und danach ein bereits erledigter Annahmeschritt folgt.",
	["opt_skipflightsteps"] = "Flugrouten als bekannt annehmen",
	["opt_skipflightsteps_desc"] = "Nimmt an, dass du Flugrouten selbst verwaltest, und markiert Flugrouten-Schritte automatisch als abgeschlossen.\n\nBesonders nuetzlich beim Einstieg in spaetere Guide-Abschnitte.",
	["opt_skipimpossible"] = "Unmoegliche Schritte ueberspringen",
	["opt_skipimpossible_desc"] = "Ueberspringt unmoegliche Schritte automatisch, falls du absichtlich ausgelassene Questziele nicht angezeigt bekommen moechtest.",
	["opt_group_progress_bottomdesc"] = "Dynamischer Fortschritt markiert Quests als \"veraltet\", wenn du den im Guide erwarteten Stufenbereich um mehr als den oben definierten Wert ueberschreitest. Questketten werden nur dann als veraltet markiert, wenn die gesamte Kette veraltet ist.\n\nFuer neue Spieler hilft dies, indem Inhalte niedriger Stufe intelligent uebersprungen werden und nur sinnvolle Questketten uebrig bleiben. Wenn du einen guten Startpunkt suchst, lade den Startguide deiner Rasse und lasse den Viewer passende Bereiche automatisch finden.\n\nFuer erfahrene Spieler verhindert dies, dass der Guide mit zu niedrigen Quests bremst, falls du schneller levelst als erwartet (zum Beispiel durch Instanzen oder Ruhend-Bonus). Du kannst festlegen, wie weit du voraus sein darfst, bevor der Guide dich durch Ueberspringen nach vorne schiebt.",
	["opt_group_mapinternal"] = "Interne Wegpunkte",
	["opt_arrowmeters"] = "Metrisches System",
	["opt_arrowmeters_desc"] = "Verwendet Meter und Kilometer statt Yards und Meilen.",
	["opt_arrowfreeze"] = "Pfeil ignoriert Klicks",
	["opt_arrowfreeze_desc"] = "Laesst den Pfeil Mausklicks ignorieren. Deaktivieren, um ihn verschieben zu koennen.",
	["opt_arrowcam"] = "Pfeil folgt Kamera",
	["opt_arrowcam_desc"] = "Zeigt Richtungen relativ zur Kameraausrichtung. Ist dies aus, orientiert sich der Pfeil an der Blickrichtung deines Charakters.\n\nHinweis: Im Kameramodus kann der Pfeil bei Click-to-Move ungenau wirken.",
	["opt_arrowcolordir"] = "Farbe nach Richtung",
	["opt_arrowcolordir_desc"] = "Faerbt den Pfeil-Edelstein gruen, wenn er in die richtige Richtung zeigt.\n\nDeaktivieren, wenn Gruen nur bei Naehe zum Ziel erscheinen soll.",
	["opt_arrowscale"] = "Pfeil-Skalierung",
	["opt_arrowscale_desc"] = "Groesse des Pfeils.",
	["opt_arrowfontsize"] = "Pfeil-Schriftgroesse",
	["opt_arrowfontsize_desc"] = "Schriftgroesse im Pfeil-Fenster.",
	["opt_minimapzoom"] = "Automatisch zoomen",
	["opt_minimapzoom_desc"] = "Erhoeht den Minikarten-Zoom automatisch, wenn ein Wegpunkt gesetzt wird, und stellt ihn danach wieder her.",
	["opt_foglight"] = "Leuchtspur anzeigen",
	["opt_foglight_desc"] = "Erzeugt einen glitzernden Pfad zum Ziel auf Weltkarte und Minikarte.",
	["opt_group_gold"] = "Gold-Guide",
	["opt_group_gold_desc"] = "Diese Einstellungen steuern die Anzeige von Goldfarming-Schritten und Ressourcenknoten.",
	["opt_gold_detectiondist"] = "Erkennungsreichweite",
	["opt_gold_detectiondist_desc"] = "Entfernung, in der naheliegende Gold-Guide-Spots erkannt und beruecksichtigt werden.",
	["opt_gold_reqmode"] = "Anforderungsmodus",
	["opt_gold_reqmode_desc"] = "Legt fest, welche Spot-Typen beruecksichtigt werden sollen.",
	["opt_gold_reqmode_all"] = "Alle",
	["opt_gold_reqmode_current"] = "Nur aktueller Guide",
	["opt_gold_reqmode_future"] = "Aktueller + zukuenftige Guides",
	["gold_missing_noguidesloaded"] = "Keine Gold-Guides geladen.",
	["gold_missing_nospotsinrange"] = "Keine passenden Gold-Spots in Reichweite gefunden.",
	["gold_header_ore"] = "Erzvorkommen:",
	["gold_header_herb"] = "Kraeuter:",
	["gold_header_skin"] = "Haeute:",
	["gold_header_drop"] = "Beute von |cffffdddd%s|r:",
	["opt_group_convenience"] = "Zusatzfunktionen",
	["opt_group_convenience_desc"] = "Verschiedene Funktionen, die nuetzlich sein koennen.",
	["opt_autoaccept"] = "Quests automatisch annehmen",
	["opt_autoaccept_desc"] = "Nimmt angebotene Quests automatisch an.",
	["opt_autoturnin"] = "Quests automatisch abgeben",
	["opt_autoturnin_desc"] = "Gibt abgeschlossene Quests automatisch ab.",
	["opt_fixblizzardautoaccept"] = "Blizzard-Auto-Annahme reparieren",
	["opt_fixblizzardautoaccept_desc"] = "Aktiviert bei aktivierter Blizzard-Option \"Quest automatisch annehmen\" dennoch die Schritte \"Nehme\" und \"Angenommen\" als abgeschlossen.",
	["opt_audiocues"] = "Audiohinweise",
	["opt_audiocues_desc"] = "Spielt Toene bei Schrittfortschritt ab.",
	["opt_analyzereps"] = "Ruf analysieren",
	["opt_analyzereps_desc"] = "Wertet deinen aktuellen Rufstand aus und markiert unpassende Rufschritte als veraltet.",
	["opt_mapcoords"] = "Kartenkoordinaten anzeigen",
	["opt_mapcoords_desc"] = "Zeigt Maus- und Spielerkoordinaten in Kartenfenstern an.",

	["haman$"] = "hamans",
	["(%a)man$"] = "%1men",

	["binding_togglewindow"] = "Guide-Fenster anzeigen",

} end)



local plurals = {
}

ZygorGuidesViewer_L("Specials", "deDE", function() return {
	["plural"] = function (word)
		return word
		--[[
		local rest=""
		local preof,postof = word:match("(.-) der (.+)")
		if preof then
			word=preof
			rest=" der "..postof
		end
		local last = word:sub(-1)
		return word..rest
		]]
	end,
	['contract_mobs'] = false,
	['contract_mobs_old'] = function(mobs)
			local start,ending

			if not mobs[1].name and type(mobs)=="table" then
				local l=mobs
				mobs={}
				for i=1,#l do mobs[i]={name=l[i]} end
			end
			local common,all
			for i=1,50 do
				common = mobs[1].name:sub(1,i)
				all=true
				for m=2,#mobs do
					if mobs[m].name:find(common)~=1 then
						all=false
						break
					end
				end
				if not all then
					common = common:sub(1,-2)
					break
				end
			end
			if common:sub(-1)==" " then common = common:sub(1,-2) end
			start=common

			-- start failed? let's try end.
			for i=1,50 do
				common = mobs[1].name:sub(-i)
				all=true
				for m=2,#mobs do
					if mobs[m].name:sub(-i)~=common then
						all=false
						break
					end
				end
				if not all then
					common = common:sub(2)
					break
				end
			end
			if common:sub(1,1)==" " then common = common:sub(2) end
			ending=common

			if #start>#ending and #start>3 then
				return ZygorGuidesViewer_L("Specials")['contract_mobs_start'](start)
			elseif #ending>#start and #ending>3 then
				return ZygorGuidesViewer_L("Specials")['contract_mobs_end'](ending)
			else
				return nil
			end
		end,
	['contract_mobs_start'] = function(s) return ZygorGuidesViewer_L("Specials")['plural'](s) end,
	['contract_mobs_end'] = function(s)
		local pre=s:sub(1,4)
		if pre=="der " or pre=="das " or pre=="die " then
			return "Mobs "..s
		else
			return ZygorGuidesViewer_L("Specials")['plural'](s)
		end
	end,
} end)



-- Add lines for any translations needed for:

-- MISC STRINGS

ZygorGuidesViewer_L("G_string", "deDE", function() return {
--	["blabla"] = TRUE,
} end)

