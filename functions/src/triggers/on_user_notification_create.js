const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

const REGION = 'southamerica-east1';

function cleanString(value) {
    if (value === undefined || value === null) return '';
    return String(value).trim();
}

function cleanDataMap(input) {
    const output = {};

    if (!input || typeof input !== 'object') {
        return output;
    }

    for (const [key, value] of Object.entries(input)) {
        if (value === undefined || value === null) continue;

        if (typeof value === 'string') {
            output[key] = value;
            continue;
        }

        if (
        typeof value === 'number' ||
        typeof value === 'boolean' ||
        value instanceof String
        ) {
            output[key] = String(value);
            continue;
        }

        try {
            output[key] = JSON.stringify(value);
        } catch (_) {
            output[key] = String(value);
        }
    }

    return output;
}

function isInvalidTokenError(code) {
    return [
        'messaging/invalid-registration-token',
        'messaging/registration-token-not-registered',
        'messaging/invalid-argument',
    ].includes(code);
}

async function getEnabledTokens(userId) {
    const snapshot = await db
        .collection('users')
        .doc(userId)
        .collection('pushTokens')
        .where('enabled', '==', true)
        .get();

    return snapshot.docs
        .map((doc) => {
        const data = doc.data() || {};

        return {
            id: doc.id,
            ref: doc.ref,
            token: cleanString(data.token || doc.id),
            platform: cleanString(data.platform || 'unknown'),
        };
    })
        .filter((item) => item.token.length > 0);
}

async function safeUpdateNotification(ref, data) {
    try {
        await ref.set(data, { merge: true });
    } catch (error) {
        console.error('[Push] Erro ao atualizar notificação:', error);
    }
}

exports.onUserNotificationCreate = onDocumentCreated(
    {
        region: REGION,
        document: 'users/{userId}/notifications/{notificationId}',
    },
    async (event) => {
        const snapshot = event.data;

        if (!snapshot) {
            console.log('[Push] Evento sem snapshot.');
            return;
        }

        const notificationRef = snapshot.ref;
        const notification = snapshot.data() || {};

        const userId = cleanString(event.params.userId);
        const notificationId = cleanString(event.params.notificationId);

        const sendPush = notification.sendPush === true;

        if (!userId || !notificationId) {
            console.log('[Push] userId ou notificationId ausente.');
            return;
        }

        if (!sendPush) {
            console.log('[Push] Notificação sem sendPush=true. Ignorando.', {
                userId,
                notificationId,
            });
            return;
        }

        await safeUpdateNotification(notificationRef, {
            pushQueuedAt: admin.firestore.FieldValue.serverTimestamp(),
            pushStatus: 'queued',
        });

        const title = cleanString(notification.title) || 'SIPGED';

        const body =
        cleanString(notification.subtitle) ||
        cleanString(notification.details) ||
        'Você recebeu uma nova notificação.';

        const leadingLabel = cleanString(notification.leadingLabel);
        const type = cleanString(notification.type) || 'info';

        const extra = notification.extra && typeof notification.extra === 'object'
            ? notification.extra
            : {};

        const baseData = cleanDataMap({
            ...extra,
            notificationId,
            userId,
            title,
            body,
            subtitle: notification.subtitle,
            details: notification.details,
            leadingLabel,
            type,
            sendPush: true,
            saveInBell: true,
        });

        let tokenItems = [];

        try {
            tokenItems = await getEnabledTokens(userId);
        } catch (error) {
            console.error('[Push] Erro ao buscar tokens:', error);

            await safeUpdateNotification(notificationRef, {
                pushSent: false,
                pushStatus: 'token_lookup_error',
                pushAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
                pushError: `Erro ao buscar tokens: ${error.message || error}`,
            });

            return;
        }

        const tokenPlatforms = tokenItems.map((item) => item.platform);

        await safeUpdateNotification(notificationRef, {
            pushTokenCount: tokenItems.length,
            pushTokenPlatforms: tokenPlatforms,
        });

        if (tokenItems.length === 0) {
            console.log('[Push] Nenhum token ativo encontrado.', {
                userId,
                notificationId,
            });

            await safeUpdateNotification(notificationRef, {
                pushSent: false,
                pushStatus: 'no_tokens',
                pushAttemptedAt: admin.firestore.FieldValue.serverTimestamp(),
                pushError: 'Nenhum token remote ativo encontrado para o usuário.',
                pushSuccessCount: 0,
                pushFailureCount: 0,
                pushResults: [],
                pushErrors: [],
            });

            return;
        }

        const results = [];
        const errors = [];

        for (const item of tokenItems) {
            const message = {
                token: item.token,

                notification: {
                    title,
                    body,
                },

                data: baseData,

                android: {
                    priority: 'high',
                    notification: {
                        channelId: 'sipged_high_importance',
                        sound: 'default',
                        priority: 'high',
                        defaultSound: true,
                        defaultVibrateTimings: true,
                    },
                },

                apns: {
                    headers: {
                        'apns-priority': '10',
                    },
                    payload: {
                        aps: {
                            alert: {
                                title,
                                body,
                            },
                            sound: 'default',
                            badge: 1,
                            'content-available': 1,
                        },
                    },
                },

                webpush: {
                    notification: {
                        title,
                        body,
                        icon: '/icons/Icon-192.png',
                        badge: '/icons/Icon-192.png',
                    },
                    fcmOptions: {
                        link: '/',
                    },
                },
            };

            try {
                const messageId = await admin.messaging().send(message);

                results.push({
                    tokenId: item.id,
                    platform: item.platform,
                    success: true,
                    messageId,
                });

                console.log('[Push] Enviado com sucesso.', {
                    userId,
                    notificationId,
                    platform: item.platform,
                    tokenId: item.id,
                    messageId,
                });
            } catch (error) {
                const code = cleanString(error.code) || 'unknown';
                const messageText = cleanString(error.message) || String(error);

                const errorData = {
                    tokenId: item.id,
                    platform: item.platform,
                    success: false,
                    code,
                    message: messageText,
                };

                results.push(errorData);
                errors.push(errorData);

                console.error('[Push] Falha ao enviar.', {
                    userId,
                    notificationId,
                    platform: item.platform,
                    tokenId: item.id,
                    code,
                    message: messageText,
                });

                if (isInvalidTokenError(code)) {
                    await item.ref.set(
                        {
                            enabled: false,
                            disabledAt: admin.firestore.FieldValue.serverTimestamp(),
                            disabledReason: code,
                            disabledMessage: messageText,
                        },
                        { merge: true },
                    );
                }
            }
        }

        const successCount = results.where
            ? results.where((item) => item.success).length
            : results.filter((item) => item.success === true).length;

        const failureCount = errors.length;

        const sentAt = admin.firestore.FieldValue.serverTimestamp();

        await safeUpdateNotification(notificationRef, {
            pushSent: successCount > 0,
            pushSentAt: successCount > 0 ? sentAt : null,
            pushAttemptedAt: sentAt,
            pushStatus: failureCount > 0 ? 'partial_or_failed' : 'sent',
            pushSuccessCount: successCount,
            pushFailureCount: failureCount,
            pushResults: results,
            pushErrors: errors,
            pushError:
            failureCount > 0
                ? `${failureCount} falha(s), ${successCount} sucesso(s). Veja pushErrors.`
                : null,
        });

        console.log('[Push] Finalizado.', {
            userId,
            notificationId,
            total: tokenItems.length,
            successCount,
            failureCount,
            platforms: tokenPlatforms,
        });
    },
);