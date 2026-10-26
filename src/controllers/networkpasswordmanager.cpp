#include "networkpasswordmanager.h"

#include <QDebug>
#include <QHash>
#include <QUrl>

#include <kio/authinfo.h>
#include <kpasswdserverclient.h>

#ifdef signals
#pragma push_macro("signals")
#undef signals
#define INDEX_RESTORE_QT_SIGNALS
#endif
extern "C" {
#include <libsecret/secret.h>
}
#ifdef INDEX_RESTORE_QT_SIGNALS
#pragma pop_macro("signals")
#undef INDEX_RESTORE_QT_SIGNALS
#endif

namespace
{
const SecretSchema *indexSchema()
{
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wmissing-field-initializers"
    static const SecretSchema schema = {
        "org.maui.index.network",
        SECRET_SCHEMA_NONE,
        {
            { "protocol", SECRET_SCHEMA_ATTRIBUTE_STRING },
            { "address",  SECRET_SCHEMA_ATTRIBUTE_STRING },
            { "username", SECRET_SCHEMA_ATTRIBUTE_STRING },
            { nullptr,     SECRET_SCHEMA_ATTRIBUTE_STRING }
        }
    };
#pragma GCC diagnostic pop

    return &schema;
}

bool validAttribute(const QString &value)
{
    return !value.contains(QChar(0));
}

QString credentialLabel(const QString &protocol, const QString &address, const QString &username)
{
    return QStringLiteral("Index: %1 @ %2://%3").arg(username, protocol, address);
}

QString credentialKey(const QString &protocol, const QString &address, const QString &username)
{
    return QStringLiteral("%1:%2%3:%4%5:%6")
        .arg(protocol.size())
        .arg(protocol)
        .arg(address.size())
        .arg(address)
        .arg(username.size())
        .arg(username);
}
}

NetworkPasswordManager &NetworkPasswordManager::instance()
{
    static NetworkPasswordManager manager;
    return manager;
}

NetworkPasswordManager::NetworkPasswordManager(QObject *parent)
    : QObject(parent)
{}

int NetworkPasswordManager::revision() const
{
    return m_revision;
}

bool NetworkPasswordManager::available() const
{
    GError *error = nullptr;
    SecretService *service = secret_service_get_sync(SECRET_SERVICE_NONE, nullptr, &error);

    if (error) {
        g_error_free(error);
        return false;
    }

    const bool result = service != nullptr;
    if (service)
        g_object_unref(service);
    return result;
}

QVariantMap NetworkPasswordManager::find(const QString &protocol,
                                         const QString &address,
                                         const QString &username) const
{
    QVariantMap result;
    result[QStringLiteral("found")] = false;

    if (!validAttribute(protocol) || !validAttribute(address) || !validAttribute(username))
        return result;

    GError *error = nullptr;
    GHashTable *attributes = secret_attributes_build(
        indexSchema(),
        "protocol", protocol.toUtf8().constData(),
        "address", address.toUtf8().constData(),
        "username", username.toUtf8().constData(),
        nullptr);

    GList *items = secret_service_search_sync(
        nullptr,
        indexSchema(),
        attributes,
        static_cast<SecretSearchFlags>(SECRET_SEARCH_ALL | SECRET_SEARCH_UNLOCK | SECRET_SEARCH_LOAD_SECRETS),
        nullptr,
        &error);

    g_hash_table_unref(attributes);

    if (error) {
        qWarning() << "NetworkPasswordManager::find:" << error->message;
        g_error_free(error);
        return result;
    }

    if (items) {
        SecretItem *item = SECRET_ITEM(items->data);
        SecretValue *value = secret_item_get_secret(item);
        if (value) {
            result[QStringLiteral("found")] = true;
            result[QStringLiteral("password")] = QString::fromUtf8(secret_value_get(value, nullptr));
            secret_value_unref(value);
        }
    }

    g_list_free_full(items, g_object_unref);
    return result;
}

bool NetworkPasswordManager::prepare(const QString &protocol,
                                     const QString &address,
                                     const QString &username,
                                     const QString &password)
{
    if (!validAttribute(protocol) || !validAttribute(address) || !validAttribute(username))
        return false;

    m_sessionCredentials.insert(credentialKey(protocol, address, username), password);

    KIO::AuthInfo info;
    info.url = QUrl(QStringLiteral("%1://%2").arg(protocol, address));
    info.username = username;
    info.password = password;
    info.keepPassword = false;

    static KPasswdServerClient client;
    client.addAuthInfo(info, 0);
    return true;
}

bool NetworkPasswordManager::prepareStored(const QString &protocol,
                                            const QString &address,
                                            const QString &username)
{
    if (!validAttribute(protocol) || !validAttribute(address) || !validAttribute(username))
        return false;

    const auto sessionCredentials = m_sessionCredentials.constFind(credentialKey(protocol, address, username));
    if (sessionCredentials != m_sessionCredentials.constEnd())
        return prepare(protocol, address, username, sessionCredentials.value());

    const QVariantMap credentials = find(protocol, address, username);
    if (!credentials.value(QStringLiteral("found")).toBool())
        return false;

    return prepare(protocol, address, username, credentials.value(QStringLiteral("password")).toString());
}

bool NetworkPasswordManager::hasCredentials(const QString &protocol,
                                            const QString &address,
                                            const QString &username) const
{
    return find(protocol, address, username).value(QStringLiteral("found")).toBool();
}

bool NetworkPasswordManager::save(const QString &protocol,
                                  const QString &address,
                                  const QString &username,
                                  const QString &password)
{
    if (!validAttribute(protocol) || !validAttribute(address) || !validAttribute(username)) {
        qWarning() << "NetworkPasswordManager::save: invalid credential attributes";
        return false;
    }

    GError *error = nullptr;
    secret_password_store_sync(
        indexSchema(),
        SECRET_COLLECTION_DEFAULT,
        credentialLabel(protocol, address, username).toUtf8().constData(),
        password.toUtf8().constData(),
        nullptr,
        &error,
        "protocol", protocol.toUtf8().constData(),
        "address", address.toUtf8().constData(),
        "username", username.toUtf8().constData(),
        nullptr);

    if (error) {
        qWarning() << "NetworkPasswordManager::save:" << error->message;
        g_error_free(error);
        return false;
    }

    ++m_revision;
    Q_EMIT credentialsChanged();
    return true;
}

bool NetworkPasswordManager::remove(const QString &protocol,
                                    const QString &address,
                                    const QString &username)
{
    if (!validAttribute(protocol) || !validAttribute(address) || !validAttribute(username)) {
        qWarning() << "NetworkPasswordManager::remove: invalid credential attributes";
        return false;
    }

    m_sessionCredentials.remove(credentialKey(protocol, address, username));

    static KPasswdServerClient client;
    const QUrl url(QStringLiteral("%1://%2").arg(protocol, address));
    client.removeAuthInfo(url.host(), protocol, username);

    GError *error = nullptr;
    secret_password_clear_sync(
        indexSchema(),
        nullptr,
        &error,
        "protocol", protocol.toUtf8().constData(),
        "address", address.toUtf8().constData(),
        "username", username.toUtf8().constData(),
        nullptr);

    if (error) {
        qWarning() << "NetworkPasswordManager::remove:" << error->message;
        g_error_free(error);
        return false;
    }

    ++m_revision;
    Q_EMIT credentialsChanged();
    return true;
}
