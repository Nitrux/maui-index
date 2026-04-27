#pragma once

#include <MauiKit4/Core/mauilist.h>

class QStorageInfo;
class QTimer;

class StorageModel : public MauiList
{
    Q_OBJECT

public:
    explicit StorageModel(QObject *parent = nullptr);

    const FMH::MODEL_LIST &items() const override final;
    void componentComplete() override final;

public Q_SLOTS:
    void reload();

private:
    FMH::MODEL_LIST m_list;
    QTimer *m_refreshTimer;

    static bool isDisplayableStorage(const QStorageInfo &storage);
    static QString storageLabel(const QStorageInfo &storage);
    static QString storageKind(const QStorageInfo &storage);
    static QString storageIcon(const QStorageInfo &storage);
};
