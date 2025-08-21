// Firebase configuration for web
const firebaseConfig = {
  apiKey: "AIzaSyAlg92sDvJb8xmuMt8yA9MtjbWrHMWV1oY",
  authDomain: "youvai-56995.firebaseapp.com",
  projectId: "youvai-56995",
  storageBucket: "youvai-56995.appspot.com",
  messagingSenderId: "377693730311",
  appId: "1:377693730311:web:24dfc047db461c18c3dca2"
};

// Initialize Firebase
if (typeof firebase !== 'undefined') {
  firebase.initializeApp(firebaseConfig);
  console.log('Firebase initialized successfully in web');
} else {
  console.error('Firebase SDK not loaded');
}
