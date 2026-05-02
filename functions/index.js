// functions/index.js

const { iaChat } = require('./src/http/ia_chat');
const { ibgeProxy } = require('./src/http/ibge_proxy');
const { onUserNotificationCreate } = require('./src/triggers/on_user_notification_create');

exports.iaChat = iaChat;
exports.ibgeProxy = ibgeProxy;
exports.onUserNotificationCreate = onUserNotificationCreate;