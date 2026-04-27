#include "storagemodel.h"

#include <QDir>
#include <QFileInfo>
#include <QLocale>
#include <QSet>
#include <QStorageInfo>
#include <QTimer>
#include <QUrl>

#include <KF6/KI18n/KLocalizedString>

StorageModel::StorageModel(QObject *parent)
    : MauiList(parent)
    , m_refreshTimer(new QTimer(this))
{
    m_refreshTimer->setInterval(10000);
    connect(m_refreshTimer, &QTimer::timeout, this, &StorageModel::reload);
}

const FMH::MODEL_LIST &StorageModel::items() const
{
    return m_list;
}

void StorageModel::componentComplete()
{
    reload();
    m_refreshTimer->start();
}

void StorageModel::reload()
{
    FMH::MODEL_LIST nextList;
    QSet<QString> seenDevices;
    QSet<QString> seenRoots;
    const QLocale locale;

    const auto storages = QStorageInfo::mountedVolumes();
    for (const auto &storage : storages)
    {
        if (!isDisplayableStorage(storage))
            continue;

        const QString rootPath = QDir::cleanPath(storage.rootPath());
        const QString devicePath = QString::fromUtf8(storage.device());
        const QString uniqueKey = !devicePath.isEmpty() ? devicePath : rootPath;

        if (seenDevices.contains(uniqueKey) || seenRoots.contains(rootPath))
            continue;

        seenDevices.insert(uniqueKey);
        seenRoots.insert(rootPath);

        const qint64 totalBytes = storage.bytesTotal();
        const qint64 freeBytes = storage.bytesAvailable();
        const qint64 usedBytes = qMax<qint64>(0, totalBytes - freeBytes);
        const double usage = totalBytes > 0 ? static_cast<double>(usedBytes) / static_cast<double>(totalBytes) : 0.0;

        nextList << FMH::MODEL {
            {FMH::MODEL_KEY::LABEL, storageLabel(storage)},
            {FMH::MODEL_KEY::PATH, QUrl::fromLocalFile(rootPath).toString()},
            {FMH::MODEL_KEY::ICON, storageIcon(storage)},
            {FMH::MODEL_KEY::TYPE, storageKind(storage)},
            {FMH::MODEL_KEY::DETAILS, rootPath},
            {FMH::MODEL_KEY::DEVICE, devicePath},
            {FMH::MODEL_KEY::SIZE, QString::number(totalBytes)},
            {FMH::MODEL_KEY::VALUE, QString::number(usage, 'f', 4)},
            {FMH::MODEL_KEY::SUMMARY, i18n("%1 used of %2", locale.formattedDataSize(usedBytes), locale.formattedDataSize(totalBytes))},
            {FMH::MODEL_KEY::MESSAGE, i18n("%1 free", locale.formattedDataSize(freeBytes))},
            {FMH::MODEL_KEY::COMMENT, QString::fromUtf8(storage.fileSystemType())}
        };
    }

    Q_EMIT preListChanged();
    m_list = nextList;
    Q_EMIT postListChanged();
}

bool StorageModel::isDisplayableStorage(const QStorageInfo &storage)
{
    if (!storage.isValid() || !storage.isReady())
        return false;

    if (storage.bytesTotal() <= 0)
        return false;

    const QString rootPath = QDir::cleanPath(storage.rootPath());
    if (rootPath.isEmpty())
        return false;

    const QString devicePath = QString::fromUtf8(storage.device());
    if (!devicePath.startsWith("/dev/"))
        return false;

    if (devicePath.startsWith("/dev/loop"))
        return false;

    return true;
}

QString StorageModel::storageLabel(const QStorageInfo &storage)
{
    const QString displayName = storage.displayName().trimmed();
    if (!displayName.isEmpty())
        return displayName;

    const QString rootPath = QDir::cleanPath(storage.rootPath());
    if (rootPath == "/")
        return i18n("System");

    const QString devicePath = QString::fromUtf8(storage.device());
    if (devicePath.startsWith("/dev/"))
        return QFileInfo(devicePath).fileName();

    const QString dirName = QFileInfo(rootPath).fileName();
    return dirName.isEmpty() ? rootPath : dirName;
}

QString StorageModel::storageKind(const QStorageInfo &storage)
{
    const QString rootPath = QDir::cleanPath(storage.rootPath());
    if (rootPath.startsWith("/run/media/") || rootPath.startsWith("/media/"))
        return i18n("External storage");

    return i18n("Storage");
}

QString StorageModel::storageIcon(const QStorageInfo &storage)
{
    const QString devicePath = QString::fromUtf8(storage.device());
    if (devicePath.startsWith("/dev/sr"))
        return QStringLiteral("media-optical");

    const QString rootPath = QDir::cleanPath(storage.rootPath());
    if (rootPath.startsWith("/run/media/") || rootPath.startsWith("/media/"))
        return QStringLiteral("drive-removable-media");

    return QStringLiteral("drive-harddisk");
}
