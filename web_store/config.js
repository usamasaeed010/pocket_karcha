// Public Firebase config for the customer order page.
//
// From the Web app "Pocket Karcha order page" (registered 2026-11-24). Firebase
// API keys are not secrets: they only identify the project. Access is
// controlled by firestore.rules (and App Check, once enforced).
window.PK_CONFIG = {
  firebase: {
    apiKey: 'AIzaSyBpqzf5buCxZ5fQWD51tMSpvjcm0V1AKVQ',
    authDomain: 'pocket-karcha-new.firebaseapp.com',
    projectId: 'pocket-karcha-new',
    appId: '1:367191218212:web:0de2b26981438b973b20b1',
    messagingSenderId: '367191218212',
  },
  // reCAPTCHA Enterprise site key (public) for App Check. Empty = App Check off.
  appCheckSiteKey: '6Lfjwi8uAAAAAFNom0VVTuzUyX8PVVST7uinUdi4',
  // A shop's own Hosting site opens that shop at its root (sites are listed
  // in firebase.json; the app shows the same links in AppUrls).
  siteShops: {
    'chill-n-chaat.web.app': 'chill-n-chaat',
    'chill-n-chaat.firebaseapp.com': 'chill-n-chaat',
  },
  playStoreUrl:
    'https://play.google.com/store/apps/details?id=com.pocket.karcha.expense.manager',
};
