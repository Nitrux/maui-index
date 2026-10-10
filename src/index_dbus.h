// Copyright 2026 Nitrux Latinoamericana S.C.
//
// SPDX-License-Identifier: GPL-3.0-or-later

#pragma once

#include <QObject>
#include <QStringList>
#include <QVariantList>

class IndexDBus : public QObject
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.kde.index.Actions")

public Q_SLOTS:
    void openDirectories(const QStringList &dirs, bool splitView);
    void openFiles(const QStringList &files, bool splitView);
    void activateWindow();
    bool isUrlOpen(const QString &url);
    void pasteIntoFolder();
    void quit();
    QVariantList quickPaths();
    void openPaths(const QStringList &paths);

Q_SIGNALS:
    void openPath(QStringList paths);
    void activate();
};
