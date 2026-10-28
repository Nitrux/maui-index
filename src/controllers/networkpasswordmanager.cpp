#include "networkpasswordmanager.h"

#include <QDebug>
#include <QHash>
#include <QRegularExpression>
#include <QStringList>
#include <QUrl>

#include <kio/authinfo.h>
#include <kpasswdserverclient.h>

#include <MauiKit4/Accounts/mauisecretstore.h>

namespace
{
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
{
    MauiSecretStore::instance()->migrateLegacy(QStringLiteral("org.maui.index.network"), {QStringLiteral("protocol"), QStringLiteral("address"), QStringLiteral("username")}, QStringLiteral("index"), QStringLiteral("network"));
}

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
    return MauiSecretStore::instance()->available();
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
    const auto credentials = MauiSecretStore::instance()->find(QStringLiteral("index"), QStringLiteral("network"), {{QStringLiteral("protocol"), normalizedProtocol}, {QStringLiteral("address"), normalizedAddress}, {QStringLiteral("username"), normalizedUsername}});
    if (credentials.value(QStringLiteral("found")).toBool())
        result[QStringLiteral("password")] = credentials.value(QStringLiteral("secret"));
    result[QStringLiteral("found")] = credentials.value(QStringLiteral("found")).toBool();
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

    const bool stored = MauiSecretStore::instance()->save(QStringLiteral("index"), QStringLiteral("network"), QVariantMap{{QStringLiteral("protocol"), normalizedProtocol}, {QStringLiteral("address"), normalizedAddress}, {QStringLiteral("username"), normalizedUsername}}, password, credentialLabel(normalizedProtocol, normalizedAddress, normalizedUsername));
    if (!stored)
        return false;

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

    if (!MauiSecretStore::instance()->remove(QStringLiteral("index"), QStringLiteral("network"), QVariantMap{{QStringLiteral("protocol"), normalizedProtocol}, {QStringLiteral("address"), normalizedAddress}, {QStringLiteral("username"), normalizedUsername}}))
        return false;

    ++m_revision;
    Q_EMIT credentialsChanged();
    return true;
}
