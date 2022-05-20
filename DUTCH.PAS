Unit Dutch;

Interface

Implementation

Uses Language;

Var
LId : Byte;

{NOTE: GOD, I love C format strings - THIS sucks ....}

Begin
 LId := RegisterLanguage( 'Nederlands' );
 AddMsg( LId, 1, ' Bezig met wissen' );
 AddMsg( LId, 2, 'Bezig met flashen' );
 AddMsg( LId, 3, 'Controleren data' );
 AddMsg( LId, 4, 'DATA NIET CORRECT WEGGESCHREVEN. OVERNIEUW PROBEREN [J/N]?' );
 AddMsg( LId, 5, '         WARNING: BOOTBLOCK MISMATCH !! PROCEED ANYWAY [Y,N]?' );
 AddMsg( LId, 6, 'Bestandsnaam : ' );
 AddMsg( LId, 7, 'Creeren van bestand ' );
 AddMsg( LId, 8, 'Openen van bestand ' );
 AddMsg( LId, 9, 'BESTANDSGROOTTE KOMT NIET OVEREEN MET ROM. TOCH DOORGAAN [J,N]?' );
 AddMsg( Lid, 10, 'WAARSCHUWING: BOOTBLOCK WORDT GEWIJZIGD. DOORGAAN [J,N]?' );
 AddMsg( Lid, 11, 'FOUT' );
 AddMsg( Lid, 12, 'SUCCES' );
 AddMsg( Lid, 13, ' bestandsnaam: ' );
 AddMsg( Lid, 14, 'Foutieve bestandsgrootte - moet exact 4K zijn !'#7 );
 AddMsg( Lid, 15, 'Wilt u doorgaan (J/N)?' );
 AddMsg( Lid, 16, 'WAARSCHUWING: U ZAL ALLE ' );
 AddMsg( Lid, 17, ' GEGEVENS VERLIEZEN. DOORGAAN [J,N]?' );
 AddMsg( Lid, 18, ' bestandsnaam : ' );
 AddMsg( Lid, 19, 'Bootblock bestandsnaam: ' );
 AddMsg( Lid, 20, 'OUDE BIOS TERUG FLASHEN NAAR FLASH ROM CHIP [J,N]?' );
 AddMsg( Lid, 21, ' WAARSCHUWING: U ZAL ALLE BIOS INSTELLINGEN VERLIEZEN. DOORGAAN [J,N]?' );
 AddMsg( Lid, 22, 'HEB ' );
 AddMsg( Lid, 23, ' BYTES CMOS RAM GEWIST.'#7 );
 AddMsg( Lid, 24, 'FOUT BIJ HET WISSEN VAN CMOS - CMOS (GEDEELTELIJK) SCHRIJFBEVEILIGD.'#7 );
 {25 obsolete}
 AddMsg( Lid, 26, 'FOUT BIJ HET SCHRIJVEN NAAR CMOS - CMOS (GEDEELTELIJK) SCHRIJFBEVEILIGD.'#7 );
 AddMsg( Lid, 27, 'OUDE CMOS GEGEVENS TERUGSCHRIJVEN [J,N]?' );
 AddMsg( Lid, 28, ' BYTES CMOS RAM GESCHREVEN.'#7 );
 AddMsg( Lid, 29, 'Optie -E moet gevolgd worden door bestandsnaam'#7 );
 AddMsg( Lid, 30, '-H or -?        Toont dit hulp scherm' );
 AddMsg( Lid, 31, '-E bnaam        Flasht bios image vanuit bestand bnaam automatisch' );
 AddMsg( Lid, 32, '                naar de flash ROM chip zonder verdere tussenkomst' );
 AddMsg( Lid, 33, '-EXPERT         Geeft toegang tot uitgebreidere menu opties' );
 AddMsg( Lid, 34, '-PCIOR          Flash naar een optie ROM op een PCI kaart' );
 AddMsg( Lid, 35, '-DEBUG          Debugging mode. Toont meer systeem gegevens' );
 AddMsg( Lid, 36, '-AMI            Forceer het gebruik van de AMI FLASH INTERFACE' );
 AddMsg( Lid, 37, 'Kan geheugen boven de 1M niet aanspreken - probeer HIMEM.SYS.' );
 AddMsg( Lid, 38, 'Sorry, maar je hebt geen 486 of beter of de processor is in V86 Mode.' );
 AddMsg( Lid, 39, 'Kies PCI optie ROM uit de volgende lijst:' );
 AddMsg( Lid, 40, 'Bus ' );
 AddMsg( Lid, 41, ' device ' );
 AddMsg( Lid, 42, ' function ' );
 AddMsg( Lid, 43, '0. Quit' );
 AddMsg( Lid, 44, ' Keuze: 0' );
 AddMsg( Lid, 45, 'Geen PCI optie ROMs gevonden.' );
 AddMsg( Lid, 46, 'Wilt u dit BIOS naar een bestand wegschrijven? ' );
 AddMsg( Lid, 47, 'Bestandsnaam: ' );
 AddMsg( Lid, 48, '           Klaar.' );
 AddMsg( Lid, 49, 'Optie ROM van geselecteerde device is geen ondersteund Flash ROM.' );
 AddMsg( Lid, 50, 'Niet genoeg vrij geheugen' );
 AddMsg( Lid, 51, '              Flash ROM chip: ' );
 AddMsg( Lid, 52, 'ONBEKEND' );
 AddMsg( Lid, 53, '                 Organisatie: ' );
 AddMsg( Lid, 54, 'nvt' );
 AddMsg( Lid, 55, 'sectored: ' );
 AddMsg( Lid, 56, ' pagina''s van ' );
 AddMsg( Lid, 57, ' bytes' );
 AddMsg( Lid, 58, 'bulk erase' );
 AddMsg( Lid, 59, ' sectors van ' );
 AddMsg( Lid, 60, 'Onbekende flash chip !' );
 AddMsg( Lid, 61, '                 PCI chipset: ' );
 AddMsg( Lid, 62, ' Status laatste schrijfactie: ' );
 AddMsg( Lid, 63, 'niet beschikbaar' );
(* AddMsg( Lid, 64, '                South bridge: ' );
 AddMsg( Lid, 65, 'Vendor=' );
 AddMsg( Lid, 66, ', Device=' );
 AddMsg( Lid, 67, ' at ' ); *)
 AddMsg( Lid, 68, '                    Geheugen: ' );
 AddMsg( Lid, 69, '                    ROM base: ' );
 AddMsg( Lid, 70, ', geheugen dump op ' );
 AddMsg( Lid, 71, '              Optie ROM voor: ' );
 AddMsg( Lid, 72, 'device op ' );
 AddMsg( Lid, 73, 'Schrijf ESCD blok (PnP gegevens) naar schijf' );
 AddMsg( Lid, 74, 'Flash ESCD blok (PnP gegevens) naar Flash ROM' );
 AddMsg( Lid, 75, 'Wis ESCD blok (PnP data)' );
 AddMsg( Lid, 76, 'Schrijf DMI gegevensblok naar disk' );
 AddMsg( Lid, 77, 'Flash DMI gegevensblok naar Flash ROM' );
 AddMsg( Lid, 78, 'Wis DMI gegevensblok' );
 AddMsg( Lid, 79, 'Terug naar hoofdmenu' );
 AddMsg( Lid, 80, 'Schrijf CMOS gegevens naar schrijf' );
 AddMsg( Lid, 81, 'Lees CMOS gegevens van schijf' );
 AddMsg( Lid, 82, 'Flash BIOS INCLUSIEF bootblock' );
 AddMsg( Lid, 83, 'Schrijf bootblock naar schijf' );
 AddMsg( Lid, 84, 'Flash bootblock naar Flash ROM' );
 AddMsg( Lid, 85, 'Schrijf oude BIOS naar schijf' );
 AddMsg( Lid, 86, 'Flash BIOS naar Flash ROM' );
 AddMsg( Lid, 87, 'Flash oude BIOS terug naar Flash ROM' );
 AddMsg( Lid, 88, 'Wis CMOS gegevens' );
 AddMsg( Lid, 89, 'Schrijf oude CMOS gegevens terug naar CMOS' );
 AddMsg( Lid, 90, 'ESCD (PnP) en DMI submenu' );
 AddMsg( Lid, 91, 'Geavanceerde opties submenu' );
 AddMsg( Lid, 92, 'Additionele BIOS informatie' );
 AddMsg( Lid, 93, 'Verlaat UNIFLASH' );
 AddMsg( Lid, 94, 'LAATSTE SCHRIJFOPERATIE NAAR FLASHROM WAS ONSUCCESVOL. TOCH VERLATEN [J/N]?'#7 );
 AddMsg( Lid, 95, ' niet gelukt !'#7 );  {Last part of msg 7 & 8 !!!!}
 AddMsg( Lid, 96, 'Foutieve bestandsgrootte - moet exact 8K zijn !'#7 );
 AddMsg( Lid, 97, '' ); {->18}
 AddMsg( Lid, 98, 'Foutieve bestandsgrootte - moet exact ' );
 AddMsg( Lid, 99, ' bytes zijn !'#7 );
 AddMsg( Lid, 100, 'BIOS Mfg: ' );
 AddMsg( Lid, 101, '   BIOS Model: ' );
 AddMsg( Lid, 102, '  Part number: ' );
 AddMsg( Lid, 103, '    Id string: ' );
 AddMsg( Lid, 104, 'Mfg id string: ' );
 AddMsg( Lid, 105, 'JN' );   {Ja Nee}
 AddMsg( Lid, 106, 'Na -FORCE optie moeten 4 hex. karakters volgen' );
 AddMsg( Lid, 107, '-CHIPLIST       Toon lijst met ondersteunde flash chips' );
 AddMsg( Lid, 108, '-FORCE xxxx     Doe net alsof chip xxxx (4 hex cijfers) is gevonden' );
 AddMsg( Lid, 109, '-SAVE bnaam     Schrijf huidige bios image naar bestand bnaam' );
End.