Unit French;

Interface

Implementation

Uses Language;

Var
LId : Byte;

Begin
 LId := RegisterLanguage( 'Fran‡ais' );
 AddMsg( LId, 1, 'En train d''effacer' );
 AddMsg( LId, 2, 'En train d''‚crire' );
 AddMsg( LId, 3, 'V‚rification des donn‚es' );
 AddMsg( LId, 4, '         ERREUR DE VERIFICATION DE DONNEES DU CIRCUIT FLASH. REESSAYER [O/N]?' );
 AddMsg( LId, 5, '         ATTENTION: LES BOOTBLOCKs SONT DIFFERENTS !! CONTINUER [O,N]?' );
 AddMsg( LId, 6, 'Nom du fichier-image: ' );
 AddMsg( LId, 7, 'Cr‚ation du fichier ' );
 AddMsg( LId, 8, 'Ouverture du fichier ' );
 AddMsg( LId, 9, 'LA TAILLE DU FICHIER EST DIFFERENTE DE CELLE DU CIRCUIT FLASH ROM. CONTINUER [O,N]?' );
 AddMsg( Lid, 10, 'ATTENTION: LE BOOTBLOCK SERA MODIFIE. CONTINUER [O,N]?' );
 AddMsg( Lid, 11, 'ERREUR' );
 AddMsg( Lid, 12, 'REUSSITE' );
 AddMsg( Lid, 13, 'Nom du fichier de donn‚es ' );
 AddMsg( Lid, 14, 'Mauvaise taille du fichier - doit ˆtre de 4Ko exactement !'#7 );
 AddMsg( Lid, 15, 'Voulez vous continuer ([O]ui/[N]on)? ' );
 AddMsg( Lid, 16, 'ATTENTION: VOUS ALLEZ PERDRE TOUS LES PARAMETRES ' );
 AddMsg( Lid, 17, '. CONTINUER [O,N]?' );
 AddMsg( Lid, 18, ' : ' ); {->97}
 AddMsg( Lid, 19, 'Nom du fichier bootblock: ' );
 AddMsg( Lid, 20, 'REENREGISTRER LE BIOS DE SAUVEGARDE DANS LA FLASH ROM [O,N]?' );
 AddMsg( Lid, 21, '   ATTENTION: TOUS LES PARAMETRES DU BIOS SERONT PERDUS. CONTINUER [O,N]?' );
 AddMsg( Lid, 22, '' );  {-> 23}
 AddMsg( Lid, 23, ' OCTETS DE LA CMOS RAM EFFACES.'#7 );
 AddMsg( Lid, 24, 'ERREUR D''EFFACEMENT DES DONNEES CMOS - POSSIBILITE DE PROTECTION EN ECRITURE.'#7 );
 {25 obsolete}
 AddMsg( Lid, 26, 'ERREUR D''ECRITURE DES DONNEES CMOS - POSSIBILITE DE PROTECTION EN ECRITURE.'#7 );
 AddMsg( Lid, 27, 'REENGREGISTRER LES DONNEES CMOS PRECEDENTES [O,N]?' );
 AddMsg( Lid, 28, ' OCTETS DE LA CMOS RAM ECRITS.'#7 );
 AddMsg( Lid, 29, 'Nom de fichier manquant avec option -E' );
 AddMsg( Lid, 30, '-H or -?        Affiche cet ‚cran d''aide' );
 AddMsg( Lid, 31, '-E fname        Ecrit le bios du fichier fname dans la FLASH ROM' );
 AddMsg( Lid, 32, '                sans intervention de la part de l''utilisateur.' );
 AddMsg( Lid, 33, '-EXPERT         Donne accŠs … des fonctions plus avanc‚es' );
 AddMsg( Lid, 34, '-PCIOR          Utilise la FLASH ROM d''une carte PCI' );
 AddMsg( Lid, 35, '-DEBUG          Mode de d‚boguage. Donne des infos utiles' );
 AddMsg( Lid, 36, '-AMI            Forcer UniFlash … utiliser l''interface FLASH de AMI' );
 AddMsg( Lid, 37, 'Impossible d''acc‚der … la m‚moire au-del… de 1Mo - utilisez HIMEM.SYS.' );
 AddMsg( Lid, 38, 'Le processeur n''est pas un 486+ ou le processeur est en mode virtuel' );
 AddMsg( Lid, 39, 'S‚lectionnez une carte PCI dans cette liste:' );
 AddMsg( Lid, 40, 'Bus ' );
 AddMsg( Lid, 41, ' p‚riph‚rique ' );
 AddMsg( Lid, 42, ' fonction ' );
 AddMsg( Lid, 43, '0. Quitter' );
 AddMsg( Lid, 44, 'Votre choix: 0' );
 AddMsg( Lid, 45, 'Pas de carte PCI avec circuit (Flash) ROM d‚tect‚e.' );
 AddMsg( Lid, 46, 'Voulez-vous sauvegarder ce BIOS dans un fichier? ' );
 AddMsg( Lid, 47, 'Nom du fichier: ' );
 AddMsg( Lid, 48, '            Fait.' );
 AddMsg( Lid, 49, 'Le p‚riph‚rique PCI s‚lectionn‚ ne contient pas de FLASH ROM connue' );
 AddMsg( Lid, 50, 'Pas assez de m‚moire libre.' );
 AddMsg( Lid, 51, '           Circuit Flash ROM: ' );
 AddMsg( Lid, 52, 'INCONNU' );
 AddMsg( Lid, 53, '                Organisation: ' );
 AddMsg( Lid, 54, 'N/A' );
 AddMsg( Lid, 55, 'secteurs: ' );
 AddMsg( Lid, 56, ' pages de ' );
 AddMsg( Lid, 57, ' octets' );
 AddMsg( Lid, 58, 'bulk erase' );
 AddMsg( Lid, 59, ' secteurs de ' );
 AddMsg( Lid, 60, 'Circuit Flash inconnu !' );
 AddMsg( Lid, 61, '            Jeu de puces PCI: ' );
 AddMsg( Lid, 62, 'Etat de la derniŠre ‚criture: ' );
 AddMsg( Lid, 63, 'pas disponible' );
(* AddMsg( Lid, 64, '    Pont du sud PCI-ISA-HOST: ' );
 AddMsg( Lid, 65, 'Vendeur=' );
 AddMsg( Lid, 66, ', P‚riph‚rique=' );
 AddMsg( Lid, 67, ' … ' ); *)
 AddMsg( Lid, 68, '                     M‚moire: ' );
 AddMsg( Lid, 69, '  Addresse de base de la ROM: ' );
 AddMsg( Lid, 70, ', memory dump at ' );
 AddMsg( Lid, 71, '              Option ROM for: ' );
 AddMsg( Lid, 72, 'device at ' );
 AddMsg( Lid, 73, 'Sauvegarder l''ESCD (donn‚es PnP)' );
 AddMsg( Lid, 74, 'Flasher l''ESCD (donn‚es PnP)' );
 AddMsg( Lid, 75, 'Effacer ESCD (donn‚es PnP)' );
 AddMsg( Lid, 76, 'Sauvegarder les donn‚es DMI' );
 AddMsg( Lid, 77, 'Flasher les donn‚es DMI' );
 AddMsg( Lid, 78, 'Effacer les donn‚es DMI' );
 AddMsg( Lid, 79, 'Revenir au menu principal' );
 AddMsg( Lid, 80, 'Sauvegarder les donn‚es CMOS' );
 AddMsg( Lid, 81, 'Restaurer les donn‚es CMOS' );
 AddMsg( Lid, 82, 'Flasher le BIOS AVEC le bootblock' );
 AddMsg( Lid, 83, 'Sauvegarder le bootblock' );
 AddMsg( Lid, 84, 'Flasher le bootblock' );
 AddMsg( Lid, 85, 'Sauvegarder le BIOS sur le disque' );
 AddMsg( Lid, 86, 'Flasher le BIOS' );
 AddMsg( Lid, 87, 'Flasher le BIOS pr‚cedent' );
 AddMsg( Lid, 88, 'Effacer les donn‚es CMOS' );
 AddMsg( Lid, 89, 'R‚‚crire les pr‚c‚dentes donn‚es CMOS' );
 AddMsg( Lid, 90, 'Menu ESCD (PnP) et DMI' );
 AddMsg( Lid, 91, 'Menu avanc‚' );
 AddMsg( Lid, 92, 'Informations BIOS suppl‚mentaires' );
 AddMsg( Lid, 93, 'Quitter' );
 AddMsg( Lid, 94, 'LA DERNIERE ECRITURE A ECHOUE. QUITTER QUAND MEME [O/N]?'#7 );
 AddMsg( Lid, 95, ' impossible !'#7 ); {Last part of msg 7 & 8 !!}
 AddMsg( Lid, 96, 'Taille du fichier invalide - doit ˆtre de 8Ko exactement !'#7 );
 AddMsg( Lid, 97, 'Nom de fichier de donn‚es ' );
 AddMsg( Lid, 98, 'Taille du fichier incorrecte - doit ˆtre de ' );
 AddMsg( Lid, 99, ' octets exactement!'#7 );
 AddMsg( Lid, 100, '  Fabriquant du BIOS: ' );
 AddMsg( Lid, 101, '           ModŠle du BIOS: ' );
 AddMsg( Lid, 102, '          Num‚ro de s‚rie: ' );
 AddMsg( Lid, 103, '  ChaŒne d''identification: ' );
 AddMsg( Lid, 104, 'ChaŒne d''id du fabriquant: ' );
 AddMsg( Lid, 105, 'ON' ); {Oui Non}
 AddMsg( Lid, 106, '-FORCE option must be followed by 4 hex digits' );
 AddMsg( Lid, 107, '-CHIPLIST       Show list of supported flash chips' );
 AddMsg( Lid, 108, '-FORCE xxxx     Force using routines for chip xxxx (4 hex digits)' );
 AddMsg( Lid, 109, '-SAVE fname     Write current bios image to file fname' );
End.