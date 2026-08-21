// FICHIER MORT — à supprimer.
//
// `bootstrapDependencies()` n'initialisait que Hive, dont la seule box
// ('session') n'était jamais lue : la session vit dans Firebase Auth et les
// cookies dans PersistCookieJar. Hive retiré du pubspec, la fonction n'a plus
// rien à faire. Conservé vide le temps d'un `git rm`.
