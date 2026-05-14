#include "dirinfo.h"

#include <KIO/DirectorySizeJob>
#include <KIO/FileSystemFreeSpaceJob>

#include <MauiKit4/FileBrowsing/fmstatic.h>

DirInfo::DirInfo(QObject *parent) : QObject(parent)
{
    // auto m_free =  KIO::fileSystemFreeSpace (QUrl("file:///"));
    // connect(m_free, &KIO::FileSystemFreeSpaceJob::result, [this, m_free](KJob *, KIO::filesize_t size, KIO::filesize_t available)
    // {
    //
    //     m_totalSpace = size;
    //     m_avaliableSpace = available;
    //
    //     Q_EMIT this->avaliableSpaceChanged(m_avaliableSpace);
    //     Q_EMIT this->totalSpaceChanged(m_totalSpace);
    //
    //     m_free->deleteLater();
    //
    // });
}

QUrl DirInfo::url() const
{
    return m_url;
}

quint64 DirInfo::size() const
{
    return m_size;
}

quint64 DirInfo::dirCount() const
{
    return m_dirCount;
}

quint64 DirInfo::filesCount() const
{
    return m_filesCount;
}

QString DirInfo::sizeString() const
{
    QLocale m_locale;
    return m_locale.formattedDataSize(m_size);
}

quint64 DirInfo::avaliableSpace() const
{
    return m_avaliableSpace;
}

quint64 DirInfo::totalSpace() const
{
    return m_totalSpace;
}

QString DirInfo::avaliableSpaceString() const
{
    QLocale m_locale;
    return m_locale.formattedDataSize(m_avaliableSpace);
}

QString DirInfo::totalSpaceString() const
{
    QLocale m_locale;
    return m_locale.formattedDataSize(m_totalSpace);
}

void DirInfo::setUrl(QUrl url)
{
    if (m_url == url)
        return;

    m_url = url;
    this->getSize();
    Q_EMIT urlChanged(m_url);
}

void DirInfo::getSize()
{
    if(!m_url.isValid() || m_url.isEmpty() || !m_url.isLocalFile())
        return;

    auto m_job = KIO::directorySize(m_url);

    //    connect(m_job, &KIO::DirectorySizeJob::percent, [this, m_job](KJob *, unsigned long percent)
    //    {
    //    });

//    connect(m_job, &KIO::DirectorySizeJob::processedSize, [this, m_job](KJob *, qulonglong size)
//    {
//    });

    connect(m_job, &KIO::DirectorySizeJob::result, [this, m_job](KJob *)
    {
        m_size = m_job->totalSize();
        m_filesCount = m_job->totalFiles();
        m_dirCount = m_job->totalSubdirs();

        Q_EMIT this->sizeChanged(m_size);
        Q_EMIT this->filesCountChanged(m_filesCount);
        Q_EMIT this->dirsCountChanged(m_dirCount);

    });
}
