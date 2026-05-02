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

const SIPGED_ICON = '/assets/logos/sipged/sipged.png';

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

        const icon =
        notification.icon ||
        data.icon ||
        SIPGED_ICON;

        const options = {
            body: body,
            icon: icon,
            badge: SIPGED_ICON,
            image: data.image || undefined,
            data: {
                ...data,
                route: data.route || '',
                module: data.module || '',
                contractId: data.contractId || '',
                processId: data.processId || '',
                notificationId: data.notificationId || '',
            },
        };

        self.registration.showNotification(title, options);
    });

    self.addEventListener('notificationclick', function (event) {
        event.notification.close();

        const data = event.notification && event.notification.data
            ? event.notification.data
            : {};

        const route = data.route || '';
        const module = data.module || '';
        const contractId = data.contractId || '';
        const processId = data.processId || '';
        const notificationId = data.notificationId || '';

        const url = new URL('/', self.location.origin);

        if (route) {
            url.searchParams.set('route', route);
        }

        if (module) {
            url.searchParams.set('module', module);
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
                        client.focus();

                        if ('navigate' in client) {
                            return client.navigate(url.toString());
                        }

                        return client;
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