// web/firebase-messaging-sw.js

/* eslint-disable no-undef */
/* eslint-disable no-restricted-globals */

importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/9.23.0/firebase-messaging-compat.js');

const firebaseConfig = {
    apiKey: 'AIzaSyDZh7jcJNO0XEW2eCXecWq3MdTvRFPzHJk',
    authDomain: 'sisgeoderal.firebaseapp.com',
    projectId: 'sisgeoderal',
    storageBucket: 'sisgeoderal.appspot.com',
    messagingSenderId: '769410863294',
    appId: '1:769410863294:web:a51d56dfd32369dd4b0eef',
};

try {
    firebase.initializeApp(firebaseConfig);

    const messaging = firebase.messaging();

    messaging.onBackgroundMessage((payload) => {
        console.log('[firebase-messaging-sw.js] Background message:', payload);

        const data = payload && payload.data ? payload.data : {};
        const notification = payload && payload.notification ? payload.notification : {};

        const title =
        notification.title ||
        data.title ||
        'SIPGED';

        const body =
        notification.body ||
        data.body ||
        data.subtitle ||
        data.details ||
        'Você recebeu uma nova notificação.';

        const options = {
            body: body,
            icon: '/icons/Icon-192.png',
            badge: '/icons/Icon-192.png',
            data: data,
        };

        self.registration.showNotification(title, options);
    });

    self.addEventListener('notificationclick', function (event) {
        event.notification.close();

        const data = event.notification && event.notification.data
            ? event.notification.data
            : {};

        const route = data.route || '';
        const contractId = data.contractId || '';
        const processId = data.processId || '';
        const notificationId = data.notificationId || '';

        const url = new URL('/', self.location.origin);

        if (route) {
            url.searchParams.set('route', route);
        }

        if (contractId) {
            url.searchParams.set('contractId', contractId);
        }

        if (processId) {
            url.searchParams.set('processId', processId);
        }

        if (notificationId) {
            url.searchParams.set('notificationId', notificationId);
        }

        event.waitUntil(
            clients.matchAll({
                type: 'window',
                includeUncontrolled: true,
            }).then(function (clientList) {
                for (let i = 0; i < clientList.length; i++) {
                    const client = clientList[i];

                    if ('focus' in client) {
                        return client.focus();
                    }
                }

                if (clients.openWindow) {
                    return clients.openWindow(url.toString());
                }

                return null;
            }),
        );
    });

    console.log('[firebase-messaging-sw.js] Service Worker carregado com sucesso.');
} catch (error) {
    console.error('[firebase-messaging-sw.js] Erro ao inicializar:', error);
}