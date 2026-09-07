/// App-wide constants.
class AppConstants {
  AppConstants._();

  // ── Firestore collection names ────────────────────────────────────
  static const usersCollection = 'users';
  static const professionalsCollection = 'professionals';
  static const serviceRequestsCollection = 'serviceRequests';
  static const chatsCollection = 'chats';
  static const messagesSubcollection = 'messages';
  static const reviewsCollection = 'reviews';
  static const categoriesCollection = 'categories';
  static const reportsCollection = 'reports';

  // ── Storage paths ─────────────────────────────────────────────────
  static const avatarsPath = 'avatars';
  static const galleryPath = 'gallery';
  static const requestsPhotosPath = 'requests';
  static const chatImagesPath = 'chats';

  // ── Limits ────────────────────────────────────────────────────────
  static const searchResultsLimit = 50;
  static const chatPageSize = 30;

  // ── Miscellaneous ─────────────────────────────────────────────────
  static const maxPhotosPerRequest = 5;
  static const maxGalleryPhotos = 20;
}
