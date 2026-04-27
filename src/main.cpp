// Copyright 2018-2023 Camilo Higuita <milo.h@aol.com>
// Copyright 2018-2023 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later
#include <QCommandLineParser>
#include <QDate>
#include <QIcon>
#include <QApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QSurfaceFormat>
#include <QUrl>

#include <MauiKit4/Core/mauiapp.h>
#include <MauiKit4/FileBrowsing/moduleinfo.h>

#include <KF6/KIO/kio_version.h>

#include <KAboutData>
#include <KLocalizedString>

#include "../index_version.h"

#include "controllers/filepreviewer.h"
#include "controllers/dirinfo.h"
#include "controllers/folderconfig.h"
#include "controllers/fileproperties.h"
#include "controllers/patharrowbackground.h"

#include "index.h"

#include "models/recentfilesmodel.h"
#include "models/pathlist.h"

#define INDEX_URI "org.maui.index"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QSurfaceFormat format;
    format.setAlphaBufferSize(8);
    QSurfaceFormat::setDefaultFormat(format);

    QApplication app(argc, argv);

    app.setOrganizationName(QStringLiteral("Maui"));
    app.setWindowIcon(QIcon("://assets/index.png"));

    KLocalizedString::setApplicationDomain("index-fm");

    KAboutData about(QStringLiteral("index"),
                     i18n("Index"),
                     INDEX_VERSION_STRING,
                     i18n("Browse, organize and preview your files."),
                     KAboutLicense::LGPL_V3,
                     i18n("© %1 Made by Nitrux | Built with MauiKit", QString::number(QDate::currentDate().year())),
                     QString(GIT_BRANCH) + "/" + QString(GIT_COMMIT_HASH));

    about.addAuthor(QStringLiteral("Camilo Higuita"), i18n("Developer"), QStringLiteral("milo.h@aol.com"));
    about.addAuthor(QStringLiteral("Uri Herrera"), i18n("Developer"), QStringLiteral("uri_herrera@nxos.org"));
    about.setHomepage("https://nxos.org");
    about.setProductName("nitrux/index");
    about.setOrganizationDomain(INDEX_URI);
    about.setDesktopFileName("org.kde.index");
    about.setProgramLogo(app.windowIcon());

    about.addComponent("KIO", "", KIO_VERSION_STRING);

    const auto fileBrowsingData = MauiKitFileBrowsing::aboutData();
    about.addComponent(fileBrowsingData.name(), MauiKitFileBrowsing::buildVersion(), fileBrowsingData.version(), fileBrowsingData.webAddress());

    KAboutData::setApplicationData(about);
    MauiApp::instance()->setIconName("qrc:/assets/index.svg");

    QCommandLineOption newWindowOption(QStringList() << "n" << "new", i18n("Open url in a new window."), "url");

    QCommandLineParser parser;

    parser.addOption(newWindowOption);

    parser.setApplicationDescription(about.shortDescription());
    parser.process(app);
    about.processCommandLine(&parser);

    const QStringList args = parser.positionalArguments();
    QStringList paths;
    
    if (!args.isEmpty())
    {
        for(const auto &path : args)
            paths << QUrl::fromUserInput(path).toString();
    }

    if(parser.isSet(newWindowOption))
    {
        paths = QStringList() << QUrl::fromUserInput(parser.value(newWindowOption)).toString() ;
    }
    else
    {
        if (IndexInstance::attachToExistingInstance(QUrl::fromStringList(paths), false, false))
        {
            // Successfully attached to existing instance of Index
            return 0;
        }
    }

    IndexInstance::registerService();

    auto index = std::make_unique<Index>(nullptr);

    QQmlApplicationEngine engine;
    // const QUrl url(QStringLiteral("qrc:/qt/qml/org/maui/index/main.qml"));
    const QUrl url(QStringLiteral("qrc:/app/maui/index/main.qml"));

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreated,
        &app,
        [url, &index](QObject *obj, const QUrl &objUrl) {
            if (!obj && url == objUrl)
                QCoreApplication::exit(-1);

            index->setQmlObject(obj);

        }, Qt::QueuedConnection);

    engine.rootContext()->setContextObject(new KLocalizedContext(&engine));

    engine.rootContext()->setContextProperty("initPaths", paths);

    engine.rootContext()->setContextProperty("inx", index.get());
    qmlRegisterType<FilePreviewer>(INDEX_URI, 1, 0, "FilePreviewProvider");
    qmlRegisterType<RecentFilesModel>(INDEX_URI, 1, 0, "RecentFiles");
    qmlRegisterType<DirInfo>(INDEX_URI, 1, 0, "DirInfo");
    qmlRegisterType<PathList>(INDEX_URI, 1, 0, "PathList");
    qmlRegisterType<FolderConfig>(INDEX_URI, 1, 0, "FolderConfig");
    qmlRegisterType<FileProperties>(INDEX_URI, 1, 0, "FileProperties");
    qmlRegisterType<Permission>(INDEX_URI, 1, 0, "Permission");
    qmlRegisterType<PathArrowBackground>(INDEX_URI, 1, 0, "PathArrowBackground");

    engine.load(url);
    return app.exec();
}
