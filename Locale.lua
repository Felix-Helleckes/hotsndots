--=====================================================================
--  HotsNDots - Locale
--  English, German, French, Spanish, Italian, Portuguese, Russian,
--  Korean, Simplified and Traditional Chinese. The client's own language decides;
--  there is no setting, because there is nothing to choose: WoW already
--  knows what language the player reads.
--
--  Three rules:
--
--  * ENGLISH IS THE BASE. Every key exists in `EN`, and every other
--    language is an overlay on top of it. A missing or empty translation
--    therefore falls back to English instead of nil - and nil is not a
--    blank here, it is an error: every one of these strings ends up in a
--    concatenation or in format().
--  * PLACEHOLDERS ARE PART OF THE STRING. A translation that drops a %s
--    does not look wrong, it throws inside format() - at the moment the
--    message was supposed to explain something. test/locale_test.py
--    compares the placeholders of every translation against English.
--  * "Default" IS NOT A WORD, it is the name of a profile and a key in
--    the saved variables. It must read the same in every language, or a
--    German client stops finding the profile a French one wrote. Same
--    reason the preset KEYS stay English while their labels do not.
--
--  Deliberately NOT translated: the output of /hnd debug. It is a bug
--  report meant to be pasted to someone who has to read it, and a report
--  in a language the reader does not speak is worth less than no report.
--=====================================================================

local ADDON_NAME, ns = ...

local EN = {
    -- ---------------- shared ----------------
    tagline          = "Shows only your own DoTs (on enemies) and HoTs/buffs (on friends) on nameplates and as movable bars.",
    editingProfile   = "Editing profile: %s",
    profilesTabHint  = "(see the Profiles entry under HotsNDots)",

    -- ---------------- nameplate icons ----------------
    hdrNameplates    = "Nameplate icons",
    cbNameplates     = "Show nameplate icons",
    cbBelow          = "Show below the nameplate",
    cbStacks         = "Show stacks (only real stacks, 2+)",
    cbSwipe          = "Show cooldown swipe",
    slIconSize       = "Icon size",
    slSecondsFont    = "Seconds font size",
    slDistance       = "Distance from nameplate",
    slMaxIcons       = "Max icons",

    -- ---------------- bars ----------------
    hdrBars          = "Bars (movable)",
    cbBars           = "Show bars",
    cbLock           = "Lock bars (not movable)",
    cbGrowUp         = "Grow upwards",
    slBarWidth       = "Bar width",
    slBarHeight      = "Bar height",
    slMaxBars        = "Max bars",
    barAnchorLabel   = "HotsNDots \226\128\148 drag to move",

    -- ---------------- filters ----------------
    hdrFilters       = "Filters",
    cbShowDebuffs    = "Show debuffs (your DoTs on enemies)",
    cbShowBuffs      = "Show buffs (your HoTs on friends)",
    cbHidePermBuffs  = "Hide buffs without a timer",
    cbHidePermDebuffs= "Hide debuffs without a timer",
    cbHideCC         = "Hide crowd control",

    -- ---------------- general ----------------
    hdrGeneral       = "General",
    cbMinimap        = "Show minimap button (not per profile)",

    -- ---------------- profiles page ----------------
    pageProfiles     = "Profiles",
    profilesIntro    = "A profile holds the filters, the nameplate icons, the bars and where the bar anchor sits."
                    .. " Each specialization picks its own, so changing spec changes the layout with it."
                    .. " Profiles are shared by all your characters; the minimap button is not part of them.",
    hdrPerSpec       = "Profile per specialization",
    perSpecHint      = "The spec you are in switches immediately; the others take effect when you switch to them.",
    hdrManage        = "Manage",
    charLine         = "Character: %s      Current spec: %s",
    activeProfile    = "Active profile: %s",
    btnNewProfile    = "New profile",
    btnNewFromThis   = "New from this one",
    btnCopyFrom      = "Copy from...",
    btnResetProfile  = "Reset this profile",
    btnDelete        = "Delete...",
    noSpec           = "No specialization",
    specNumbered     = "Spec %s",

    popupNewName     = "HotsNDots: name for the new profile",
    popupDelete      = "HotsNDots: delete the profile \"%s\"? Every spec using it falls back to Default.",
    popupReset       = "HotsNDots: reset the profile \"%s\" to the defaults?",

    -- ---------------- bar style page ----------------
    pageBarStyle     = "Bar style",
    barStyleIntro    = "How a bar row looks. Textures and fonts come from LibSharedMedia when any addon has loaded it,"
                    .. " so a media pack you already own shows up here; without it there is a small built-in list."
                    .. " Like everything else, this is part of the profile - each spec can look different.",
    lblPreview       = "Preview",
    lblStyle         = "Style",
    lblBarTexture    = "Bar texture",
    lblFont          = "Font",
    lblColorDots     = "Colour of your DoTs",
    lblColorHots     = "Colour of your HoTs",
    previewDot       = "Your DoT",
    previewHot       = "Your HoT",

    presetDefault    = "Default",
    presetCompact    = "Compact (no name)",
    presetIconRight  = "Icon on the right",
    presetNoIcon     = "No icon",
    -- ---------------- self bar page ----------------
    pageSelf         = "Your own HoTs",
    selfIntro        = "Your own HoTs and buffs on YOURSELF, as a movable row of icons in the style of Blizzard's cooldown manager:"
                    .. " icon, swipe and the seconds in the middle. Uses the same filters as everything else"
                    .. " (\"Hide buffs without a timer\" keeps your permanent raid buffs out).",
    cbSelf           = "Show the row of your own HoTs",
    cbSelfLock       = "Lock the row (not movable)",
    cbSelfAsBars     = "Show as bars (look from \"Bar style\")",
    cbGrowLeft       = "Grow to the left",
    slSpacing        = "Spacing",
    btnResetPos      = "Reset position",
    selfHint         = "Drag the green square to move the row. /hnd self switches it on and off, /hnd lock and /hnd unlock work for the bars and this row together.",
    selfAnchorLabel  = "Your HoTs \226\128\148 drag",
    msgSelf          = "row of your own HoTs %s",
    msgSelfLate      = "the row of your own HoTs arrives after a restart - please restart WoW to finish the update.",

    -- ---------------- messages ----------------
    on               = "ON",
    off              = "OFF",
    msgBarsLocked    = "bars locked.",
    msgBarsUnlocked  = "bars unlocked \226\128\147 drag to move.",
    msgNameplates    = "nameplate icons %s",
    msgBars          = "bars %s",
    msgMinimapButton = "minimap button %s",
    msgProfileNow    = "profile %s.",
    msgSpecUses      = "%s uses %s.",
    msgSpecNowUses   = "%s now uses %s.",
    msgNoSuchProfile = "there is no profile called \"%s\".",
    msgProfileList   = "profiles (active is %s)",
    msgCreated       = "created %s and put %s on it.",
    msgNoOtherToCopy = "there is no other profile to copy from.",
    msgNothingToDel  = "there is nothing to delete - only Default exists, and it stays.",
    msgCombat        = "the settings cannot be opened during combat - try again afterwards.",
    msgManualRoute   = "Open the settings via ESC > Options > AddOns > HotsNDots.",
    msgBlocked       = "the game blocked opening the settings panel (another addon has tainted it). ",
    msgNoContainer1  = "this client has no AuraContainer widget (needs 12.1.0),",
    msgNoContainer2  = "so the aura display stays off. Please update the game.",
    msgUpdate1       = "the update was installed while the game was running.",
    msgUpdate2       = "please RESTART WoW to finish it - /reload is not enough,",
    msgUpdate3       = "because new files are only picked up at startup.",
    msgInitFailed    = "%s failed - the rest keeps running.",
    msgDebugHint     = "/hnd debug shows the whole message.",
    msgProfilesLate  = "profiles are not loaded - please restart WoW to finish the update.",

    errNeedsName     = "a profile needs a name",
    errExists        = "that profile already exists",
    errNoSuch        = "no such profile",
    errDefaultKeep   = "the Default profile cannot be deleted",
    errSameProfile   = "that is the profile you are on",

    -- ---------------- minimap tooltip ----------------
    ttLeftSettings   = "Left click: settings",
    ttRightLock      = "Right click: lock/unlock bars",
    ttDrag           = "Drag: move this button",
    ttClickSettings  = "Click: open settings",
}

local translations = {}

translations.deDE = {
    tagline          = "Zeigt nur deine eigenen DoTs (auf Gegnern) und HoTs/Buffs (auf Verbündeten) \226\128\147 groß an der Namensplakette und als frei bewegliche Leisten.",
    editingProfile   = "Bearbeitetes Profil: %s",
    profilesTabHint  = "(siehe den Eintrag „Profile\" unter HotsNDots)",

    hdrNameplates    = "Symbole an der Namensplakette",
    cbNameplates     = "Symbole an Namensplaketten anzeigen",
    cbBelow          = "Unterhalb der Namensplakette anzeigen",
    cbStacks         = "Stapel anzeigen (nur echte Stapel, ab 2)",
    cbSwipe          = "Abklingzeit-Wischer anzeigen",
    slIconSize       = "Symbolgröße",
    slSecondsFont    = "Schriftgröße der Sekunden",
    slDistance       = "Abstand zur Namensplakette",
    slMaxIcons       = "Max. Symbole",

    hdrBars          = "Leisten (beweglich)",
    cbBars           = "Leisten anzeigen",
    cbLock           = "Leisten sperren (nicht beweglich)",
    cbGrowUp         = "Nach oben wachsen",
    slBarWidth       = "Leistenbreite",
    slBarHeight      = "Leistenhöhe",
    slMaxBars        = "Max. Leisten",
    barAnchorLabel   = "HotsNDots \226\128\148 zum Verschieben ziehen",

    hdrFilters       = "Filter",
    cbShowDebuffs    = "Debuffs anzeigen (deine DoTs auf Gegnern)",
    cbShowBuffs      = "Buffs anzeigen (deine HoTs auf Verbündeten)",
    cbHidePermBuffs  = "Buffs ohne Zeitangabe ausblenden",
    cbHidePermDebuffs= "Debuffs ohne Zeitangabe ausblenden",
    cbHideCC         = "Kontrolleffekte ausblenden",

    hdrGeneral       = "Allgemein",
    cbMinimap        = "Minikarten-Symbol anzeigen (nicht pro Profil)",

    pageProfiles     = "Profile",
    profilesIntro    = "Ein Profil enthält die Filter, die Symbole an der Namensplakette, die Leisten und die Position ihres Ankers."
                    .. " Jede Spezialisierung wählt ihr eigenes \226\128\147 wechselst du die Skillung, wechselt die Anordnung mit."
                    .. " Profile gelten für alle deine Charaktere; das Minikarten-Symbol gehört nicht dazu.",
    hdrPerSpec       = "Profil pro Spezialisierung",
    perSpecHint      = "Die Spezialisierung, in der du gerade bist, wechselt sofort; die anderen greifen, sobald du dorthin wechselst.",
    hdrManage        = "Verwalten",
    charLine         = "Charakter: %s      Aktuelle Spezialisierung: %s",
    activeProfile    = "Aktives Profil: %s",
    btnNewProfile    = "Neues Profil",
    btnNewFromThis   = "Neu aus diesem",
    btnCopyFrom      = "Kopieren von \226\128\166",
    btnResetProfile  = "Profil zurücksetzen",
    btnDelete        = "Löschen \226\128\166",
    noSpec           = "Keine Spezialisierung",
    specNumbered     = "Spez. %s",

    popupNewName     = "HotsNDots: Name für das neue Profil",
    popupDelete      = "HotsNDots: Profil „%s\" löschen? Jede Spezialisierung, die es benutzt, fällt auf „Default\" zurück.",
    popupReset       = "HotsNDots: Profil „%s\" auf die Standardwerte zurücksetzen?",

    pageBarStyle     = "Leisten-Stil",
    barStyleIntro    = "Wie eine Leiste aussieht. Texturen und Schriften kommen aus LibSharedMedia, sobald irgendein Addon sie geladen hat \226\128\147"
                    .. " ein Medienpaket, das du schon besitzt, taucht hier also auf; ohne die Bibliothek gibt es eine kleine eingebaute Liste."
                    .. " Wie alles andere gehört das zum Profil: jede Spezialisierung darf anders aussehen.",
    lblPreview       = "Vorschau",
    lblStyle         = "Stil",
    lblBarTexture    = "Leisten-Textur",
    lblFont          = "Schrift",
    lblColorDots     = "Farbe deiner DoTs",
    lblColorHots     = "Farbe deiner HoTs",
    previewDot       = "Dein DoT",
    previewHot       = "Dein HoT",

    presetDefault    = "Standard",
    presetCompact    = "Kompakt (ohne Namen)",
    presetIconRight  = "Symbol rechts",
    presetNoIcon     = "Ohne Symbol",
    -- ---------------- self bar page ----------------
    pageSelf         = "Eigene HoTs",
    selfIntro        = "Deine eigenen HoTs und Buffs AUF DIR SELBST, als verschiebbare Symbolreihe im Stil von Blizzards Abklingzeitenmanager:"
                    .. " Symbol, Ablauf-Animation und die Sekunden in der Mitte. Nutzt dieselben Filter wie alles andere"
                    .. " (\"Buffs ohne Zeitangabe ausblenden\" hält deine dauerhaften Raidbuffs heraus).",
    cbSelf           = "Reihe der eigenen HoTs anzeigen",
    cbSelfLock       = "Reihe sperren (nicht verschiebbar)",
    cbSelfAsBars     = "Als Balken anzeigen (Optik aus \"Leisten-Stil\")",
    cbGrowLeft       = "Nach links wachsen",
    slSpacing        = "Abstand",
    btnResetPos      = "Position zurücksetzen",
    selfHint         = "Zum Verschieben das grüne Quadrat ziehen. /hnd self schaltet die Reihe ein und aus, /hnd lock und /hnd unlock gelten für die Leisten und diese Reihe zusammen.",
    selfAnchorLabel  = "Eigene HoTs \226\128\148 ziehen",
    msgSelf          = "Reihe der eigenen HoTs %s",
    msgSelfLate      = "die Reihe der eigenen HoTs kommt erst nach einem Neustart - bitte WoW neu starten, um das Update abzuschließen.",

    on               = "AN",
    off              = "AUS",
    msgBarsLocked    = "Leisten gesperrt.",
    msgBarsUnlocked  = "Leisten entsperrt \226\128\147 zum Verschieben ziehen.",
    msgNameplates    = "Symbole an Namensplaketten %s",
    msgBars          = "Leisten %s",
    msgMinimapButton = "Minikarten-Symbol %s",
    msgProfileNow    = "Profil %s.",
    msgSpecUses      = "%s benutzt %s.",
    msgSpecNowUses   = "%s benutzt jetzt %s.",
    msgNoSuchProfile = "es gibt kein Profil namens „%s\".",
    msgProfileList   = "Profile (aktiv ist %s)",
    msgCreated       = "%s angelegt und %s darauf gesetzt.",
    msgNoOtherToCopy = "es gibt kein anderes Profil, von dem kopiert werden könnte.",
    msgNothingToDel  = "es gibt nichts zu löschen \226\128\147 es existiert nur „Default\", und das bleibt.",
    msgCombat        = "die Einstellungen lassen sich im Kampf nicht öffnen \226\128\147 danach noch einmal versuchen.",
    msgManualRoute   = "Einstellungen über ESC > Optionen > AddOns > HotsNDots öffnen.",
    msgBlocked       = "das Spiel hat das Öffnen der Einstellungen blockiert (ein anderes Addon hat sie verunreinigt). ",
    msgNoContainer1  = "dieser Client hat kein AuraContainer-Widget (benötigt 12.1.0),",
    msgNoContainer2  = "die Aura-Anzeige bleibt deshalb aus. Bitte aktualisiere das Spiel.",
    msgUpdate1       = "das Update wurde installiert, während das Spiel lief.",
    msgUpdate2       = "bitte starte WoW NEU, um es abzuschließen \226\128\147 /reload genügt nicht,",
    msgUpdate3       = "denn neue Dateien werden nur beim Start eingelesen.",
    msgInitFailed    = "%s fehlgeschlagen \226\128\147 der Rest läuft weiter.",
    msgDebugHint     = "/hnd debug zeigt die vollständige Meldung.",
    msgProfilesLate  = "Profile sind nicht geladen \226\128\147 bitte WoW neu starten, um das Update abzuschließen.",

    errNeedsName     = "ein Profil braucht einen Namen",
    errExists        = "dieses Profil gibt es schon",
    errNoSuch        = "dieses Profil gibt es nicht",
    errDefaultKeep   = "das Profil „Default\" kann nicht gelöscht werden",
    errSameProfile   = "auf diesem Profil bist du gerade",

    ttLeftSettings   = "Linksklick: Einstellungen",
    ttRightLock      = "Rechtsklick: Leisten sperren/entsperren",
    ttDrag           = "Ziehen: diesen Knopf verschieben",
    ttClickSettings  = "Klick: Einstellungen öffnen",
}

translations.frFR = {
    tagline          = "N'affiche que vos propres DoT (sur les ennemis) et HoT/buffs (sur les alliés), sur les plaques de nom et sous forme de barres déplaçables.",
    editingProfile   = "Profil en cours d'édition : %s",
    profilesTabHint  = "(voir l'entrée « Profils » sous HotsNDots)",

    hdrNameplates    = "Icônes sur la plaque de nom",
    cbNameplates     = "Afficher les icônes sur les plaques de nom",
    cbBelow          = "Afficher sous la plaque de nom",
    cbStacks         = "Afficher les cumuls (uniquement à partir de 2)",
    cbSwipe          = "Afficher le balayage de recharge",
    slIconSize       = "Taille des icônes",
    slSecondsFont    = "Taille du texte des secondes",
    slDistance       = "Distance à la plaque de nom",
    slMaxIcons       = "Icônes max.",

    hdrBars          = "Barres (déplaçables)",
    cbBars           = "Afficher les barres",
    cbLock           = "Verrouiller les barres (non déplaçables)",
    cbGrowUp         = "Croissance vers le haut",
    slBarWidth       = "Largeur des barres",
    slBarHeight      = "Hauteur des barres",
    slMaxBars        = "Barres max.",
    barAnchorLabel   = "HotsNDots \226\128\148 glisser pour déplacer",

    hdrFilters       = "Filtres",
    cbShowDebuffs    = "Afficher les debuffs (vos DoT sur les ennemis)",
    cbShowBuffs      = "Afficher les buffs (vos HoT sur les alliés)",
    cbHidePermBuffs  = "Masquer les buffs sans durée",
    cbHidePermDebuffs= "Masquer les debuffs sans durée",
    cbHideCC         = "Masquer le contrôle de foule",

    hdrGeneral       = "Général",
    cbMinimap        = "Afficher le bouton de la minicarte (pas par profil)",

    pageProfiles     = "Profils",
    profilesIntro    = "Un profil contient les filtres, les icônes de plaque de nom, les barres et la position de leur ancre."
                    .. " Chaque spécialisation choisit le sien : changer de spé change la disposition."
                    .. " Les profils sont partagés par tous vos personnages ; le bouton de la minicarte n'en fait pas partie.",
    hdrPerSpec       = "Profil par spécialisation",
    perSpecHint      = "La spécialisation actuelle change immédiatement ; les autres prendront effet quand vous y passerez.",
    hdrManage        = "Gérer",
    charLine         = "Personnage : %s      Spécialisation actuelle : %s",
    activeProfile    = "Profil actif : %s",
    btnNewProfile    = "Nouveau profil",
    btnNewFromThis   = "Nouveau d'après celui-ci",
    btnCopyFrom      = "Copier depuis\226\128\166",
    btnResetProfile  = "Réinitialiser ce profil",
    btnDelete        = "Supprimer\226\128\166",
    noSpec           = "Aucune spécialisation",
    specNumbered     = "Spé %s",

    popupNewName     = "HotsNDots : nom du nouveau profil",
    popupDelete      = "HotsNDots : supprimer le profil « %s » ? Chaque spécialisation qui l'utilise reviendra à Default.",
    popupReset       = "HotsNDots : réinitialiser le profil « %s » aux valeurs par défaut ?",

    pageBarStyle     = "Style des barres",
    barStyleIntro    = "L'apparence d'une barre. Les textures et les polices proviennent de LibSharedMedia dès qu'un addon l'a chargée :"
                    .. " un pack que vous possédez déjà apparaît donc ici ; sinon, une petite liste intégrée est utilisée."
                    .. " Comme le reste, cela fait partie du profil : chaque spécialisation peut être différente.",
    lblPreview       = "Aperçu",
    lblStyle         = "Style",
    lblBarTexture    = "Texture de barre",
    lblFont          = "Police",
    lblColorDots     = "Couleur de vos DoT",
    lblColorHots     = "Couleur de vos HoT",
    previewDot       = "Votre DoT",
    previewHot       = "Votre HoT",

    presetDefault    = "Par défaut",
    presetCompact    = "Compact (sans nom)",
    presetIconRight  = "Icône à droite",
    presetNoIcon     = "Sans icône",
    -- ---------------- self bar page ----------------
    pageSelf         = "Vos HoTs",
    selfIntro        = "Vos propres HoTs et buffs SUR VOUS-MÊME, en rangée d'icônes déplaçable dans le style du gestionnaire de temps de recharge de Blizzard :"
                    .. " icône, balayage et les secondes au centre. Utilise les mêmes filtres que le reste.",
    cbSelf           = "Afficher la rangée de vos HoTs",
    cbSelfLock       = "Verrouiller la rangée (non déplaçable)",
    cbSelfAsBars     = "Afficher en barres (aspect de \"Style des barres\")",
    cbGrowLeft       = "S'étendre vers la gauche",
    slSpacing        = "Espacement",
    btnResetPos      = "Réinitialiser la position",
    selfHint         = "Faites glisser le carré vert pour déplacer la rangée. /hnd self l'active ou la désactive, /hnd lock et /hnd unlock valent pour les barres et cette rangée.",
    selfAnchorLabel  = "Vos HoTs \226\128\148 glisser",
    msgSelf          = "rangée de vos HoTs %s",
    msgSelfLate      = "la rangée de vos HoTs arrive après un redémarrage - veuillez redémarrer WoW pour terminer la mise à jour.",

    on               = "ACTIVÉ",
    off              = "DÉSACTIVÉ",
    msgBarsLocked    = "barres verrouillées.",
    msgBarsUnlocked  = "barres déverrouillées \226\128\147 faites-les glisser pour les déplacer.",
    msgNameplates    = "icônes de plaque de nom %s",
    msgBars          = "barres %s",
    msgMinimapButton = "bouton de la minicarte %s",
    msgProfileNow    = "profil %s.",
    msgSpecUses      = "%s utilise %s.",
    msgSpecNowUses   = "%s utilise désormais %s.",
    msgNoSuchProfile = "il n'existe aucun profil nommé « %s ».",
    msgProfileList   = "profils (actif : %s)",
    msgCreated       = "%s créé, et %s l'utilise désormais.",
    msgNoOtherToCopy = "il n'y a aucun autre profil à copier.",
    msgNothingToDel  = "il n'y a rien à supprimer : seul Default existe, et il reste.",
    msgCombat        = "les options ne peuvent pas être ouvertes en combat \226\128\147 réessayez après.",
    msgManualRoute   = "Ouvrez les options via ÉCHAP > Options > AddOns > HotsNDots.",
    msgBlocked       = "le jeu a bloqué l'ouverture des options (un autre addon les a corrompues). ",
    msgNoContainer1  = "ce client n'a pas de widget AuraContainer (nécessite 12.1.0),",
    msgNoContainer2  = "l'affichage des auras reste donc désactivé. Veuillez mettre le jeu à jour.",
    msgUpdate1       = "la mise à jour a été installée pendant que le jeu tournait.",
    msgUpdate2       = "veuillez REDÉMARRER WoW pour la terminer \226\128\147 /reload ne suffit pas,",
    msgUpdate3       = "car les nouveaux fichiers ne sont lus qu'au démarrage.",
    msgInitFailed    = "échec de %s \226\128\147 le reste continue de fonctionner.",
    msgDebugHint     = "/hnd debug affiche le message complet.",
    msgProfilesLate  = "les profils ne sont pas chargés \226\128\147 redémarrez WoW pour terminer la mise à jour.",

    errNeedsName     = "un profil a besoin d'un nom",
    errExists        = "ce profil existe déjà",
    errNoSuch        = "profil introuvable",
    errDefaultKeep   = "le profil Default ne peut pas être supprimé",
    errSameProfile   = "c'est le profil que vous utilisez déjà",

    ttLeftSettings   = "Clic gauche : options",
    ttRightLock      = "Clic droit : verrouiller/déverrouiller les barres",
    ttDrag           = "Glisser : déplacer ce bouton",
    ttClickSettings  = "Clic : ouvrir les options",
}

translations.esES = {
    tagline          = "Muestra solo tus propios DoT (en enemigos) y HoT/beneficios (en aliados), en las placas de nombre y como barras móviles.",
    editingProfile   = "Editando el perfil: %s",
    profilesTabHint  = "(consulta la entrada «Perfiles» en HotsNDots)",

    hdrNameplates    = "Iconos en la placa de nombre",
    cbNameplates     = "Mostrar iconos en las placas de nombre",
    cbBelow          = "Mostrar debajo de la placa de nombre",
    cbStacks         = "Mostrar acumulaciones (solo reales, 2+)",
    cbSwipe          = "Mostrar barrido de reutilización",
    slIconSize       = "Tamaño de icono",
    slSecondsFont    = "Tamaño de fuente de los segundos",
    slDistance       = "Distancia a la placa de nombre",
    slMaxIcons       = "Iconos máx.",

    hdrBars          = "Barras (móviles)",
    cbBars           = "Mostrar barras",
    cbLock           = "Bloquear barras (no móviles)",
    cbGrowUp         = "Crecer hacia arriba",
    slBarWidth       = "Ancho de barra",
    slBarHeight      = "Alto de barra",
    slMaxBars        = "Barras máx.",
    barAnchorLabel   = "HotsNDots \226\128\148 arrastra para mover",

    hdrFilters       = "Filtros",
    cbShowDebuffs    = "Mostrar perjuicios (tus DoT en enemigos)",
    cbShowBuffs      = "Mostrar beneficios (tus HoT en aliados)",
    cbHidePermBuffs  = "Ocultar beneficios sin duración",
    cbHidePermDebuffs= "Ocultar perjuicios sin duración",
    cbHideCC         = "Ocultar control de masas",

    hdrGeneral       = "General",
    cbMinimap        = "Mostrar botón del minimapa (no por perfil)",

    pageProfiles     = "Perfiles",
    profilesIntro    = "Un perfil contiene los filtros, los iconos de la placa de nombre, las barras y la posición de su ancla."
                    .. " Cada especialización elige el suyo, así que cambiar de especialización cambia la disposición."
                    .. " Los perfiles se comparten entre todos tus personajes; el botón del minimapa no forma parte de ellos.",
    hdrPerSpec       = "Perfil por especialización",
    perSpecHint      = "La especialización actual cambia de inmediato; las demás se aplicarán cuando cambies a ellas.",
    hdrManage        = "Gestionar",
    charLine         = "Personaje: %s      Especialización actual: %s",
    activeProfile    = "Perfil activo: %s",
    btnNewProfile    = "Nuevo perfil",
    btnNewFromThis   = "Nuevo a partir de este",
    btnCopyFrom      = "Copiar desde\226\128\166",
    btnResetProfile  = "Restablecer este perfil",
    btnDelete        = "Eliminar\226\128\166",
    noSpec           = "Sin especialización",
    specNumbered     = "Esp. %s",

    popupNewName     = "HotsNDots: nombre del nuevo perfil",
    popupDelete      = "HotsNDots: ¿eliminar el perfil «%s»? Cada especialización que lo use volverá a Default.",
    popupReset       = "HotsNDots: ¿restablecer el perfil «%s» a los valores predeterminados?",

    pageBarStyle     = "Estilo de barra",
    barStyleIntro    = "El aspecto de una barra. Las texturas y las fuentes provienen de LibSharedMedia si algún addon la ha cargado,"
                    .. " así que un paquete que ya tengas aparecerá aquí; si no, se usa una pequeña lista integrada."
                    .. " Como todo lo demás, esto forma parte del perfil: cada especialización puede verse distinta.",
    lblPreview       = "Vista previa",
    lblStyle         = "Estilo",
    lblBarTexture    = "Textura de barra",
    lblFont          = "Fuente",
    lblColorDots     = "Color de tus DoT",
    lblColorHots     = "Color de tus HoT",
    previewDot       = "Tu DoT",
    previewHot       = "Tu HoT",

    presetDefault    = "Predeterminado",
    presetCompact    = "Compacto (sin nombre)",
    presetIconRight  = "Icono a la derecha",
    presetNoIcon     = "Sin icono",
    -- ---------------- self bar page ----------------
    pageSelf         = "Tus HoTs",
    selfIntro        = "Tus propios HoTs y beneficios SOBRE TI, como una fila de iconos móvil al estilo del gestor de reutilización de Blizzard:"
                    .. " icono, barrido y los segundos en el centro. Usa los mismos filtros que todo lo demás.",
    cbSelf           = "Mostrar la fila de tus HoTs",
    cbSelfLock       = "Bloquear la fila (no móvil)",
    cbSelfAsBars     = "Mostrar como barras (aspecto de \"Estilo de barra\")",
    cbGrowLeft       = "Crecer hacia la izquierda",
    slSpacing        = "Espaciado",
    btnResetPos      = "Restablecer posición",
    selfHint         = "Arrastra el cuadrado verde para mover la fila. /hnd self la activa o desactiva, /hnd lock y /hnd unlock valen para las barras y esta fila.",
    selfAnchorLabel  = "Tus HoTs \226\128\148 arrastra",
    msgSelf          = "fila de tus HoTs %s",
    msgSelfLate      = "la fila de tus HoTs llega tras reiniciar - reinicia WoW para terminar la actualización.",

    on               = "ACTIVADO",
    off              = "DESACTIVADO",
    msgBarsLocked    = "barras bloqueadas.",
    msgBarsUnlocked  = "barras desbloqueadas \226\128\147 arrástralas para moverlas.",
    msgNameplates    = "iconos de placa de nombre %s",
    msgBars          = "barras %s",
    msgMinimapButton = "botón del minimapa %s",
    msgProfileNow    = "perfil %s.",
    msgSpecUses      = "%s usa %s.",
    msgSpecNowUses   = "%s ahora usa %s.",
    msgNoSuchProfile = "no existe ningún perfil llamado «%s».",
    msgProfileList   = "perfiles (activo: %s)",
    msgCreated       = "«%s» creado y %s ahora lo usa.",
    msgNoOtherToCopy = "no hay ningún otro perfil del que copiar.",
    msgNothingToDel  = "no hay nada que eliminar: solo existe Default, y se queda.",
    msgCombat        = "las opciones no se pueden abrir en combate \226\128\147 inténtalo después.",
    msgManualRoute   = "Abre las opciones con ESC > Opciones > AddOns > HotsNDots.",
    msgBlocked       = "el juego bloqueó la apertura de las opciones (otro addon las ha contaminado). ",
    msgNoContainer1  = "este cliente no tiene el widget AuraContainer (necesita 12.1.0),",
    msgNoContainer2  = "por eso la visualización de auras queda desactivada. Actualiza el juego.",
    msgUpdate1       = "la actualización se instaló mientras el juego estaba abierto.",
    msgUpdate2       = "REINICIA WoW para terminarla \226\128\147 /reload no basta,",
    msgUpdate3       = "porque los archivos nuevos solo se leen al arrancar.",
    msgInitFailed    = "%s ha fallado \226\128\147 el resto sigue funcionando.",
    msgDebugHint     = "/hnd debug muestra el mensaje completo.",
    msgProfilesLate  = "los perfiles no están cargados \226\128\147 reinicia WoW para terminar la actualización.",

    errNeedsName     = "un perfil necesita un nombre",
    errExists        = "ese perfil ya existe",
    errNoSuch        = "no existe ese perfil",
    errDefaultKeep   = "el perfil Default no se puede eliminar",
    errSameProfile   = "ese es el perfil que estás usando",

    ttLeftSettings   = "Clic izquierdo: opciones",
    ttRightLock      = "Clic derecho: bloquear/desbloquear barras",
    ttDrag           = "Arrastrar: mover este botón",
    ttClickSettings  = "Clic: abrir opciones",
}

-- Italian. Terms as the Italian client uses them: "barre dei nomi" for
-- nameplates, "specializzazione", "minimappa"; buff/debuff stay as players say them.
translations.itIT = {
    tagline          = "Mostra solo i tuoi DoT (sui nemici) e HoT/buff (sugli alleati), sulle barre dei nomi e come barre spostabili.",
    editingProfile   = "Profilo in modifica: %s",
    profilesTabHint  = "(vedi la voce «Profili» sotto HotsNDots)",

    hdrNameplates    = "Icone sulla barra del nome",
    cbNameplates     = "Mostra le icone sulle barre dei nomi",
    cbBelow          = "Mostra sotto la barra del nome",
    cbStacks         = "Mostra le cariche (solo cariche reali, 2+)",
    cbSwipe          = "Mostra l'animazione del tempo di recupero",
    slIconSize       = "Dimensione icone",
    slSecondsFont    = "Dimensione carattere dei secondi",
    slDistance       = "Distanza dalla barra del nome",
    slMaxIcons       = "Icone max.",

    hdrBars          = "Barre (spostabili)",
    cbBars           = "Mostra le barre",
    cbLock           = "Blocca le barre (non spostabili)",
    cbGrowUp         = "Crescita verso l'alto",
    slBarWidth       = "Larghezza barre",
    slBarHeight      = "Altezza barre",
    slMaxBars        = "Barre max.",
    barAnchorLabel   = "HotsNDots \226\128\148 trascina per spostare",

    hdrFilters       = "Filtri",
    cbShowDebuffs    = "Mostra i debuff (i tuoi DoT sui nemici)",
    cbShowBuffs      = "Mostra i buff (i tuoi HoT sugli alleati)",
    cbHidePermBuffs  = "Nascondi i buff senza durata",
    cbHidePermDebuffs= "Nascondi i debuff senza durata",
    cbHideCC         = "Nascondi il controllo della folla",

    hdrGeneral       = "Generale",
    cbMinimap        = "Mostra il pulsante della minimappa (non per profilo)",

    pageProfiles     = "Profili",
    profilesIntro    = "Un profilo contiene i filtri, le icone sulle barre dei nomi, le barre e la posizione del loro ancoraggio."
                    .. " Ogni specializzazione sceglie il proprio, quindi cambiando specializzazione cambia anche la disposizione."
                    .. " I profili sono condivisi da tutti i tuoi personaggi; il pulsante della minimappa non ne fa parte.",
    hdrPerSpec       = "Profilo per specializzazione",
    perSpecHint      = "La specializzazione attiva cambia subito; le altre si applicano quando passi a esse.",
    hdrManage        = "Gestisci",
    charLine         = "Personaggio: %s      Specializzazione attuale: %s",
    activeProfile    = "Profilo attivo: %s",
    btnNewProfile    = "Nuovo profilo",
    btnNewFromThis   = "Nuovo da questo",
    btnCopyFrom      = "Copia da\226\128\166",
    btnResetProfile  = "Reimposta questo profilo",
    btnDelete        = "Elimina\226\128\166",
    noSpec           = "Nessuna specializzazione",
    specNumbered     = "Spec. %s",

    popupNewName     = "HotsNDots: nome del nuovo profilo",
    popupDelete      = "HotsNDots: eliminare il profilo «%s»? Ogni specializzazione che lo usa torna a Default.",
    popupReset       = "HotsNDots: reimpostare il profilo «%s» ai valori predefiniti?",

    pageBarStyle     = "Stile barre",
    barStyleIntro    = "L'aspetto di una barra. Texture e caratteri provengono da LibSharedMedia se un addon l'ha caricata,"
                    .. " quindi un pacchetto che possiedi già compare qui; altrimenti c'è un piccolo elenco integrato."
                    .. " Come tutto il resto, fa parte del profilo: ogni specializzazione può avere un aspetto diverso.",
    lblPreview       = "Anteprima",
    lblStyle         = "Stile",
    lblBarTexture    = "Texture della barra",
    lblFont          = "Carattere",
    lblColorDots     = "Colore dei tuoi DoT",
    lblColorHots     = "Colore dei tuoi HoT",
    previewDot       = "Il tuo DoT",
    previewHot       = "Il tuo HoT",

    presetDefault    = "Predefinito",
    presetCompact    = "Compatto (senza nome)",
    presetIconRight  = "Icona a destra",
    presetNoIcon     = "Senza icona",
    -- ---------------- self bar page ----------------
    pageSelf         = "I tuoi HoT",
    selfIntro        = "I tuoi HoT e buff su TE STESSO, come fila di icone spostabile nello stile del gestore dei tempi di recupero di Blizzard:"
                    .. " icona, animazione e i secondi al centro. Usa gli stessi filtri di tutto il resto"
                    .. " («Nascondi i buff senza durata» esclude i tuoi buff permanenti da incursione).",
    cbSelf           = "Mostra la fila dei tuoi HoT",
    cbSelfLock       = "Blocca la fila (non spostabile)",
    cbSelfAsBars     = "Mostra come barre (aspetto da «Stile barre»)",
    cbGrowLeft       = "Crescita verso sinistra",
    slSpacing        = "Spaziatura",
    btnResetPos      = "Reimposta posizione",
    selfHint         = "Trascina il quadrato verde per spostare la fila. /hnd self la attiva e disattiva, /hnd lock e /hnd unlock valgono insieme per le barre e questa fila.",
    selfAnchorLabel  = "I tuoi HoT \226\128\148 trascina",
    msgSelf          = "fila dei tuoi HoT %s",
    msgSelfLate      = "la fila dei tuoi HoT arriva dopo un riavvio - riavvia WoW per completare l'aggiornamento.",

    on               = "ATTIVO",
    off              = "DISATTIVO",
    msgBarsLocked    = "barre bloccate.",
    msgBarsUnlocked  = "barre sbloccate \226\128\147 trascinale per spostarle.",
    msgNameplates    = "icone sulle barre dei nomi %s",
    msgBars          = "barre %s",
    msgMinimapButton = "pulsante della minimappa %s",
    msgProfileNow    = "profilo %s.",
    msgSpecUses      = "%s usa %s.",
    msgSpecNowUses   = "%s ora usa %s.",
    msgNoSuchProfile = "non esiste nessun profilo chiamato «%s».",
    msgProfileList   = "profili (attivo: %s)",
    msgCreated       = "%s creato, e ora %s lo usa.",
    msgNoOtherToCopy = "non c'è nessun altro profilo da cui copiare.",
    msgNothingToDel  = "non c'è niente da eliminare: esiste solo Default, e resta.",
    msgCombat        = "le opzioni non si possono aprire in combattimento \226\128\147 riprova dopo.",
    msgManualRoute   = "Apri le opzioni da ESC > Opzioni > AddOn > HotsNDots.",
    msgBlocked       = "il gioco ha bloccato l'apertura delle opzioni (un altro addon le ha contaminate). ",
    msgNoContainer1  = "questo client non ha il widget AuraContainer (richiede 12.1.0),",
    msgNoContainer2  = "quindi la visualizzazione delle aure resta disattivata. Aggiorna il gioco.",
    msgUpdate1       = "l'aggiornamento è stato installato mentre il gioco era in esecuzione.",
    msgUpdate2       = "RIAVVIA WoW per completarlo \226\128\147 /reload non basta,",
    msgUpdate3       = "perché i nuovi file vengono letti solo all'avvio.",
    msgInitFailed    = "%s non riuscito \226\128\147 il resto continua a funzionare.",
    msgDebugHint     = "/hnd debug mostra il messaggio completo.",
    msgProfilesLate  = "i profili non sono caricati \226\128\147 riavvia WoW per completare l'aggiornamento.",

    errNeedsName     = "un profilo ha bisogno di un nome",
    errExists        = "questo profilo esiste già",
    errNoSuch        = "profilo inesistente",
    errDefaultKeep   = "il profilo Default non può essere eliminato",
    errSameProfile   = "è il profilo che stai già usando",

    ttLeftSettings   = "Clic sinistro: opzioni",
    ttRightLock      = "Clic destro: blocca/sblocca le barre",
    ttDrag           = "Trascina: sposta questo pulsante",
    ttClickSettings  = "Clic: apri le opzioni",
}

-- Brazilian Portuguese. "placas de identificação" for nameplates, as the
-- ptBR client calls them; "bônus"/"penalidades" for buffs/debuffs.
translations.ptBR = {
    tagline          = "Mostra apenas seus próprios DoTs (em inimigos) e HoTs/bônus (em aliados), nas placas de identificação e como barras móveis.",
    editingProfile   = "Editando o perfil: %s",
    profilesTabHint  = "(veja a entrada \"Perfis\" em HotsNDots)",

    hdrNameplates    = "Ícones na placa de identificação",
    cbNameplates     = "Mostrar ícones nas placas de identificação",
    cbBelow          = "Mostrar abaixo da placa de identificação",
    cbStacks         = "Mostrar acúmulos (só acúmulos reais, 2+)",
    cbSwipe          = "Mostrar animação de tempo de recarga",
    slIconSize       = "Tamanho do ícone",
    slSecondsFont    = "Tamanho da fonte dos segundos",
    slDistance       = "Distância da placa de identificação",
    slMaxIcons       = "Máx. de ícones",

    hdrBars          = "Barras (móveis)",
    cbBars           = "Mostrar barras",
    cbLock           = "Travar barras (não móveis)",
    cbGrowUp         = "Crescer para cima",
    slBarWidth       = "Largura da barra",
    slBarHeight      = "Altura da barra",
    slMaxBars        = "Máx. de barras",
    barAnchorLabel   = "HotsNDots \226\128\148 arraste para mover",

    hdrFilters       = "Filtros",
    cbShowDebuffs    = "Mostrar penalidades (seus DoTs em inimigos)",
    cbShowBuffs      = "Mostrar bônus (seus HoTs em aliados)",
    cbHidePermBuffs  = "Ocultar bônus sem duração",
    cbHidePermDebuffs= "Ocultar penalidades sem duração",
    cbHideCC         = "Ocultar controle de grupo",

    hdrGeneral       = "Geral",
    cbMinimap        = "Mostrar botão do minimapa (não por perfil)",

    pageProfiles     = "Perfis",
    profilesIntro    = "Um perfil guarda os filtros, os ícones da placa de identificação, as barras e a posição da âncora delas."
                    .. " Cada especialização escolhe o seu, então trocar de especialização troca o layout junto."
                    .. " Os perfis são compartilhados por todos os seus personagens; o botão do minimapa não faz parte deles.",
    hdrPerSpec       = "Perfil por especialização",
    perSpecHint      = "A especialização atual muda na hora; as outras passam a valer quando você trocar para elas.",
    hdrManage        = "Gerenciar",
    charLine         = "Personagem: %s      Especialização atual: %s",
    activeProfile    = "Perfil ativo: %s",
    btnNewProfile    = "Novo perfil",
    btnNewFromThis   = "Novo a partir deste",
    btnCopyFrom      = "Copiar de\226\128\166",
    btnResetProfile  = "Redefinir este perfil",
    btnDelete        = "Excluir\226\128\166",
    noSpec           = "Sem especialização",
    specNumbered     = "Espec. %s",

    popupNewName     = "HotsNDots: nome do novo perfil",
    popupDelete      = "HotsNDots: excluir o perfil \"%s\"? Toda especialização que o usa volta para Default.",
    popupReset       = "HotsNDots: redefinir o perfil \"%s\" para os valores padrão?",

    pageBarStyle     = "Estilo das barras",
    barStyleIntro    = "A aparência de uma barra. Texturas e fontes vêm da LibSharedMedia quando algum addon a carrega,"
                    .. " então um pacote de mídia que você já tem aparece aqui; sem ela há uma pequena lista embutida."
                    .. " Como todo o resto, isso faz parte do perfil: cada especialização pode ter outra aparência.",
    lblPreview       = "Pré-visualização",
    lblStyle         = "Estilo",
    lblBarTexture    = "Textura da barra",
    lblFont          = "Fonte",
    lblColorDots     = "Cor dos seus DoTs",
    lblColorHots     = "Cor dos seus HoTs",
    previewDot       = "Seu DoT",
    previewHot       = "Seu HoT",

    presetDefault    = "Padrão",
    presetCompact    = "Compacto (sem nome)",
    presetIconRight  = "Ícone à direita",
    presetNoIcon     = "Sem ícone",
    -- ---------------- self bar page ----------------
    pageSelf         = "Seus HoTs",
    selfIntro        = "Seus próprios HoTs e bônus EM VOCÊ MESMO, como uma fileira de ícones móvel no estilo do gerenciador de recargas da Blizzard:"
                    .. " ícone, animação e os segundos no meio. Usa os mesmos filtros de todo o resto"
                    .. " (\"Ocultar bônus sem duração\" deixa de fora seus bônus permanentes de raide).",
    cbSelf           = "Mostrar a fileira dos seus HoTs",
    cbSelfLock       = "Travar a fileira (não móvel)",
    cbSelfAsBars     = "Mostrar como barras (aparência de \"Estilo das barras\")",
    cbGrowLeft       = "Crescer para a esquerda",
    slSpacing        = "Espaçamento",
    btnResetPos      = "Redefinir posição",
    selfHint         = "Arraste o quadrado verde para mover a fileira. /hnd self liga e desliga, /hnd lock e /hnd unlock valem para as barras e esta fileira juntas.",
    selfAnchorLabel  = "Seus HoTs \226\128\148 arraste",
    msgSelf          = "fileira dos seus HoTs %s",
    msgSelfLate      = "a fileira dos seus HoTs só aparece após reiniciar - reinicie o WoW para concluir a atualização.",

    on               = "LIGADO",
    off              = "DESLIGADO",
    msgBarsLocked    = "barras travadas.",
    msgBarsUnlocked  = "barras destravadas \226\128\147 arraste para mover.",
    msgNameplates    = "ícones nas placas de identificação %s",
    msgBars          = "barras %s",
    msgMinimapButton = "botão do minimapa %s",
    msgProfileNow    = "perfil %s.",
    msgSpecUses      = "%s usa %s.",
    msgSpecNowUses   = "%s agora usa %s.",
    msgNoSuchProfile = "não existe nenhum perfil chamado \"%s\".",
    msgProfileList   = "perfis (ativo: %s)",
    msgCreated       = "%s criado, e %s agora o usa.",
    msgNoOtherToCopy = "não há outro perfil de onde copiar.",
    msgNothingToDel  = "não há nada para excluir: só existe Default, e ele fica.",
    msgCombat        = "as opções não podem ser abertas em combate \226\128\147 tente de novo depois.",
    msgManualRoute   = "Abra as opções por ESC > Opções > AddOns > HotsNDots.",
    msgBlocked       = "o jogo bloqueou a abertura das opções (outro addon as contaminou). ",
    msgNoContainer1  = "este cliente não tem o widget AuraContainer (requer 12.1.0),",
    msgNoContainer2  = "por isso a exibição de auras fica desligada. Atualize o jogo.",
    msgUpdate1       = "a atualização foi instalada com o jogo aberto.",
    msgUpdate2       = "REINICIE o WoW para concluí-la \226\128\147 /reload não basta,",
    msgUpdate3       = "porque arquivos novos só são lidos na inicialização.",
    msgInitFailed    = "%s falhou \226\128\147 o resto continua funcionando.",
    msgDebugHint     = "/hnd debug mostra a mensagem completa.",
    msgProfilesLate  = "os perfis não foram carregados \226\128\147 reinicie o WoW para concluir a atualização.",

    errNeedsName     = "um perfil precisa de um nome",
    errExists        = "esse perfil já existe",
    errNoSuch        = "esse perfil não existe",
    errDefaultKeep   = "o perfil Default não pode ser excluído",
    errSameProfile   = "esse é o perfil que você está usando",

    ttLeftSettings   = "Clique esquerdo: opções",
    ttRightLock      = "Clique direito: travar/destravar barras",
    ttDrag           = "Arrastar: mover este botão",
    ttClickSettings  = "Clique: abrir opções",
}

-- Russian. "индикаторы здоровья" for nameplates, as the ruRU client calls
-- them; "положительные/отрицательные эффекты" for buffs/debuffs.
translations.ruRU = {
    tagline          = "Показывает только ваши собственные DoT (на противниках) и HoT/положительные эффекты (на союзниках) — на индикаторах здоровья и в виде перемещаемых полос.",
    editingProfile   = "Редактируемый профиль: %s",
    profilesTabHint  = "(см. раздел «Профили» в HotsNDots)",

    hdrNameplates    = "Значки на индикаторах здоровья",
    cbNameplates     = "Показывать значки на индикаторах здоровья",
    cbBelow          = "Показывать под индикатором здоровья",
    cbStacks         = "Показывать стаки (только настоящие, от 2)",
    cbSwipe          = "Показывать анимацию восстановления",
    slIconSize       = "Размер значков",
    slSecondsFont    = "Размер шрифта секунд",
    slDistance       = "Расстояние до индикатора",
    slMaxIcons       = "Макс. значков",

    hdrBars          = "Полосы (перемещаемые)",
    cbBars           = "Показывать полосы",
    cbLock           = "Закрепить полосы (не перемещаются)",
    cbGrowUp         = "Рост вверх",
    slBarWidth       = "Ширина полосы",
    slBarHeight      = "Высота полосы",
    slMaxBars        = "Макс. полос",
    barAnchorLabel   = "HotsNDots \226\128\148 перетащите, чтобы переместить",

    hdrFilters       = "Фильтры",
    cbShowDebuffs    = "Показывать отрицательные эффекты (ваши DoT на противниках)",
    cbShowBuffs      = "Показывать положительные эффекты (ваши HoT на союзниках)",
    cbHidePermBuffs  = "Скрывать положительные эффекты без таймера",
    cbHidePermDebuffs= "Скрывать отрицательные эффекты без таймера",
    cbHideCC         = "Скрывать эффекты контроля",

    hdrGeneral       = "Общие",
    cbMinimap        = "Показывать кнопку у миникарты (не зависит от профиля)",

    pageProfiles     = "Профили",
    profilesIntro    = "Профиль хранит фильтры, значки на индикаторах здоровья, полосы и положение их якоря."
                    .. " Каждая специализация выбирает свой, поэтому при смене специализации меняется и расположение."
                    .. " Профили общие для всех ваших персонажей; кнопка у миникарты в них не входит.",
    hdrPerSpec       = "Профиль для каждой специализации",
    perSpecHint      = "Текущая специализация переключается сразу; остальные вступят в силу, когда вы на них перейдете.",
    hdrManage        = "Управление",
    charLine         = "Персонаж: %s      Текущая специализация: %s",
    activeProfile    = "Активный профиль: %s",
    btnNewProfile    = "Новый профиль",
    btnNewFromThis   = "Новый на основе этого",
    btnCopyFrom      = "Копировать из\226\128\166",
    btnResetProfile  = "Сбросить этот профиль",
    btnDelete        = "Удалить\226\128\166",
    noSpec           = "Нет специализации",
    specNumbered     = "Специализация %s",

    popupNewName     = "HotsNDots: имя нового профиля",
    popupDelete      = "HotsNDots: удалить профиль «%s»? Все специализации, которые его используют, вернутся к Default.",
    popupReset       = "HotsNDots: сбросить профиль «%s» к значениям по умолчанию?",

    pageBarStyle     = "Стиль полос",
    barStyleIntro    = "Как выглядит полоса. Текстуры и шрифты берутся из LibSharedMedia, если ее загрузила какая-либо модификация,"
                    .. " поэтому уже установленный у вас набор медиафайлов появится здесь; без нее доступен небольшой встроенный список."
                    .. " Как и все остальное, это часть профиля: каждая специализация может выглядеть по-своему.",
    lblPreview       = "Предпросмотр",
    lblStyle         = "Стиль",
    lblBarTexture    = "Текстура полосы",
    lblFont          = "Шрифт",
    lblColorDots     = "Цвет ваших DoT",
    lblColorHots     = "Цвет ваших HoT",
    previewDot       = "Ваш DoT",
    previewHot       = "Ваш HoT",

    presetDefault    = "По умолчанию",
    presetCompact    = "Компактный (без названия)",
    presetIconRight  = "Значок справа",
    presetNoIcon     = "Без значка",
    -- ---------------- self bar page ----------------
    pageSelf         = "Ваши HoT",
    selfIntro        = "Ваши собственные HoT и положительные эффекты НА ВАС САМИХ, в виде перемещаемого ряда значков в стиле менеджера восстановления Blizzard:"
                    .. " значок, анимация и секунды в центре. Использует те же фильтры, что и все остальное"
                    .. " («Скрывать положительные эффекты без таймера» убирает ваши постоянные рейдовые эффекты).",
    cbSelf           = "Показывать ряд ваших HoT",
    cbSelfLock       = "Закрепить ряд (не перемещается)",
    cbSelfAsBars     = "Показывать полосами (вид из «Стиль полос»)",
    cbGrowLeft       = "Рост влево",
    slSpacing        = "Интервал",
    btnResetPos      = "Сбросить положение",
    selfHint         = "Перетащите зеленый квадрат, чтобы переместить ряд. /hnd self включает и выключает его, /hnd lock и /hnd unlock действуют на полосы и этот ряд вместе.",
    selfAnchorLabel  = "Ваши HoT \226\128\148 перетащите",
    msgSelf          = "ряд ваших HoT: %s",
    msgSelfLate      = "ряд ваших HoT появится после перезапуска - перезапустите WoW, чтобы завершить обновление.",

    on               = "ВКЛ",
    off              = "ВЫКЛ",
    msgBarsLocked    = "полосы закреплены.",
    msgBarsUnlocked  = "полосы откреплены \226\128\147 перетащите, чтобы переместить.",
    msgNameplates    = "значки на индикаторах здоровья: %s",
    msgBars          = "полосы: %s",
    msgMinimapButton = "кнопка у миникарты: %s",
    msgProfileNow    = "профиль %s.",
    msgSpecUses      = "%s использует %s.",
    msgSpecNowUses   = "%s теперь использует %s.",
    msgNoSuchProfile = "профиля с именем «%s» не существует.",
    msgProfileList   = "профили (активный: %s)",
    msgCreated       = "создан профиль %s, его теперь использует %s.",
    msgNoOtherToCopy = "нет другого профиля, из которого можно скопировать.",
    msgNothingToDel  = "удалять нечего: существует только Default, и он остается.",
    msgCombat        = "настройки нельзя открыть в бою \226\128\147 попробуйте позже.",
    msgManualRoute   = "Откройте настройки через ESC > Настройки > Модификации > HotsNDots.",
    msgBlocked       = "игра заблокировала открытие панели настроек (другая модификация ее «испортила»). ",
    msgNoContainer1  = "в этом клиенте нет виджета AuraContainer (нужен 12.1.0),",
    msgNoContainer2  = "поэтому отображение эффектов отключено. Обновите игру.",
    msgUpdate1       = "обновление было установлено, пока игра была запущена.",
    msgUpdate2       = "ПЕРЕЗАПУСТИТЕ WoW, чтобы завершить его \226\128\147 /reload недостаточно,",
    msgUpdate3       = "потому что новые файлы загружаются только при запуске.",
    msgInitFailed    = "ошибка: %s \226\128\147 остальное продолжает работать.",
    msgDebugHint     = "/hnd debug показывает полное сообщение.",
    msgProfilesLate  = "профили не загружены \226\128\147 перезапустите WoW, чтобы завершить обновление.",

    errNeedsName     = "у профиля должно быть имя",
    errExists        = "такой профиль уже существует",
    errNoSuch        = "такого профиля нет",
    errDefaultKeep   = "профиль Default нельзя удалить",
    errSameProfile   = "это профиль, который вы сейчас используете",

    ttLeftSettings   = "Левый щелчок: настройки",
    ttRightLock      = "Правый щелчок: закрепить/открепить полосы",
    ttDrag           = "Перетаскивание: переместить эту кнопку",
    ttClickSettings  = "Щелчок: открыть настройки",
}

-- Korean. "이름표" for nameplates, "강화 효과"/"약화 효과" for buffs/debuffs,
-- "전문화" for specialization, as the koKR client calls them.
translations.koKR = {
    tagline          = "내가 건 DoT(적에게)와 HoT/강화 효과(아군에게)만 이름표와 이동 가능한 바로 표시합니다.",
    editingProfile   = "편집 중인 프로필: %s",
    profilesTabHint  = "(HotsNDots 아래의 '프로필' 항목 참고)",

    hdrNameplates    = "이름표 아이콘",
    cbNameplates     = "이름표 아이콘 표시",
    cbBelow          = "이름표 아래에 표시",
    cbStacks         = "중첩 표시 (실제 중첩, 2 이상만)",
    cbSwipe          = "재사용 대기시간 애니메이션 표시",
    slIconSize       = "아이콘 크기",
    slSecondsFont    = "초 글꼴 크기",
    slDistance       = "이름표와의 거리",
    slMaxIcons       = "최대 아이콘 수",

    hdrBars          = "바 (이동 가능)",
    cbBars           = "바 표시",
    cbLock           = "바 잠금 (이동 불가)",
    cbGrowUp         = "위로 쌓기",
    slBarWidth       = "바 너비",
    slBarHeight      = "바 높이",
    slMaxBars        = "최대 바 수",
    barAnchorLabel   = "HotsNDots \226\128\148 끌어서 이동",

    hdrFilters       = "필터",
    cbShowDebuffs    = "약화 효과 표시 (적에게 건 내 DoT)",
    cbShowBuffs      = "강화 효과 표시 (아군에게 건 내 HoT)",
    cbHidePermBuffs  = "지속시간 없는 강화 효과 숨기기",
    cbHidePermDebuffs= "지속시간 없는 약화 효과 숨기기",
    cbHideCC         = "군중 제어 효과 숨기기",

    hdrGeneral       = "일반",
    cbMinimap        = "미니맵 버튼 표시 (프로필별 아님)",

    pageProfiles     = "프로필",
    profilesIntro    = "프로필에는 필터, 이름표 아이콘, 바, 바 기준점의 위치가 저장됩니다."
                    .. " 전문화마다 자기 프로필을 고르므로, 전문화를 바꾸면 배치도 함께 바뀝니다."
                    .. " 프로필은 모든 캐릭터가 함께 쓰며, 미니맵 버튼은 프로필에 포함되지 않습니다.",
    hdrPerSpec       = "전문화별 프로필",
    perSpecHint      = "현재 전문화는 즉시 바뀌고, 나머지는 해당 전문화로 바꿀 때 적용됩니다.",
    hdrManage        = "관리",
    charLine         = "캐릭터: %s      현재 전문화: %s",
    activeProfile    = "사용 중인 프로필: %s",
    btnNewProfile    = "새 프로필",
    btnNewFromThis   = "이 프로필로 새로 만들기",
    btnCopyFrom      = "복사해 오기\226\128\166",
    btnResetProfile  = "이 프로필 초기화",
    btnDelete        = "삭제\226\128\166",
    noSpec           = "전문화 없음",
    specNumbered     = "전문화 %s",

    popupNewName     = "HotsNDots: 새 프로필 이름",
    popupDelete      = "HotsNDots: '%s' 프로필을 삭제할까요? 이 프로필을 쓰는 전문화는 모두 Default로 돌아갑니다.",
    popupReset       = "HotsNDots: '%s' 프로필을 기본값으로 초기화할까요?",

    pageBarStyle     = "바 스타일",
    barStyleIntro    = "바의 모양입니다. 애드온 중 하나라도 LibSharedMedia를 불러왔다면 텍스처와 글꼴을 거기서 가져오므로,"
                    .. " 이미 가진 미디어 팩이 여기에 나타납니다. 없으면 작은 기본 목록을 씁니다."
                    .. " 다른 모든 설정처럼 이것도 프로필의 일부라서 전문화마다 다르게 꾸밀 수 있습니다.",
    lblPreview       = "미리보기",
    lblStyle         = "스타일",
    lblBarTexture    = "바 텍스처",
    lblFont          = "글꼴",
    lblColorDots     = "내 DoT 색상",
    lblColorHots     = "내 HoT 색상",
    previewDot       = "내 DoT",
    previewHot       = "내 HoT",

    presetDefault    = "기본",
    presetCompact    = "간결 (이름 없음)",
    presetIconRight  = "아이콘 오른쪽",
    presetNoIcon     = "아이콘 없음",
    -- ---------------- self bar page ----------------
    pageSelf         = "내 HoT",
    selfIntro        = "나 자신에게 건 내 HoT와 강화 효과를 블리자드 재사용 대기시간 관리자 스타일의 이동 가능한 아이콘 줄로 보여 줍니다:"
                    .. " 아이콘, 애니메이션, 가운데에 남은 초. 다른 모든 표시와 같은 필터를 씁니다"
                    .. " ('지속시간 없는 강화 효과 숨기기'를 켜면 영구 공격대 강화 효과는 빠집니다).",
    cbSelf           = "내 HoT 줄 표시",
    cbSelfLock       = "줄 잠금 (이동 불가)",
    cbSelfAsBars     = "바로 표시 ('바 스타일'의 모양 사용)",
    cbGrowLeft       = "왼쪽으로 쌓기",
    slSpacing        = "간격",
    btnResetPos      = "위치 초기화",
    selfHint         = "초록색 사각형을 끌어서 줄을 옮기세요. /hnd self로 켜고 끄며, /hnd lock과 /hnd unlock은 바와 이 줄에 함께 적용됩니다.",
    selfAnchorLabel  = "내 HoT \226\128\148 끌기",
    msgSelf          = "내 HoT 줄 %s",
    msgSelfLate      = "내 HoT 줄은 재시작 후에 나타납니다 - 업데이트를 마치려면 WoW를 재시작하세요.",

    on               = "켜짐",
    off              = "꺼짐",
    msgBarsLocked    = "바가 잠겼습니다.",
    msgBarsUnlocked  = "바 잠금 해제 \226\128\147 끌어서 이동하세요.",
    msgNameplates    = "이름표 아이콘 %s",
    msgBars          = "바 %s",
    msgMinimapButton = "미니맵 버튼 %s",
    msgProfileNow    = "프로필 %s.",
    msgSpecUses      = "%s: %s 사용 중.",
    msgSpecNowUses   = "%s: 이제 %s 사용.",
    msgNoSuchProfile = "'%s'(이)라는 프로필이 없습니다.",
    msgProfileList   = "프로필 (사용 중: %s)",
    msgCreated       = "%s 프로필을 만들고 %s에 적용했습니다.",
    msgNoOtherToCopy = "복사해 올 다른 프로필이 없습니다.",
    msgNothingToDel  = "삭제할 프로필이 없습니다 - Default만 있고, 그것은 남습니다.",
    msgCombat        = "전투 중에는 설정을 열 수 없습니다 \226\128\147 전투가 끝난 뒤 다시 시도하세요.",
    msgManualRoute   = "ESC > 설정 > 애드온 > HotsNDots에서 설정을 여세요.",
    msgBlocked       = "게임이 설정 창 열기를 차단했습니다 (다른 애드온이 오염시켰습니다). ",
    msgNoContainer1  = "이 클라이언트에는 AuraContainer 위젯이 없으므로 (12.1.0 필요),",
    msgNoContainer2  = "효과 표시가 꺼진 상태로 유지됩니다. 게임을 업데이트하세요.",
    msgUpdate1       = "게임 실행 중에 업데이트가 설치되었습니다.",
    msgUpdate2       = "업데이트를 마치려면 WoW를 재시작하세요 \226\128\147 /reload로는 부족합니다,",
    msgUpdate3       = "새 파일은 게임 시작 시에만 읽히기 때문입니다.",
    msgInitFailed    = "%s 실패 \226\128\147 나머지는 계속 작동합니다.",
    msgDebugHint     = "/hnd debug로 전체 메시지를 볼 수 있습니다.",
    msgProfilesLate  = "프로필이 로드되지 않았습니다 \226\128\147 업데이트를 마치려면 WoW를 재시작하세요.",

    errNeedsName     = "프로필에는 이름이 필요합니다",
    errExists        = "이미 있는 프로필입니다",
    errNoSuch        = "없는 프로필입니다",
    errDefaultKeep   = "Default 프로필은 삭제할 수 없습니다",
    errSameProfile   = "지금 사용 중인 프로필입니다",

    ttLeftSettings   = "왼쪽 클릭: 설정",
    ttRightLock      = "오른쪽 클릭: 바 잠금/해제",
    ttDrag           = "끌기: 이 버튼 이동",
    ttClickSettings  = "클릭: 설정 열기",
}

-- Simplified Chinese. "姓名板" for nameplates, "增益/减益效果" for
-- buffs/debuffs, "专精" for specialization, as the zhCN client calls them.
translations.zhCN = {
    tagline          = "只显示你自己的DoT（敌人身上）和HoT/增益效果（友方身上），显示在姓名板上，也可显示为可移动的计时条。",
    editingProfile   = "正在编辑配置文件：%s",
    profilesTabHint  = "（见HotsNDots下的“配置文件”项）",

    hdrNameplates    = "姓名板图标",
    cbNameplates     = "在姓名板上显示图标",
    cbBelow          = "显示在姓名板下方",
    cbStacks         = "显示层数（仅真实层数，2层起）",
    cbSwipe          = "显示冷却转圈动画",
    slIconSize       = "图标大小",
    slSecondsFont    = "秒数字体大小",
    slDistance       = "与姓名板的距离",
    slMaxIcons       = "最大图标数",

    hdrBars          = "计时条（可移动）",
    cbBars           = "显示计时条",
    cbLock           = "锁定计时条（不可移动）",
    cbGrowUp         = "向上增长",
    slBarWidth       = "计时条宽度",
    slBarHeight      = "计时条高度",
    slMaxBars        = "最大计时条数",
    barAnchorLabel   = "HotsNDots \226\128\148 拖动以移动",

    hdrFilters       = "过滤",
    cbShowDebuffs    = "显示减益效果（你在敌人身上的DoT）",
    cbShowBuffs      = "显示增益效果（你在友方身上的HoT）",
    cbHidePermBuffs  = "隐藏没有持续时间的增益效果",
    cbHidePermDebuffs= "隐藏没有持续时间的减益效果",
    cbHideCC         = "隐藏控制效果",

    hdrGeneral       = "常规",
    cbMinimap        = "显示小地图按钮（不随配置文件）",

    pageProfiles     = "配置文件",
    profilesIntro    = "配置文件包含过滤设置、姓名板图标、计时条以及计时条锚点的位置。"
                    .. "每个专精各选一个，所以切换专精时布局也会随之切换。"
                    .. "配置文件由你的所有角色共用；小地图按钮不在其中。",
    hdrPerSpec       = "每个专精的配置文件",
    perSpecHint      = "当前专精立即切换；其他专精在你切换过去时生效。",
    hdrManage        = "管理",
    charLine         = "角色：%s      当前专精：%s",
    activeProfile    = "当前配置文件：%s",
    btnNewProfile    = "新建配置文件",
    btnNewFromThis   = "以此为基础新建",
    btnCopyFrom      = "复制自\226\128\166",
    btnResetProfile  = "重置此配置文件",
    btnDelete        = "删除\226\128\166",
    noSpec           = "无专精",
    specNumbered     = "专精 %s",

    popupNewName     = "HotsNDots：新配置文件的名称",
    popupDelete      = "HotsNDots：删除配置文件“%s”？使用它的专精都将改回Default。",
    popupReset       = "HotsNDots：将配置文件“%s”重置为默认值？",

    pageBarStyle     = "计时条样式",
    barStyleIntro    = "计时条的外观。只要有插件加载了LibSharedMedia，材质和字体就从中获取，"
                    .. "所以你已有的媒体包会出现在这里；没有它时则使用一个小型内置列表。"
                    .. "和其他设置一样，这也是配置文件的一部分：每个专精可以有不同的外观。",
    lblPreview       = "预览",
    lblStyle         = "样式",
    lblBarTexture    = "计时条材质",
    lblFont          = "字体",
    lblColorDots     = "你的DoT颜色",
    lblColorHots     = "你的HoT颜色",
    previewDot       = "你的DoT",
    previewHot       = "你的HoT",

    presetDefault    = "默认",
    presetCompact    = "紧凑（无名称）",
    presetIconRight  = "图标在右",
    presetNoIcon     = "无图标",
    -- ---------------- self bar page ----------------
    pageSelf         = "自身HoT",
    selfIntro        = "你施加在自己身上的HoT和增益效果，以暴雪冷却管理器风格的可移动图标行显示："
                    .. "图标、转圈动画和居中的秒数。使用与其他部分相同的过滤设置"
                    .. "（“隐藏没有持续时间的增益效果”可排除你的永久团队增益）。",
    cbSelf           = "显示自身HoT图标行",
    cbSelfLock       = "锁定图标行（不可移动）",
    cbSelfAsBars     = "显示为计时条（外观取自“计时条样式”）",
    cbGrowLeft       = "向左增长",
    slSpacing        = "间距",
    btnResetPos      = "重置位置",
    selfHint         = "拖动绿色方块来移动图标行。/hnd self 开启或关闭它，/hnd lock 和 /hnd unlock 同时作用于计时条和此图标行。",
    selfAnchorLabel  = "自身HoT \226\128\148 拖动",
    msgSelf          = "自身HoT图标行%s",
    msgSelfLate      = "自身HoT图标行需重启后才会出现 - 请重启WoW以完成更新。",

    on               = "开启",
    off              = "关闭",
    msgBarsLocked    = "计时条已锁定。",
    msgBarsUnlocked  = "计时条已解锁 \226\128\147 拖动以移动。",
    msgNameplates    = "姓名板图标%s",
    msgBars          = "计时条%s",
    msgMinimapButton = "小地图按钮%s",
    msgProfileNow    = "配置文件：%s。",
    msgSpecUses      = "%s 使用 %s。",
    msgSpecNowUses   = "%s 现在使用 %s。",
    msgNoSuchProfile = "没有名为“%s”的配置文件。",
    msgProfileList   = "配置文件（当前：%s）",
    msgCreated       = "已创建 %s，并应用于 %s。",
    msgNoOtherToCopy = "没有可供复制的其他配置文件。",
    msgNothingToDel  = "没有可删除的配置文件：只有Default，而它会保留。",
    msgCombat        = "战斗中无法打开设置 \226\128\147 请在战斗结束后重试。",
    msgManualRoute   = "请通过 ESC > 选项 > 插件 > HotsNDots 打开设置。",
    msgBlocked       = "游戏阻止了打开设置面板（另一个插件污染了它）。 ",
    msgNoContainer1  = "此客户端没有AuraContainer控件（需要12.1.0），",
    msgNoContainer2  = "因此光环显示保持关闭。请更新游戏。",
    msgUpdate1       = "更新是在游戏运行时安装的。",
    msgUpdate2       = "请重启WoW以完成更新 \226\128\147 /reload 不够，",
    msgUpdate3       = "因为新文件只在启动时读取。",
    msgInitFailed    = "%s 失败 \226\128\147 其余部分继续运行。",
    msgDebugHint     = "/hnd debug 显示完整信息。",
    msgProfilesLate  = "配置文件未加载 \226\128\147 请重启WoW以完成更新。",

    errNeedsName     = "配置文件需要一个名称",
    errExists        = "该配置文件已存在",
    errNoSuch        = "没有该配置文件",
    errDefaultKeep   = "Default配置文件无法删除",
    errSameProfile   = "这就是你正在使用的配置文件",

    ttLeftSettings   = "左键点击：设置",
    ttRightLock      = "右键点击：锁定/解锁计时条",
    ttDrag           = "拖动：移动此按钮",
    ttClickSettings  = "点击：打开设置",
}

-- Traditional Chinese. "名條" for nameplates, "增益/減益效果" for
-- buffs/debuffs, "專精" for specialization, "設定檔" for profile (zhTW client).
translations.zhTW = {
    tagline          = "只顯示你自己的DoT（敵人身上）和HoT/增益效果（友方身上），顯示在名條上，也可顯示為可移動的計時條。",
    editingProfile   = "正在編輯設定檔：%s",
    profilesTabHint  = "（見HotsNDots下的「設定檔」項目）",

    hdrNameplates    = "名條圖示",
    cbNameplates     = "在名條上顯示圖示",
    cbBelow          = "顯示在名條下方",
    cbStacks         = "顯示層數（僅真實層數，2層起）",
    cbSwipe          = "顯示冷卻轉圈動畫",
    slIconSize       = "圖示大小",
    slSecondsFont    = "秒數字型大小",
    slDistance       = "與名條的距離",
    slMaxIcons       = "最大圖示數",

    hdrBars          = "計時條（可移動）",
    cbBars           = "顯示計時條",
    cbLock           = "鎖定計時條（不可移動）",
    cbGrowUp         = "向上延伸",
    slBarWidth       = "計時條寬度",
    slBarHeight      = "計時條高度",
    slMaxBars        = "最大計時條數",
    barAnchorLabel   = "HotsNDots \226\128\148 拖曳以移動",

    hdrFilters       = "過濾",
    cbShowDebuffs    = "顯示減益效果（你在敵人身上的DoT）",
    cbShowBuffs      = "顯示增益效果（你在友方身上的HoT）",
    cbHidePermBuffs  = "隱藏沒有持續時間的增益效果",
    cbHidePermDebuffs= "隱藏沒有持續時間的減益效果",
    cbHideCC         = "隱藏控場效果",

    hdrGeneral       = "一般",
    cbMinimap        = "顯示小地圖按鈕（不隨設定檔）",

    pageProfiles     = "設定檔",
    profilesIntro    = "設定檔包含過濾設定、名條圖示、計時條以及計時條錨點的位置。"
                    .. "每個專精各選一個，所以切換專精時版面也會跟著切換。"
                    .. "設定檔由你的所有角色共用；小地圖按鈕不在其中。",
    hdrPerSpec       = "每個專精的設定檔",
    perSpecHint      = "目前的專精會立即切換；其他專精在你切換過去時生效。",
    hdrManage        = "管理",
    charLine         = "角色：%s      目前專精：%s",
    activeProfile    = "使用中的設定檔：%s",
    btnNewProfile    = "新增設定檔",
    btnNewFromThis   = "以此為基礎新增",
    btnCopyFrom      = "複製自\226\128\166",
    btnResetProfile  = "重置此設定檔",
    btnDelete        = "刪除\226\128\166",
    noSpec           = "無專精",
    specNumbered     = "專精 %s",

    popupNewName     = "HotsNDots：新設定檔的名稱",
    popupDelete      = "HotsNDots：刪除設定檔「%s」？使用它的專精都會改回Default。",
    popupReset       = "HotsNDots：將設定檔「%s」重置為預設值？",

    pageBarStyle     = "計時條樣式",
    barStyleIntro    = "計時條的外觀。只要有插件載入了LibSharedMedia，材質和字型就從中取得，"
                    .. "所以你已有的媒體包會出現在這裡；沒有它時則使用一個小型內建清單。"
                    .. "和其他設定一樣，這也是設定檔的一部分：每個專精可以有不同的外觀。",
    lblPreview       = "預覽",
    lblStyle         = "樣式",
    lblBarTexture    = "計時條材質",
    lblFont          = "字型",
    lblColorDots     = "你的DoT顏色",
    lblColorHots     = "你的HoT顏色",
    previewDot       = "你的DoT",
    previewHot       = "你的HoT",

    presetDefault    = "預設",
    presetCompact    = "精簡（無名稱）",
    presetIconRight  = "圖示在右",
    presetNoIcon     = "無圖示",
    -- ---------------- self bar page ----------------
    pageSelf         = "自身HoT",
    selfIntro        = "你施放在自己身上的HoT和增益效果，以暴雪冷卻管理員風格的可移動圖示列顯示："
                    .. "圖示、轉圈動畫和置中的秒數。使用與其他部分相同的過濾設定"
                    .. "（「隱藏沒有持續時間的增益效果」可排除你的永久團隊增益）。",
    cbSelf           = "顯示自身HoT圖示列",
    cbSelfLock       = "鎖定圖示列（不可移動）",
    cbSelfAsBars     = "顯示為計時條（外觀取自「計時條樣式」）",
    cbGrowLeft       = "向左延伸",
    slSpacing        = "間距",
    btnResetPos      = "重置位置",
    selfHint         = "拖曳綠色方塊來移動圖示列。/hnd self 開啟或關閉它，/hnd lock 和 /hnd unlock 同時作用於計時條和此圖示列。",
    selfAnchorLabel  = "自身HoT \226\128\148 拖曳",
    msgSelf          = "自身HoT圖示列%s",
    msgSelfLate      = "自身HoT圖示列需重新啟動後才會出現 - 請重新啟動WoW以完成更新。",

    on               = "開啟",
    off              = "關閉",
    msgBarsLocked    = "計時條已鎖定。",
    msgBarsUnlocked  = "計時條已解鎖 \226\128\147 拖曳以移動。",
    msgNameplates    = "名條圖示%s",
    msgBars          = "計時條%s",
    msgMinimapButton = "小地圖按鈕%s",
    msgProfileNow    = "設定檔：%s。",
    msgSpecUses      = "%s 使用 %s。",
    msgSpecNowUses   = "%s 現在使用 %s。",
    msgNoSuchProfile = "沒有名為「%s」的設定檔。",
    msgProfileList   = "設定檔（使用中：%s）",
    msgCreated       = "已建立 %s，並套用於 %s。",
    msgNoOtherToCopy = "沒有可供複製的其他設定檔。",
    msgNothingToDel  = "沒有可刪除的設定檔：只有Default，而它會保留。",
    msgCombat        = "戰鬥中無法開啟設定 \226\128\147 請在戰鬥結束後再試。",
    msgManualRoute   = "請透過 ESC > 選項 > 插件 > HotsNDots 開啟設定。",
    msgBlocked       = "遊戲阻止了開啟設定面板（另一個插件汙染了它）。 ",
    msgNoContainer1  = "此用戶端沒有AuraContainer元件（需要12.1.0），",
    msgNoContainer2  = "因此光環顯示保持關閉。請更新遊戲。",
    msgUpdate1       = "更新是在遊戲執行時安裝的。",
    msgUpdate2       = "請重新啟動WoW以完成更新 \226\128\147 /reload 不夠，",
    msgUpdate3       = "因為新檔案只在啟動時讀取。",
    msgInitFailed    = "%s 失敗 \226\128\147 其餘部分繼續運作。",
    msgDebugHint     = "/hnd debug 顯示完整訊息。",
    msgProfilesLate  = "設定檔未載入 \226\128\147 請重新啟動WoW以完成更新。",

    errNeedsName     = "設定檔需要一個名稱",
    errExists        = "該設定檔已存在",
    errNoSuch        = "沒有該設定檔",
    errDefaultKeep   = "Default設定檔無法刪除",
    errSameProfile   = "這就是你正在使用的設定檔",

    ttLeftSettings   = "左鍵點擊：設定",
    ttRightLock      = "右鍵點擊：鎖定/解鎖計時條",
    ttDrag           = "拖曳：移動此按鈕",
    ttClickSettings  = "點擊：開啟設定",
}

-- Latin American Spanish is its own client locale and gets the same text:
-- nothing in here is regional, and one table cannot drift from the other.
translations.esMX = translations.esES

--------------------------------------------------------------------
-- Assemble
--  English first, then the overlay. The __index is the last line of
--  defence: a key that exists nowhere returns its own name, which is
--  ugly on screen but is a STRING - so the concatenation it sits in
--  still works, and the addon does not die over a typo in a label.
--------------------------------------------------------------------
local L = {}
for k, v in pairs(EN) do L[k] = v end

local locale = GetLocale and GetLocale() or "enUS"
local overlay = translations[locale]
if overlay then
    for k, v in pairs(overlay) do
        if type(v) == "string" and v ~= "" then L[k] = v end
    end
end

setmetatable(L, { __index = function(_, k) return tostring(k) end })

ns.L = L
ns.localeBase = EN                  -- what the tests compare against
ns.localeTables = translations
ns.locale = locale
