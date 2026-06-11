#pragma once

#include <QQuickPaintedItem>

class PathArrowBackground : public QQuickPaintedItem
{
    Q_OBJECT
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(int arrowWidth READ arrowWidth WRITE setArrowWidth NOTIFY arrowWidthChanged)
    Q_PROPERTY(bool flatLeft READ flatLeft WRITE setFlatLeft NOTIFY flatLeftChanged)
    Q_PROPERTY(bool flatRight READ flatRight WRITE setFlatRight NOTIFY flatRightChanged)
    Q_PROPERTY(qreal leftRadius READ leftRadius WRITE setLeftRadius NOTIFY leftRadiusChanged)
    Q_PROPERTY(qreal rightRadius READ rightRadius WRITE setRightRadius NOTIFY rightRadiusChanged)

public:
    PathArrowBackground(QQuickItem *parent = nullptr);

    QColor color() const;
    void setColor(const QColor &color);

    int arrowWidth() const;
    void setArrowWidth(int arrowWidth);

    bool flatLeft() const;
    void setFlatLeft(bool flatLeft);

    bool flatRight() const;
    void setFlatRight(bool flatRight);

    qreal leftRadius() const;
    void setLeftRadius(qreal leftRadius);

    qreal rightRadius() const;
    void setRightRadius(qreal rightRadius);

protected:
    void paint(QPainter *painter) override;

private:
    QColor m_color;
    int m_arrowWidth;
    bool m_flatLeft;
    bool m_flatRight;
    qreal m_leftRadius;
    qreal m_rightRadius;

Q_SIGNALS:
    void colorChanged();
    void arrowWidthChanged();
    void flatLeftChanged();
    void flatRightChanged();
    void leftRadiusChanged();
    void rightRadiusChanged();
};
