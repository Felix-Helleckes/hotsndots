--=====================================================================
--  HotsNDots - Locale
--  English, German, French, Spanish. The client's own language decides;
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
