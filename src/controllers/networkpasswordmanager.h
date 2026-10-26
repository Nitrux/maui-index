#pragma once

#include <QObject>
#include <QString>
#include <QHash>
#include <QVariantMap>

class NetworkPasswordManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool available READ available CONSTANT)
    Q_PROPERTY(int revision READ revision NOTIFY credentialsChanged)

public:
    static NetworkPasswordManager &instance();

    bool available() const;
    int revision() const;

    Q_INVOKABLE bool hasCredentials(const QString &protocol,
                                    const QString &address,
                                    const QString &username) const;
    Q_INVOKABLE bool save(const QString &protocol,
                          const QString &address,
                          const QString &username,
                          const QString &password);
    Q_INVOKABLE bool remove(const QString &protocol,
                            const QString &address,
                            const QString &username);
    Q_INVOKABLE bool prepare(const QString &protocol,
                             const QString &address,
                             const QString &username,
                             const QString &password);
    Q_INVOKABLE bool prepareStored(const QString &protocol,
                                   const QString &address,
                                   const QString &username);

Q_SIGNALS:
    void credentialsChanged();

private:
    QVariantMap find(const QString &protocol,
                     const QString &address,
                     const QString &username) const;

    explicit NetworkPasswordManager(QObject *parent = nullptr);

    int m_revision = 0;
    QHash<QString, QString> m_sessionCredentials;
};
