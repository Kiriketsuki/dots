import QtQuick

// Flat-top hex used as the seat icon in the usaKi card.
Canvas {
    id: root
    property color tone: Theme.tealLt
    property real fillAlpha: 0.2
    width: 18
    height: 16
    onToneChanged: requestPaint()
    onFillAlphaChanged: requestPaint()
    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ctx.beginPath();
        for (let i = 0; i < 6; i++) {
            const a = Math.PI / 3 * i;
            const x = 9 + 7 * Math.cos(a), y = 8 + 7 * Math.sin(a);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.globalAlpha = fillAlpha;
        ctx.fillStyle = tone;
        ctx.fill();
        ctx.globalAlpha = 1;
        ctx.strokeStyle = tone;
        ctx.lineWidth = 1;
        ctx.stroke();
    }
}
