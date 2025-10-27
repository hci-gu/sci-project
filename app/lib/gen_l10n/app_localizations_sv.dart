// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appName => 'RullaPå';

  @override
  String get redirecting => 'Omdirigerar...';

  @override
  String get authenticating => 'Autentiserar...';

  @override
  String get abort => 'Avbryt';

  @override
  String get watchSyncLoginRequired =>
      'Du måste vara inloggad för att synka med din klocka.';

  @override
  String get watchSyncInvalidFitbitInfo =>
      'Fick ogiltig information från Fitbit-appen.';

  @override
  String get forcedLoginFailed =>
      'Misslyckades med att logga in med angivna uppgifter.';

  @override
  String get missingUserIdOrApiKey =>
      'Saknar userId eller apiKey parametrar.';

  @override
  String get noWatchConnected => 'Ingen klocka ansluten';

  @override
  String get confirmDisconnectWatchTitle => 'Är du säker?';

  @override
  String get disconnectWatchConfirmation =>
      'Att koppla från klockan stoppar alla inspelningar och tar bort anslutningen. Vill du fortsätta?';

  @override
  String get watchDisconnected => 'Klockan kopplades från';

  @override
  String get disconnect => 'Koppla från';

  @override
  String get refresh => 'Uppdatera';

  @override
  String lastSynced(Object time) {
    return 'Senast synkad: $time';
  }

  @override
  String get never => 'Aldrig';

  @override
  String get bluetoothOff => 'Bluetooth är av';

  @override
  String get recordingInProgress => 'Spelar in...';

  @override
  String get connected => 'Ansluten';

  @override
  String get disconnected => 'Frånkopplad';

  @override
  String get syncInstructions => 'Tryck på synkknappen för att ladda upp din data';

  @override
  String get sync => 'Synka';

  @override
  String get syncSuccess => 'Inspelningarna synkroniserades!';

  @override
  String get syncNoData => 'Inga inspelningar hittades att synka.';

  @override
  String get searchingForWatches => 'Söker efter klockor...';

  @override
  String get noDevicesFound => 'Inga enheter hittades.';

  @override
  String get searching => 'Söker...';

  @override
  String get searchAgain => 'Sök igen';

  @override
  String get connect => 'Anslut';

  @override
  String get unknownDevice => 'Okänd';

  @override
  String get connectWatchPrompt => 'Anslut din klocka för att komma igång!';

  @override
  String get connectWatch => 'Anslut klocka';

  @override
  String get generatedImageTitle => 'Genererad bild';

  @override
  String get noImageFromServer => 'Ingen bild returnerades från servern.';

  @override
  String get generatingImage => 'Genererar bild…';

  @override
  String get failedToLoadImage => 'Kunde inte ladda bilden';

  @override
  String get tryAgain => 'Försök igen';

  @override
  String get error => 'Fel';

  @override
  String get kcal => 'kcal';

  @override
  String get login => 'Logga in';

  @override
  String get register => 'Registrera';

  @override
  String get email => 'Email';

  @override
  String get password => 'Lösenord';

  @override
  String get verifyPassword => 'Verifiera lösenord';

  @override
  String get forgotPassword => 'Glömt lösenord?';

  @override
  String get skip => 'Hoppa över';

  @override
  String get next => 'Nästa';

  @override
  String get finish => 'Avsluta';

  @override
  String get today => 'Idag';

  @override
  String get yesterday => 'Igår';

  @override
  String get day => 'Dag';

  @override
  String get week => 'Vecka';

  @override
  String get month => 'Månad';

  @override
  String get quarter => 'Kvartal';

  @override
  String get year => 'År';

  @override
  String get logout => 'Logga ut';

  @override
  String get from => 'Från';

  @override
  String get last => 'Förra';

  @override
  String get createAccount => 'Skapa konto';

  @override
  String get deleteAccount => 'Radera konto';

  @override
  String get deleteAccountConfirmation =>
      'Är du säker att du vill radera ditt konto? Du kan inte ångra dig och din data försvinner efter du har raderat ditt konto.';

  @override
  String get close => 'Stäng';

  @override
  String get cancel => 'Avbryt';

  @override
  String get save => 'Spara';

  @override
  String get saved => 'Sparad';

  @override
  String get about => 'Om';

  @override
  String get total => 'Total';

  @override
  String get average => 'Genomsnitt';

  @override
  String get side => 'Sida';

  @override
  String get right => 'Höger';

  @override
  String get left => 'Vänster';

  @override
  String get comment => 'Kommentar';

  @override
  String get optional => 'Valfri';

  @override
  String get add => 'Lägg till';

  @override
  String get select => 'Välj';

  @override
  String get genericError => 'Något gick fel';

  @override
  String get connectionTimeout =>
      'Kunde inte ansluta till servern, försök igen senare.';

  @override
  String get connectionError =>
      'Kunde inte ansluta, kontrollera din internetanslutning.';

  @override
  String get update => 'Uppdatera';

  @override
  String get updated => 'Uppdaterad';

  @override
  String get home => 'Hem';

  @override
  String get noData => 'Ingen data';

  @override
  String get all => 'Alla';

  @override
  String get change => 'Ändra';

  @override
  String get remove => 'Ta bort';

  @override
  String get removeConfirmation => 'Är du säker på att du vill ta bort detta?';

  @override
  String get goodWork => 'Bra jobbat!';

  @override
  String get back => 'Tillbaka';

  @override
  String get start => 'Starta';

  @override
  String get pause => 'Pausa';

  @override
  String get pushNotifications => 'Pushnotiser';

  @override
  String get getStarted => 'Sätt igång';

  @override
  String get seconds => 'sekunder';

  @override
  String get pickANumber => 'Välj ett nummer';

  @override
  String get other => 'Annat';

  @override
  String get yes => 'Ja';

  @override
  String get no => 'Nej';

  @override
  String get monday => 'Måndag';

  @override
  String get tuesday => 'Tisdag';

  @override
  String get wednesday => 'Onsdag';

  @override
  String get thursday => 'Torsdag';

  @override
  String get friday => 'Fredag';

  @override
  String get saturday => 'Lördag';

  @override
  String get sunday => 'Söndag';

  @override
  String get pushPermissionsErrorMessage =>
      'Du måste slå på notifikationer i telefonens appinställningar.';

  @override
  String get watchSettings => 'Klockinställningar';

  @override
  String get paraplegic => 'Paraplegiker';

  @override
  String get tetraplegic => 'Tetraplegiker';

  @override
  String get sedentary => 'Stillasittande';

  @override
  String get movement => 'Rörelse';

  @override
  String get active => 'Aktiv';

  @override
  String get activity => 'Aktivitet';

  @override
  String get weights => 'Vikter';

  @override
  String get skiErgo => 'Ski ergometer';

  @override
  String get armErgo => 'Armcykel';

  @override
  String get rollOutside => 'Rulla ute träning ( eller annat )';

  @override
  String get calories => 'Kalorier';

  @override
  String get workout => 'Träningspass';

  @override
  String get injury => 'Skada';

  @override
  String get weight => 'Vikt';

  @override
  String get gender => 'Kön';

  @override
  String get bodyPart => 'Kroppsdel';

  @override
  String get bodyPartNeck => 'Nacke';

  @override
  String get bodyPartBack => 'Rygg';

  @override
  String get bodyPartScapula => 'Skulderblad';

  @override
  String get bodyPartShoulderJoint => 'Axelled';

  @override
  String get bodyPartElbow => 'Armbåge';

  @override
  String get bodyPartHand => 'Hand';

  @override
  String get arm => 'Arm';

  @override
  String get condition => 'Tillstånd';

  @override
  String get injuryLevel => 'Skadenivå';

  @override
  String get gear => 'Utrustning';

  @override
  String get medicin => 'Medicin';

  @override
  String get introductionScreenHeader => 'Spåra din rörelse';

  @override
  String get introductionWelcome => 'Välkommen till RullaPå-appen!';

  @override
  String get registerDataTitle => 'Hur appen använder din data';

  @override
  String get registerDataDescription =>
      'Det sker inte någon automatisk insamling av data i appen. Allt som loggas är det du själv gör genom \"Loggboken\" samt genvägarna som finns på hemskärmen. All data är synlig i din Loggbok.';

  @override
  String get registerDataDeletion =>
      'Om du väljer att radera ditt konto så försvinner även all data kopplad till kontot.';

  @override
  String get registerProceed => 'Vill du fortsätta?';

  @override
  String get intro => 'Intro';

  @override
  String get onboardingTitle => 'Välkommen till RullaPå';

  @override
  String get onboardingIntro =>
      'Hej och välkommen till RullaPå, den här guiden kommer att visa vad det finns för funktioner.\n\nDu kan välja om du är intresserad av att använda de eller inte, om du väljer bort en funktion så syns inte den på hemskärmen. Du kan alltid ångra dig genom att göra om det här från inställningarna i appen.\n\n Tryck på \"Nästa\" för att gå vidare.';

  @override
  String get watchFunctions => 'Klockfunktioner';

  @override
  String get onboardingWantFunctions => 'Jag vill ha dessa funktioner';

  @override
  String get onboardingWatchRequirement =>
      '* Du behöver en Fitbit ( Versa 2/3 eller Sense 1/2 )';

  @override
  String get onboardingNotInterested => 'Inte intresserad';

  @override
  String get onboardingDontHaveWatch => 'Har inte en klocka';

  @override
  String get onboardingCaloriesDescription =>
      'Här visas en uppskattning av din dagliga energiförbrukning (kalorier) du. Du kan även  jämföra med en genomsnittlig dag under senaste veckan.';

  @override
  String get onboardingSedentaryDescription =>
      'Här får du information om hur länge du sitter still sammanlagt under en dag, hur ofta du bryter upp ditt stillasittande samt hur länge du sitter still innan du är aktiv.';

  @override
  String get onboardingMovementDescription =>
      'Här visas hur länge och när du är fysiskt  aktiv, beskrivet som låg, medlel och hög intensitet';

  @override
  String get onboardingPressureReleaseAndUlcerTitle => 'Trycksår & avlastning';

  @override
  String get onboardingPressureReleaseDescription =>
      'Här får du information om hur ofta du har tryckavlastat samt hur länge du suttit still mellan dina tryckavlastningar. Du kan även ställa in hur många gånger under dagen som du skall påminnas.';

  @override
  String get onboaridngPressureUlcerDescription =>
      'Här kan du registrera placering, grad samt fotografera utbredningen av trycksår för att kunna följa utvecklingen av ditt trycksår.';

  @override
  String get onboardingPainFeature => 'Logga din smärta';

  @override
  String get onboardingPainDescription =>
      'Här kan du registrera vart du har smärta samt vilken nivå av smärta du har just idag.';

  @override
  String get onboardingNeuropathicPainDescription =>
      'Ställ in din nivå för smärta vid/under skada, intermittent smärta eller allodyni.';

  @override
  String get onboardingSpasticityDescription =>
      'Ställ in din spasticitetsnivå.';

  @override
  String get onboardingPushDescription =>
      'För att kunna få påminnelser eller rekommendationer genom pushnotiser så behöver du ge ditt godkännande att appen ska få skicka pushnotiser till dig.';

  @override
  String get onboardingActivatePush => 'Aktivera pushnotiser';

  @override
  String get onboardingSettingsInfo =>
      'Du kan när som helst ändra dina inställningar i appen.';

  @override
  String get onboardingBladderAndBowelFunctions => 'Blåsa & tarm';

  @override
  String get onboardingUtiDescription =>
      'Registrera om du har en urinvägsinfektion eller inte.';

  @override
  String get onboardingBladderEmptyingDescription =>
      'Här kan du registrera hur ofta du har tömmer blåsan och få påminnelser om när det är dags att tömma blåsan.';

  @override
  String get onboardingLeakageDescription => 'Registrera när du har läckage.';

  @override
  String get profile => 'Profil';

  @override
  String get appSettings => 'App inställningar';

  @override
  String get notifications => 'Notifikationer';

  @override
  String get enableDisableFeatures => 'Aktivera/inaktivera funktioner';

  @override
  String get language => 'Språk';

  @override
  String get editProfile => 'Redigera profil';

  @override
  String get redoIntro => 'Gör om intro';

  @override
  String get showLicenses => 'Visa licenser';

  @override
  String get userId => 'AnvändarID';

  @override
  String get userIdCopyMessage => 'AnvändarID kopierat till urklipp';

  @override
  String get movementReminders => 'Rörelsepåminnelser';

  @override
  String get logbookReminders => 'Loggbokspåminnelser';

  @override
  String get noDataWarning => 'Ingen data varning';

  @override
  String get aboutCalories =>
      'Här visas en uppskattningen av din dagliga energiförbrukning (kalorier) vilket sker genom att aktivitetsarmbandet (klockan) registrerar rörelsen från accelerometern och hjärtfrekvensen kontinuerligt. Informationen från aktivitetsarmbandet samt information om skadenivå, kön och kroppsvikt används för att beräkna energiförbrukning samt aktivitetsnivå (intensitet).';

  @override
  String get aboutSedentary =>
      'Här visas en uppskattning av den totala tid - fördelat över dagen - du sitter still och arbetar, tittar på TV, läser eller äter.';

  @override
  String get aboutMovement =>
      'Här visas en uppskattning av din dagliga aktivitet. Rörelse (lågintensiv aktivitet, blå). Består av aktiviteter som upplevs som lätt ansträngning och kan beskrivas som 20 - 45% av en individs maximal kapacitet.\nAktivitet (Medel till hög intensiv aktivitet, grön). Består av aktiviteter som upplevs som något ansträngande till ansträngande och mycket ansträngande. Dessa kan beskrivas som medel 46 - 63% och hög 54 - 90% av maximal intensitet.\n\nAktivitetsnivån är baserad på procent (%) av maximal kapacitet (relativ intensitet), detta gör att samma aktivitet kan uppfattas olika anstränga hos olika individer.';

  @override
  String get dateAndTime => 'Datum och tid';

  @override
  String get journalNoData => 'Du har ingen data för den här perioden';

  @override
  String get journalWelcome => 'Välkommen till loggboken';

  @override
  String get journalWelcomeDescription =>
      'Här kan du få en överblick över vad du har loggat och skapa nya poster, tryck på knappen nedan för att komma igång.';

  @override
  String get logbook => 'Loggbok';

  @override
  String get listEntries => 'Lista inlägg';

  @override
  String get listEntriesDescription => 'Se/redigera dina inlägg';

  @override
  String get addBodyPart => 'Lägg till kroppsdel';

  @override
  String get newEntry => 'Ny registrering';

  @override
  String get journalCategoriesTitle => 'Vad vill du registrera?';

  @override
  String get journalCategoriesDescription =>
      'Välj en utav de kategorier du ser nedanför';

  @override
  String get journalShortcutDescription =>
      'Tryck på en knapp nedan för att skapa nytt inlägg inom samma kategori.';

  @override
  String get pain => 'Smärta';

  @override
  String get painAndDiscomfort => 'Smärta & besvär';

  @override
  String get painAndDiscormfortEmpty =>
      'Logga neuropatisk smärta eller spasticitet för att se det här.';

  @override
  String get painAndDiscormfortEmptyButton => 'Gå till loggbok';

  @override
  String get neuropathic => 'Neuropatisk';

  @override
  String get neuropathicPain => 'Neuropatisk smärta';

  @override
  String get typeOfPain => 'Typ av smärta';

  @override
  String get belowOrAt => 'Smärta ( under / i )';

  @override
  String get intermittent => 'Intermittent';

  @override
  String get allodynia => 'Allodyni';

  @override
  String get musclePainTitle => 'Smärta i muskler & leder';

  @override
  String get musclePainSubtitle => 'Från muskler och leder';

  @override
  String get trackPain => 'Spåra smärta';

  @override
  String get trackPainDescription =>
      'Tryck på en kroppsdel för att lägga till en ny smärtupplevelse.';

  @override
  String get trackPainEmpty =>
      'Lägg till en kroppsdel för att börja spåra din smärta.';

  @override
  String get painLevel => 'Smärtnivå';

  @override
  String get painLevelHelper => 'Välj ett nummer mellan 1-10';

  @override
  String get painCommentPlaceholder => 'Skriv en kommentar';

  @override
  String get painCommentHelper =>
      'Beskriv hur du mår, vad du har gjort, hur du har sovit etc.';

  @override
  String get exercise => 'Träning';

  @override
  String get newExercise => 'Nytt träningspass';

  @override
  String get startTime => 'Starttid';

  @override
  String get exerciseActivityDescription =>
      'Vad för typ av träning har du gjort?';

  @override
  String get duration => 'Längd';

  @override
  String get exerciseLengthDescription => 'Hur länge har du tränat?';

  @override
  String get pressureRelease => 'Tryckavlastning';

  @override
  String get pressureReleases => 'Tryckavlastningar';

  @override
  String get pressureReleaseNow => 'Tryckavlasta nu';

  @override
  String get pressureReleaseSelectExercises => 'Välj övningar';

  @override
  String get pressureReleaseSelectExercisesDescription =>
      'Tänk på att fullständing tryckavlastning ger bäst resultat.';

  @override
  String get pressureReleaseCreateGoal => 'Skapa ett mål för tryckavlastning';

  @override
  String get pressureReleaseAlreadyDone => 'Jag har redan tryckavlastat';

  @override
  String get pressureReleaseTimeToDoIt => 'Dags att avlasta';

  @override
  String get holdPositionFor => 'Håll positionen i';

  @override
  String get pressureReleaseSittingExercises => 'Sittande övningar';

  @override
  String get pressureReleaseExerciseLying => 'Liggande';

  @override
  String get pressureReleaseExerciseLyingDescription =>
      'Liggandes på magen eller sidan';

  @override
  String get pressureReleaseExerciseLeanForward => 'Framåtlutad';

  @override
  String get pressureReleaseExerciseLeanForwardDescription =>
      'Luta överkroppen framåt så att magen vilar mot låren eller mot ett bord';

  @override
  String get pressureReleaseExerciseLeanLeft => 'Sidolutning vänster';

  @override
  String get pressureReleaseExerciseLeanLeftDescription =>
      'Luta överkroppen mot vänster armstöd eller mot ett bord';

  @override
  String get pressureReleaseExerciseLeanRight => 'Sidolutning höger';

  @override
  String get pressureReleaseExerciseLeanRightDescription =>
      'Luta överkroppen mot höger armstöd eller mot ett bord';

  @override
  String get urinaryTractInfection => 'Urinvägsinfektion';

  @override
  String get utiTypeNone => 'Ingen infektion';

  @override
  String get utiTypeFeeling => 'Känning';

  @override
  String get utiTypeDiagnosed => 'Diagnostiserad';

  @override
  String get utiTypeNoneDescription =>
      'Du har inga symptom för en urinvägsinfektion.';

  @override
  String get utiTypeFeelingDescription =>
      'Du misstänker att du har en urinvägsinfektion.';

  @override
  String get utiTypeDiagnosedDescription =>
      'Du har fått en diagnos på att du har en urinvägsinfektion.';

  @override
  String get utiTypeHint => 'Välj ett alternativ';

  @override
  String get utiChangeStatus => 'Ändra status på urinvägsinfektion';

  @override
  String get noUti => 'Ingen UVI';

  @override
  String get noLoggedUti => 'Ingen loggad UVI';

  @override
  String get urine => 'Urin';

  @override
  String get urineTypeHint => 'Välj det alternativ som beskriver urinet.';

  @override
  String get bladderEmptying => 'Blåstömning';

  @override
  String get bladderEmptyings => 'Blåstömningar';

  @override
  String get bladderEmptyingCreateGoal => 'Sätt ett mål för blåstömning';

  @override
  String get bladderEmptyingTimeToDoIt => 'Dags för blåstömning';

  @override
  String get urineTypeNormal => 'Normalt';

  @override
  String get urineTypeCloudy => 'Grumligt/Mjölkigt';

  @override
  String get urineTypeBlood => 'Blod i urinet';

  @override
  String get urineSmellTitle => 'Luktar det?';

  @override
  String get urineSmellDescription => 'Lukt kan vara ett tecken på infektion.';

  @override
  String get urineSmellNo => 'Nej det luktar inte';

  @override
  String get urineSmellYes => 'Ja det luktar';

  @override
  String get leakage => 'Läckage';

  @override
  String get bowel => 'Tarm';

  @override
  String get bowelEmptying => 'Tarmtömning';

  @override
  String get stoolType => 'Avföringstyp';

  @override
  String get stoolTypeHint => 'Välj en avföringstyp';

  @override
  String get stoolType1 => 'Svår förstoppning';

  @override
  String get stoolType2 => 'Förstoppning';

  @override
  String get stoolType3 => 'Fast';

  @override
  String get stoolType4 => 'Normal';

  @override
  String get stoolType5 => 'Saknar form';

  @override
  String get stoolType6 => 'Mild diarré';

  @override
  String get stoolType7 => 'Svår diarré';

  @override
  String get stoolType1Description =>
      'Separata hårda klumpar som liknar nötter';

  @override
  String get stoolType2Description => 'Korvformad med klumpar';

  @override
  String get stoolType3Description => 'Liknar en korv med sprickor på ytan';

  @override
  String get stoolType4Description => 'Liknar en korv, smidig och mjuk';

  @override
  String get stoolType5Description => 'Mjuka klumpar med skarpa kanter';

  @override
  String get stoolType6Description => 'Småbitar med mjuk konsistens';

  @override
  String get stoolType7Description => 'Vattnig utan klumpar, enbart vätska';

  @override
  String get goal => 'Mål';

  @override
  String get goalPressureRelease => 'Sätt ditt dagliga mål för avlastning';

  @override
  String get goalBladderEmptying => 'Sätt ditt dagliga mål för blåstömning';

  @override
  String get goalTimePerDay => 'Hur många gånger per dag?';

  @override
  String get bladderGoalTimePerDayDescription =>
      'Det är rekommenderat att tappa 4-8 gånger om dagen.';

  @override
  String get goalTimePerDayDescription => 'Vi rekommenderar 8 gånger om dagen.';

  @override
  String get goalStart => 'Vilken tid på dagen vill du börja?';

  @override
  String get goalStartDescription =>
      'T.ex. en timme efter att du brukar vakna.';

  @override
  String get ofDailyGoal => 'av dagliga målet';

  @override
  String get createYourGoal => 'Skapa ditt mål';

  @override
  String get leftToReachGoalMessage => 'kvar för att nå ditt dagliga mål.';

  @override
  String get reachedGoalMessage => 'Du har nått ditt dagliga mål!';

  @override
  String get editGoal => 'Ändra mål';

  @override
  String get pressureUlcer => 'Trycksår';

  @override
  String get pressureUlcers => 'Trycksår';

  @override
  String get noLoggedPressureUlcer => 'Inget loggat trycksår';

  @override
  String get pressureUlcerChangeStatus => 'Ändra status på trycksår';

  @override
  String get pressureUlcerAdd => 'Lägg till trycksår';

  @override
  String get pressureUlcerViewHistory => 'Se trycksårshistorik';

  @override
  String get pressureUlcerClassification => 'Trycksårsklassificering';

  @override
  String get pressureUlcerClassificationDescription =>
      'Välj den kategori av skada som ditt trycksår har nu.';

  @override
  String get pressureUlcerClassificationHint => 'Välj kategori';

  @override
  String get pressureUlcerLocation => 'Var är ditt sår någonstans?';

  @override
  String get pressureUlcerLocationDescription =>
      'Välj den plats på kroppen där ditt trycksår finns.';

  @override
  String get pressureUlcerLocationHint => 'Välj en plats';

  @override
  String get selectInjuryLevel => 'Välj skadenivå';

  @override
  String get noPressureUlcer => 'Inget trycksår';

  @override
  String get pressureUlcerCategory1 => 'Rodnad';

  @override
  String get pressureUlcerCategory2 => 'Ytligt sår';

  @override
  String get pressureUlcerCategory3 => 'Öppet sår';

  @override
  String get pressureUlcerCategory4 => 'Djupt öppet sår';

  @override
  String get noPressureUlcerDescription => 'Trycksåret har läkt';

  @override
  String get pressureUlcerCategory1Description =>
      'Rodnad som inte bleknar vid tryck';

  @override
  String get pressureUlcerCategory2Description =>
      'Delhudsskada, blåsa, spricka, avskavd hud';

  @override
  String get pressureUlcerCategory3Description => 'Öppen hud med liten grop';

  @override
  String get pressureUlcerCategory4Description =>
      'Ett öppet djupt sår där ben, senor och muskler kan vara synliga';

  @override
  String get ancle => 'Ankel';

  @override
  String get heel => 'Häl';

  @override
  String get insideKnee => 'Insida knä';

  @override
  String get hip => 'Höft';

  @override
  String get sitBones => 'Sittben';

  @override
  String get sacrum => 'Sakrum';

  @override
  String get scapula => 'Skulderblad';

  @override
  String get shoulder => 'Axel';

  @override
  String get spasticity => 'Spasticitet';

  @override
  String get spasticityLevel => 'Spasticitetsnivå';

  @override
  String get spasticityLevelDescription => 'Välj en nivå mellan 1-10';
}
