// functions/src/triggers/on_user_notification_create.js

const admin = require('firebase-admin');
const { onDocumentCreated } = require('firebase-functions/v2/firestore');

if (!admin.apps.length) {
    admin.initializeApp();
}

const db = admin.firestore();

const REGION = 'southamerica-east1';
const FCM_BATCH_LIMIT = 500;

function cleanString(value) {
    if (value === undefined || value === null) return '';
    return String(value).trim();
}

function cleanDataMap(input) {
    const output = {};

    if (!input || typeof input !== 'object') {
        return output;
    }

    for (const [rawKey, rawValue] of Object.entries(input)) {
        const key = cleanString(rawKey);

        if (!key) continue;
        if (rawValue === undefined || rawValue === null) continue;

        if (typeof rawValue === 'string') {
            const value = rawValue.trim();

            if (value) {
                output[key] = value;
            }

            continue;
        }

        if (
        typeof rawValue === 'number' ||
        typeof rawValue === 'boolean' ||
        rawValue instanceof String
        ) {
            output[key] = String(rawValue);
            continue;
        }

        if (rawValue instanceof admin.firestore.Timestamp) {
            output[key] = rawValue.toDate().toISOString();
            continue;
        }

        if (rawValue instanceof Date) {
            output[key] = rawValue.toISOString();
            continue;
        }

        try {
            const value = JSON.stringify(rawValue);

            if (value && value !== '{}' && value !== '[]') {
                output[key] = value;
            }
        } catch (_) {
            const value = String(rawValue).trim();

            if (value) {
                output[key] = value;
            }
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

function chunkArray(items, size) {
    const chunks = [];

    for (let i = 0; i < items.length; i += size) {
        chunks.push(items.slice(i, i + size));
    }

    return chunks;
}

async function getEnabledTokens(userId) {
    const cleanUserId = cleanString(userId);

    if (!cleanUserId) return [];

    const snapshot = await db
        .collection('users')
        .doc(cleanUserId)
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
            platform: cleanString(data.platform || 'unknown') || 'unknown',
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

async function disableInvalidToken(tokenItem, code, messageText) {
    try {
        await tokenItem.ref.set(
            {
                enabled: false,
                disabledAt: admin.firestore.FieldValue.serverTimestamp(),
                disabledReason: code,
                disabledMessage: messageText,
            },
            { merge: true },
        );
    } catch (error) {
        console.error('[Push] Erro ao desativar token inválido:', {
            tokenId: tokenItem.id,
            code,
            error: error.message || error,
        });
    }
}

function buildMulticastMessage({
    tokens,
    title,
    body,
    data,
}) {
    return {
        tokens,

        notification: {
            title,
            body,
        },

        data,

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
}

exports.onUserNotificationCreate = onDocumentCreated(
    {
        region: REGION,
        document: 'users/{userId}/notifications/{notificationId}',
        memory: '256MiB',
        timeoutSeconds: 60,
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

        if (!userId || !notificationId) {
            console.log('[Push] userId ou notificationId ausente.', {
                userId,
                notificationId,
            });
            return;
        }

        const sendPush = notification.sendPush === true;

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
        const status = cleanString(notification.status || notification.type) || 'info';

        const extra =
        notification.extra && typeof notification.extra === 'object'
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
            status,
            type: status,
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
                pushError: 'Nenhum token remoto ativo encontrado para o usuário.',
                pushSuccessCount: 0,
                pushFailureCount: 0,
                pushResults: [],
                pushErrors: [],
            });

            return;
        }

        const results = [];
        const errors = [];

        const tokenChunks = chunkArray(tokenItems, FCM_BATCH_LIMIT);

        for (const chunk of tokenChunks) {
            const tokens = chunk.map((item) => item.token);

            const message = buildMulticastMessage({
                tokens,
                title,
                body,
                data: baseData,
            });

            let response;

            try {
                response = await admin.messaging().sendEachForMulticast(message);
            } catch (error) {
                const code = cleanString(error.code) || 'unknown';
                const messageText = cleanString(error.message) || String(error);

                console.error('[Push] Falha geral no lote multicast.', {
                    userId,
                    notificationId,
                    code,
                    message: messageText,
                    totalTokens: chunk.length,
                });

                for (const item of chunk) {
                    const errorData = {
                        tokenId: item.id,
                        platform: item.platform,
                        success: false,
                        code,
                        message: messageText,
                    };

                    results.push(errorData);
                    errors.push(errorData);
                }

                continue;
            }

            response.responses.forEach((itemResponse, index) => {
                const tokenItem = chunk[index];

                if (itemResponse.success) {
                    const resultData = {
                        tokenId: tokenItem.id,
                        platform: tokenItem.platform,
                        success: true,
                        messageId: cleanString(itemResponse.messageId),
                    };

                    results.push(resultData);

                    return;
                }

                const error = itemResponse.error || {};
                const code = cleanString(error.code) || 'unknown';
                const messageText = cleanString(error.message) || String(error);

                const errorData = {
                    tokenId: tokenItem.id,
                    platform: tokenItem.platform,
                    success: false,
                    code,
                    message: messageText,
                };

                results.push(errorData);
                errors.push(errorData);

                console.error('[Push] Falha ao enviar para token.', {
                    userId,
                    notificationId,
                    platform: tokenItem.platform,
                    tokenId: tokenItem.id,
                    code,
                    message: messageText,
                });
            });
        }

        const invalidTokenDisables = [];

        for (const errorItem of errors) {
            if (!isInvalidTokenError(errorItem.code)) continue;

            const tokenItem = tokenItems.find((item) => item.id === errorItem.tokenId);

            if (!tokenItem) continue;

            invalidTokenDisables.push(
                disableInvalidToken(
                    tokenItem,
                    errorItem.code,
                    errorItem.message,
                ),
            );
        }

        if (invalidTokenDisables.length > 0) {
            await Promise.allSettled(invalidTokenDisables);
        }

        const successCount = results.filter((item) => item.success === true).length;
        const failureCount = errors.length;

        const sentAt = admin.firestore.FieldValue.serverTimestamp();

        const pushStatus =
        successCount === 0
            ? 'failed'
            : failureCount > 0
            ? 'partial'
            : 'sent';

        await safeUpdateNotification(notificationRef, {
            pushSent: successCount > 0,
            pushSentAt: successCount > 0 ? sentAt : null,
            pushAttemptedAt: sentAt,
            pushStatus,
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
            pushStatus,
            platforms: tokenPlatforms,
        });
    },
);