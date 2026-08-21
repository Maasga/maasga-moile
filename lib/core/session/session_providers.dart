import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Flux d'état d'authentification Firebase.
///
/// Vit dans `core` et non dans `features/auth` pour qu'une feature puisse lier
/// son cache à l'utilisateur courant sans dépendre d'une autre feature.
///
/// L'accès à Firebase est encapsulé dans un `try/catch` pour la même raison que
/// dans le router : les tests widget n'ont aucun binding Firebase, et sans ce
/// filet le moindre `watch` ferait échouer la construction de l'arbre.
final authUserProvider = StreamProvider<User?>((ref) {
  try {
    return FirebaseAuth.instance.authStateChanges();
  } catch (_) {
    return Stream<User?>.empty();
  }
});

/// UID de l'utilisateur connecté, `null` hors session.
///
/// **C'est la clé de cache de toutes les données propres à un compte.** Tout
/// provider qui sert des données utilisateur doit le `watch`er : Riverpod jette
/// alors sa valeur au changement de compte.
///
/// Sans cela, les `FutureProvider` — qui ne sont pas `autoDispose` — resservent
/// indéfiniment la première réponse obtenue : on se connecte avec un second
/// compte Google et l'espace client réaffiche le profil, les commandes et les
/// rendez-vous du premier.
final currentUserIdProvider = Provider<String?>((ref) {
  final snapshot = ref.watch(authUserProvider);
  // Tant que le flux n'a pas émis, on lit Firebase en direct : sans ce repli,
  // le premier build passerait pour « déconnecté » et déclencherait une requête
  // inutile, suivie d'un second fetch dès l'émission.
  if (snapshot.isLoading) return _uidSync();
  return snapshot.value?.uid;
});

String? _uidSync() {
  try {
    return FirebaseAuth.instance.currentUser?.uid;
  } catch (_) {
    return null;
  }
}
