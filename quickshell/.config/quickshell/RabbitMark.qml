import QtQuick

// usaKi mark: a hex head with two ears. An ear folds when its window passes 75%.
Canvas {
    id: root
    property bool leftFold: false
    property bool rightFold: false
    width: 18
    height: 20
    onLeftFoldChanged: requestPaint()
    onRightFoldChanged: requestPaint()

    function hex(ctx, cx, cy, r) {
        ctx.beginPath();
        for (let i = 0; i < 6; i++) {
            const a = Math.PI / 3 * i;
            const x = cx + r * Math.cos(a), y = cy + r * Math.sin(a);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.closePath();
    }

    function ear(ctx, x, fold) {
        ctx.beginPath();
        ctx.strokeStyle = fold ? Theme.err : Theme.amLt;
        ctx.lineWidth = 1.6;
        ctx.lineCap = "square";
        ctx.moveTo(x, 10);
        if (fold) {
            ctx.lineTo(x, 5);
            ctx.lineTo(x < 9 ? x - 4 : x + 4, 7);
        } else {
            ctx.lineTo(x, 1);
        }
        ctx.stroke();
    }

    onPaint: {
        const ctx = getContext("2d");
        ctx.reset();
        ear(ctx, 6, leftFold);
        ear(ctx, 12, rightFold);
        hex(ctx, 9, 13.5, 6);
        ctx.fillStyle = "#1e1a3e";
        ctx.fill();
        ctx.strokeStyle = Theme.amLt;
        ctx.lineWidth = 1;
        ctx.stroke();
        ctx.beginPath();
        ctx.arc(9, 13.5, 1.4, 0, Math.PI * 2);
        ctx.fillStyle = Theme.tealLt;
        ctx.fill();
    }
}
