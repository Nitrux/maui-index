// Copyright 2018-2020 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2020 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later

#include "index.h"

#include <QGuiApplication>
#include <QQuickWindow>
#include <QQmlApplicationEngine>

#include <QFileInfo>

#include <QProcess>
#include <QStandardPaths>

#include <KF6/KI18n/KLazyLocalizedString>

#include <MauiKit4/Core/fmh.h>
#include <MauiKit4/FileBrowsing/fmstatic.h>

#include "indexinterface.h"
#include "indexadaptor.h"

namespace
{
bool launchDetachedIndexWindow(const QUrl &url)
{
    const QStringList arguments = {"-n", url.toString()};
    const QString appPath = QCoreApplication::applicationFilePath();

    if (!appPath.isEmpty() && QProcess::startDetached(appPath, arguments))
    {
        return true;
    }

    if (QProcess::startDetached(QStringLiteral("index"), arguments))
    {
        return true;
    }

    qWarning() << "Failed to detach tab into a new window for" << url;
    return false;
}
}

QVector<QPair<QSharedPointer<OrgKdeIndexActionsInterface>, QStringList>> IndexInstance::appInstances(const QString& preferredService)
{
    QVector<QPair<QSharedPointer<OrgKdeIndexActionsInterface>, QStringList>> dolphinInterfaces;

    if (!preferredService.isEmpty())
    {
        QSharedPointer<OrgKdeIndexActionsInterface> preferredInterface(
            new OrgKdeIndexActionsInterface(preferredService,
                                            QStringLiteral("/Actions"),
                                            QDBusConnection::sessionBus()));

        if (preferredInterface->isValid() && !preferredInterface->lastError().isValid()) {
            dolphinInterfaces.append(qMakePair(preferredInterface, QStringList()));
        }
    }

           // Look for dolphin instances among all available dbus services.
    QDBusConnectionInterface *sessionInterface = QDBusConnection::sessionBus().interface();
    const QStringList dbusServices = sessionInterface ? sessionInterface->registeredServiceNames().value() : QStringList();
    // Don't match the service without trailing "-" (unique instance)
    const QString pattern = QStringLiteral("org.kde.index-");

           // Don't match the pid without leading "-"
    const QString myPid = QLatin1Char('-') + QString::number(QCoreApplication::applicationPid());

    for (const QString& service : dbusServices)
    {
        if (service.startsWith(pattern) && !service.endsWith(myPid))
        {
                   // Check if instance can handle our URLs
            QSharedPointer<OrgKdeIndexActionsInterface> interface(
                new OrgKdeIndexActionsInterface(service,
                                                QStringLiteral("/Actions"),
                                                QDBusConnection::sessionBus()));
            if (interface->isValid() && !interface->lastError().isValid())
            {
                dolphinInterfaces.append(qMakePair(interface, QStringList()));
            }
        }
    }

    return dolphinInterfaces;
}

bool IndexInstance::attachToExistingInstance(const QList<QUrl>& inputUrls, bool openFiles, bool splitView, const QString& preferredService)
{
    bool attached = false;

    if (inputUrls.isEmpty())
    {
        return false;
    }

    auto dolphinInterfaces = appInstances(preferredService);
    if (dolphinInterfaces.isEmpty())
    {
        return false;
    }

    QStringList newUrls;

           // check to see if any instances already have any of the given URLs open
    const auto urls = QUrl::toStringList(inputUrls);
    for (const QString& url : urls)
    {
        bool urlFound = false;

        for (auto& interface: dolphinInterfaces)
        {
            auto isUrlOpenReply = interface.first->isUrlOpen(url);
            isUrlOpenReply.waitForFinished();

            if (!isUrlOpenReply.isError() && isUrlOpenReply.value())
            {
                interface.second.append(url);
                urlFound = true;
                break;
            }
        }

        if (!urlFound)
        {
            newUrls.append(url);
        }
    }

    for (const auto& interface: std::as_const(dolphinInterfaces))
    {
        auto reply = openFiles ? interface.first->openFiles(newUrls, splitView) : interface.first->openDirectories(newUrls, splitView);
        reply.waitForFinished();

        if (!reply.isError())
        {
            interface.first->activateWindow();
            attached = true;
            break;
        }
    }

    return attached;
}


bool IndexInstance::registerService()
{
    QDBusConnectionInterface *iface = QDBusConnection::sessionBus().interface();

    auto registration = iface->registerService(QStringLiteral("org.kde.index-%1").arg(QCoreApplication::applicationPid()),
                                               QDBusConnectionInterface::ReplaceExistingService,
                                               QDBusConnectionInterface::DontAllowReplacement);

    if (!registration.isValid())
    {
        qWarning("2 Failed to register D-Bus service \"%s\" on session bus: \"%s\"",
                 qPrintable("org.kde.index"),
                 qPrintable(registration.error().message()));
        return false;
    }

    return true;
}

Index::Index(QObject *parent)
    : QObject(parent)
{
    new ActionsAdaptor(this);
    if(!QDBusConnection::sessionBus().registerObject(QStringLiteral("/Actions"), this))
    {
        return;
    }
}

void Index::openDirectories(const QStringList &dirs, bool)
{
    openPaths(dirs);
}

void Index::openFiles(const QStringList &files, bool)
{
    openPaths(files);
}

void Index::activateWindow()
{
    if(m_qmlObject)
    {
        auto window = qobject_cast<QQuickWindow *>(m_qmlObject);
        if (window)
        {
            window->raise();
            window->requestActivate();
        }
    }
}

bool Index::isUrlOpen(const QString &url)
{
    bool value = false;

    QMetaObject::invokeMethod(m_qmlObject, "isUrlOpen",
                              Q_RETURN_ARG(bool, value),
                              Q_ARG(QString, url));

    return value;
}

void Index::pasteIntoFolder()
{

}

void Index::changeUrl(const QUrl &)
{

}

void Index::slotTerminalDirectoryChanged(const QUrl &)
{

}

void Index::quit()
{
    QCoreApplication::quit();
}

void Index::openNewTab(const QUrl &)
{

}

void Index::openNewTabAndActivate(const QUrl &)
{

}

void Index::openNewWindow(const QUrl &url)
{
    launchDetachedIndexWindow(url);
}

bool Index::detachTabToNewWindow(const QUrl &url)
{
    return launchDetachedIndexWindow(url);
}

/* to be called to launch index with opening different paths */
void Index::openPaths(const QStringList &paths)
{
    QStringList urls = std::accumulate(paths.constBegin(), paths.constEnd(), QStringList(), [](QStringList &list, const QString &path) -> QStringList {
        const auto url = QUrl::fromUserInput(path);
        if (url.isLocalFile())
        {
            if (FMStatic::isDir(url))
            {
                list << url.toString();
            }
            else
            {
                list <<  FMStatic::fileDir(url).toString();
            }
        }

        return list;
    });

    if(m_qmlObject)
        QMetaObject::invokeMethod(m_qmlObject, "openDirs",
                                  Q_ARG(QVariant, urls));
}

void Index::setQmlObject(QObject *object)
{
    m_qmlObject = object;
}

void Index::openTerminal(const QUrl &url, const QString &program)
{
    const QString terminalProgram = program.trimmed().isEmpty() ? QStringLiteral("/usr/bin/station") : program.trimmed();
    const QString workingDirectory = url.isLocalFile() ? url.toLocalFile() : QString();

    if (!QProcess::startDetached(terminalProgram, {}, workingDirectory))
    {
        qWarning() << "Failed to launch terminal executable" << terminalProgram << "for" << workingDirectory;
    }
}

QVariantList Index::quickPaths()
{
    FMH::MODEL_LIST paths;
    const auto appendQuickPlace = [&paths](const QString &path, const QString &fallbackLabel, const QString &fallbackIcon, const QString &color, const bool forceIcon = false)
    {
        if (path.isEmpty())
            return;

        const auto url = QUrl::fromLocalFile(path);
        auto info = FMStatic::getFileInfoModel(url);

        if (info.isEmpty())
        {
            info = FMH::MODEL {
                {FMH::MODEL_KEY::PATH, url.toString()},
                {FMH::MODEL_KEY::ICON, fallbackIcon},
                {FMH::MODEL_KEY::LABEL, fallbackLabel}
            };
        }

        if (forceIcon)
            info[FMH::MODEL_KEY::ICON] = fallbackIcon;

        info.insert(FMH::MODEL_KEY::TYPE, QStringLiteral("Quick"));
        info.insert(FMH::MODEL_KEY::COLOR, color);
        paths << info;
    };

    paths << FMH::MODEL {{FMH::MODEL_KEY::PATH, "overview:///"},
                        {FMH::MODEL_KEY::ICON, "computer"},
                        {FMH::MODEL_KEY::LABEL, i18n("Overview")},
                        {FMH::MODEL_KEY::TYPE, "Quick"},
                        {FMH::MODEL_KEY::COLOR, "green"}};

    paths << FMH::MODEL {{FMH::MODEL_KEY::PATH, "tags:///"},
                        {FMH::MODEL_KEY::ICON, "tag"},
                        {FMH::MODEL_KEY::LABEL, i18n("Tags")}, {FMH::MODEL_KEY::TYPE, "Quick"},
                        {FMH::MODEL_KEY::COLOR, "blue"}};

    const auto defaultPaths = FMStatic::getDefaultPaths();
    for (const auto &item : defaultPaths)
    {
        if (item[FMH::MODEL_KEY::PATH] == FMStatic::RootPath)
            continue;

        paths << item;
    }

    appendQuickPlace(QStandardPaths::writableLocation(QStandardPaths::TemplatesLocation),
                     i18n("Templates"),
                     QStringLiteral("folder-templates"),
                     QStringLiteral("orange"),
                     true);

    appendQuickPlace(QStandardPaths::writableLocation(QStandardPaths::PublicShareLocation),
                     i18n("Public"),
                     QStringLiteral("folder-publicshare"),
                     QStringLiteral("orange"),
                     true);

    return FMH::toMapList(paths);
}

QUrl Index::cameraPath()
{
    const static auto paths = QStringList{FMStatic::HomePath + "/DCIM/Camera", FMStatic::HomePath + "/Camera"};

    for (const auto &path : paths) {
        if (FMH::fileExists(path))
            return QUrl(path);
    }

    return QUrl();
}

QUrl Index::screenshotsPath()
{
    const static auto paths = QStringList{FMStatic::HomePath + "/DCIM/Screenshots", FMStatic::HomePath + "/Screenshots"};

    for (const auto &path : paths) {
        if (FMH::fileExists(path))
            return QUrl(path);
    }

    return QUrl();
}
