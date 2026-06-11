#include "patharrowbackground.h"

#include <QPainter>
#include <QBrush>
#include <QPainterPath>

PathArrowBackground::PathArrowBackground(QQuickItem *parent)
    : QQuickPaintedItem(parent)
    , m_color(Qt::white)
    , m_arrowWidth(16)
    , m_flatLeft(false)
    , m_flatRight(false)
    , m_leftRadius(0)
    , m_rightRadius(0)
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

bool PathArrowBackground::flatRight() const
{
    return m_flatRight;
}

void PathArrowBackground::setFlatRight(bool flatRight)
{
    if (m_flatRight == flatRight) {
        return;
    }

    m_flatRight = flatRight;
    Q_EMIT flatRightChanged();
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

qreal PathArrowBackground::rightRadius() const
{
    return m_rightRadius;
}

void PathArrowBackground::setRightRadius(qreal rightRadius)
{
    if (qFuzzyCompare(m_rightRadius, rightRadius)) {
        return;
    }

    m_rightRadius = rightRadius;
    Q_EMIT rightRadiusChanged();
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
    const qreal leftRadius = qBound<qreal>(0, m_leftRadius, bounds.height() * 0.5);
    const qreal rightRadius = qBound<qreal>(0, m_rightRadius, bounds.height() * 0.5);

    QPainterPath path;

    if (m_flatLeft && m_flatRight) {
        path.moveTo(left + leftRadius, top);
        path.lineTo(right - rightRadius, top);

        if (rightRadius > 0) {
            path.quadTo(right, top, right, top + rightRadius);
            path.lineTo(right, bottom - rightRadius);
            path.quadTo(right, bottom, right - rightRadius, bottom);
        } else {
            path.lineTo(right, top);
            path.lineTo(right, bottom);
        }

        path.lineTo(left + leftRadius, bottom);

        if (leftRadius > 0) {
            path.quadTo(left, bottom, left, bottom - leftRadius);
            path.lineTo(left, top + leftRadius);
            path.quadTo(left, top, left + leftRadius, top);
        } else {
            path.lineTo(left, bottom);
            path.lineTo(left, top);
        }
    } else if (m_flatLeft) {
        path.moveTo(left + leftRadius, top);
        path.lineTo(right - arrowWidth - 1, top);
        path.lineTo(right, middle);
        path.lineTo(right - arrowWidth - 1, bottom);
        path.lineTo(left + leftRadius, bottom);

        if (leftRadius > 0) {
            path.quadTo(left, bottom, left, bottom - leftRadius);
            path.lineTo(left, top + leftRadius);
            path.quadTo(left, top, left + leftRadius, top);
        } else {
            path.lineTo(left, bottom);
            path.lineTo(left, top);
        }
    } else if (m_flatRight) {
        path.moveTo(left - 1, top);
        path.lineTo(left + arrowWidth, top);
        path.lineTo(right - rightRadius, top);

        if (rightRadius > 0) {
            path.quadTo(right, top, right, top + rightRadius);
            path.lineTo(right, bottom - rightRadius);
            path.quadTo(right, bottom, right - rightRadius, bottom);
        } else {
            path.lineTo(right, top);
            path.lineTo(right, bottom);
        }

        path.lineTo(left + arrowWidth, bottom);
        path.lineTo(left - 1, bottom);
        path.lineTo(left + arrowWidth, middle);
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
