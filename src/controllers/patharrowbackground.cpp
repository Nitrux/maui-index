#include "patharrowbackground.h"

#include <QPainter>
#include <QBrush>
#include <QPainterPath>

PathArrowBackground::PathArrowBackground(QQuickItem *parent)
    : QQuickPaintedItem(parent)
    , m_color(Qt::white)
    , m_arrowWidth(16)
    , m_flatLeft(false)
    , m_leftRadius(0)
{
}

QColor PathArrowBackground::color() const
{
    return m_color;
}

void PathArrowBackground::setColor(const QColor &color)
{
    if (m_color == color) {
        return;
    }

    m_color = color;
    Q_EMIT colorChanged();
    update();
}

int PathArrowBackground::arrowWidth() const
{
    return m_arrowWidth;
}

void PathArrowBackground::setArrowWidth(int arrowWidth)
{
    if (m_arrowWidth == arrowWidth) {
        return;
    }

    m_arrowWidth = arrowWidth;
    Q_EMIT arrowWidthChanged();
    update();
}

bool PathArrowBackground::flatLeft() const
{
    return m_flatLeft;
}

void PathArrowBackground::setFlatLeft(bool flatLeft)
{
    if (m_flatLeft == flatLeft) {
        return;
    }

    m_flatLeft = flatLeft;
    Q_EMIT flatLeftChanged();
    update();
}

qreal PathArrowBackground::leftRadius() const
{
    return m_leftRadius;
}

void PathArrowBackground::setLeftRadius(qreal leftRadius)
{
    if (qFuzzyCompare(m_leftRadius, leftRadius)) {
        return;
    }

    m_leftRadius = leftRadius;
    Q_EMIT leftRadiusChanged();
    update();
}

void PathArrowBackground::paint(QPainter *painter)
{
    if (boundingRect().isEmpty()) {
        return;
    }

    painter->setBrush(QBrush(m_color));
    painter->setPen(Qt::NoPen);
    painter->setRenderHint(QPainter::Antialiasing);

    const auto bounds = boundingRect();
    const qreal left = bounds.left();
    const qreal top = bounds.top();
    const qreal right = bounds.right();
    const qreal bottom = bounds.bottom();
    const qreal middle = top + (bounds.height() * 0.5);
    const qreal arrowWidth = qMin<qreal>(m_arrowWidth, bounds.width() * 0.5);
    const qreal radius = qBound<qreal>(0, m_leftRadius, bounds.height() * 0.5);

    QPainterPath path;

    if (m_flatLeft) {
        path.moveTo(left + radius, top);
        path.lineTo(right - arrowWidth - 1, top);
        path.lineTo(right, middle);
        path.lineTo(right - arrowWidth - 1, bottom);
        path.lineTo(left + radius, bottom);

        if (radius > 0) {
            path.quadTo(left, bottom, left, bottom - radius);
            path.lineTo(left, top + radius);
            path.quadTo(left, top, left + radius, top);
        } else {
            path.lineTo(left, bottom);
            path.lineTo(left, top);
        }
    } else {
        path.moveTo(left - 1, top);
        path.lineTo(left + arrowWidth, top);
        path.lineTo(right - arrowWidth - 1, top);
        path.lineTo(right, middle);
        path.lineTo(right - arrowWidth - 1, bottom);
        path.lineTo(left + arrowWidth, bottom);
        path.lineTo(left - 1, bottom);
        path.lineTo(left + arrowWidth, middle);
    }

    path.closeSubpath();
    painter->drawPath(path);
}
