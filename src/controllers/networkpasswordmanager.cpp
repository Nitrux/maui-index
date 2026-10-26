#include "networkpasswordmanager.h"

#include <QDebug>
#include <QHash>
#include <QRegularExpression>
#include <QStringList>
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
    return !value.isEmpty() && !value.contains(QChar(0)) && !value.contains(QRegularExpression(QStringLiteral("[\\x00-\\x1F\\x7F]")));
}

bool validSecret(const QString &value)
{
    return !value.contains(QChar(0));
}

bool normalizeEndpoint(const QString &protocol, const QString &address, const QString &username, QString *normalizedProtocol, QString *normalizedAddress, QUrl *url)
{
    const QString normalizedScheme = protocol.trimmed().toLower();
    static const QStringList supportedSchemes = {QStringLiteral("smb"), QStringLiteral("sftp"), QStringLiteral("ftp"), QStringLiteral("ftps"), QStringLiteral("dav"), QStringLiteral("davs"), QStringLiteral("fish"), QStringLiteral("afc")};
    if (!supportedSchemes.contains(normalizedScheme) || !validAttribute(username.trimmed()))
        return false;

    const QString normalizedHost = address.trimmed();
    if (!validAttribute(normalizedHost) || normalizedHost.contains(QStringLiteral("://")))
        return false;

    const QUrl endpoint(QStringLiteral("%1://%2").arg(normalizedScheme, normalizedHost), QUrl::StrictMode);
    if (!endpoint.isValid() || endpoint.host().isEmpty() || !endpoint.userInfo().isEmpty() || endpoint.hasQuery() || endpoint.hasFragment())
        return false;

    if (normalizedProtocol)
        *normalizedProtocol = normalizedScheme;
    if (normalizedAddress)
        *normalizedAddress = normalizedHost;
    if (url)
        *url = endpoint;
    return true;
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

NetworkPasswordManager::~NetworkPasswordManager()
{
    for (auto it = m_sessionCredentials.begin(); it != m_sessionCredentials.end(); ++it)
        it.value().fill(QChar(0));
    m_sessionCredentials.clear();
}

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

    QString normalizedProtocol;
    QString normalizedAddress;
    const QString normalizedUsername = username.trimmed();
    if (!normalizeEndpoint(protocol, address, normalizedUsername, &normalizedProtocol, &normalizedAddress, nullptr))
        return result;

    GError *error = nullptr;
    GHashTable *attributes = secret_attributes_build(
        indexSchema(),
        "protocol", normalizedProtocol.toUtf8().constData(),
        "address", normalizedAddress.toUtf8().constData(),
        "username", normalizedUsername.toUtf8().constData(),
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
    QString normalizedProtocol;
    QString normalizedAddress;
    QString normalizedUsername = username.trimmed();
    QUrl endpoint;
    if (!normalizeEndpoint(protocol, address, normalizedUsername, &normalizedProtocol, &normalizedAddress, &endpoint)
            || !validSecret(password))
        return false;

    const auto key = credentialKey(normalizedProtocol, normalizedAddress, normalizedUsername);
    auto sessionCredential = m_sessionCredentials.find(key);
    if (sessionCredential != m_sessionCredentials.end()) {
        sessionCredential.value().fill(QChar(0));
        sessionCredential.value() = password;
    } else {
        m_sessionCredentials.insert(key, password);
    }

    KIO::AuthInfo info;
    info.url = endpoint;
    info.username = normalizedUsername;
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
    QString normalizedProtocol;
    QString normalizedAddress;
    const QString normalizedUsername = username.trimmed();
    if (!normalizeEndpoint(protocol, address, normalizedUsername, &normalizedProtocol, &normalizedAddress, nullptr))
        return false;

    const auto sessionCredentials = m_sessionCredentials.constFind(credentialKey(normalizedProtocol, normalizedAddress, normalizedUsername));
    if (sessionCredentials != m_sessionCredentials.constEnd())
        return prepare(normalizedProtocol, normalizedAddress, normalizedUsername, sessionCredentials.value());

    const QVariantMap credentials = find(normalizedProtocol, normalizedAddress, normalizedUsername);
    if (!credentials.value(QStringLiteral("found")).toBool())
        return false;

    return prepare(normalizedProtocol, normalizedAddress, normalizedUsername, credentials.value(QStringLiteral("password")).toString());
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
    QString normalizedProtocol;
    QString normalizedAddress;
    const QString normalizedUsername = username.trimmed();
    if (!normalizeEndpoint(protocol, address, normalizedUsername, &normalizedProtocol, &normalizedAddress, nullptr)
            || !validSecret(password)) {
        qWarning() << "NetworkPasswordManager::save: invalid credential attributes";
        return false;
    }

    GError *error = nullptr;
    secret_password_store_sync(
        indexSchema(),
        SECRET_COLLECTION_DEFAULT,
        credentialLabel(normalizedProtocol, normalizedAddress, normalizedUsername).toUtf8().constData(),
        password.toUtf8().constData(),
        nullptr,
        &error,
        "protocol", normalizedProtocol.toUtf8().constData(),
        "address", normalizedAddress.toUtf8().constData(),
        "username", normalizedUsername.toUtf8().constData(),
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
    QString normalizedProtocol;
    QString normalizedAddress;
    const QString normalizedUsername = username.trimmed();
    QUrl endpoint;
    if (!normalizeEndpoint(protocol, address, normalizedUsername, &normalizedProtocol, &normalizedAddress, &endpoint)) {
        qWarning() << "NetworkPasswordManager::remove: invalid credential attributes";
        return false;
    }

    const auto key = credentialKey(normalizedProtocol, normalizedAddress, normalizedUsername);
    auto sessionCredential = m_sessionCredentials.find(key);
    if (sessionCredential != m_sessionCredentials.end()) {
        sessionCredential.value().fill(QChar(0));
        m_sessionCredentials.erase(sessionCredential);
    }

    static KPasswdServerClient client;
    client.removeAuthInfo(endpoint.host(), normalizedProtocol, normalizedUsername);

    GError *error = nullptr;
    secret_password_clear_sync(
        indexSchema(),
        nullptr,
        &error,
        "protocol", normalizedProtocol.toUtf8().constData(),
        "address", normalizedAddress.toUtf8().constData(),
        "username", normalizedUsername.toUtf8().constData(),
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
