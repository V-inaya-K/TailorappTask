importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: "AIzaSyCDZg8zwDcxvZvJEeFSt0Bp-hmqliUrQqo",
  authDomain: "interntask-190da.firebaseapp.com",
  projectId: "interntask-190da",
  storageBucket: "interntask-190da.firebasestorage.app",
  messagingSenderId: "1054135743627",
  appId: "1:1054135743627:web:6da5600aece974678dd08e"
});

const messaging = firebase.messaging();
