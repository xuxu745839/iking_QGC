/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick 2.11

Item {
    id: root

    property string title:          ""
    property string unit:           ""
    property real   yMin:           -180
    property real   yMax:           180
    property real   timeWindowSec:  30
    property string cmdColor:       "#00CFFF"   ///< 指令曲线颜色（青色）
    property string feedColor:      "#FFA040"   ///< 反馈曲线颜色（橙色）

    property var  _cmdData:  []
    property var  _feedData: []
    property real _latestT:  0

    readonly property int _lm: 52
    readonly property int _rm: 8
    readonly property int _tm: 20
    readonly property int _bm: 22

    function appendData(t, cmdVal, feedVal) {
        _latestT = t
        var tCut = t - timeWindowSec - 0.5

        _cmdData.push({ t: t, v: cmdVal })
        _feedData.push({ t: t, v: feedVal })

        while (_cmdData.length  > 1 && _cmdData[0].t  < tCut) { _cmdData.shift()  }
        while (_feedData.length > 1 && _feedData[0].t < tCut) { _feedData.shift() }
    }

    function redraw() {
        canvas.requestPaint()
    }

    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx  = getContext("2d")
            var pw   = root.width  - root._lm - root._rm
            var ph   = root.height - root._tm - root._bm
            var px   = root._lm
            var py   = root._tm
            var yRng = root.yMax - root.yMin
            var tNow = root._latestT
            var tMin = tNow - root.timeWindowSec

            // ── 背景 ──────────────────────────────────────────────
            ctx.fillStyle = "#1c1c2e"
            ctx.fillRect(0, 0, root.width, root.height)
            ctx.fillStyle = "#13132a"
            ctx.fillRect(px, py, pw, ph)

            // ── 网格（虚线）───────────────────────────────────────
            var nGX = 5, nGY = 4, i, j
            ctx.strokeStyle = "#253050"
            ctx.lineWidth   = 1
            ctx.setLineDash([3, 3])
            for (i = 0; i <= nGY; i++) {
                var gy = py + i * ph / nGY
                ctx.beginPath(); ctx.moveTo(px, gy); ctx.lineTo(px + pw, gy); ctx.stroke()
            }
            for (j = 0; j <= nGX; j++) {
                var gx = px + j * pw / nGX
                ctx.beginPath(); ctx.moveTo(gx, py); ctx.lineTo(gx, py + ph); ctx.stroke()
            }

            // ── 恢复实线：用 [1,0] 替代 []，规避 Qt Canvas 兼容问题 ──
            ctx.setLineDash([1, 0])

            // ── Y 轴标签 ──────────────────────────────────────────
            ctx.fillStyle = "#99aabb"
            ctx.font      = "10px monospace"
            ctx.textAlign = "right"
            for (i = 0; i <= nGY; i++) {
                var lv = root.yMax - i * yRng / nGY
                var ly = py + i * ph / nGY
                ctx.fillText(lv.toFixed(0), px - 4, ly + 4)
            }

            // ── X 轴标签 ──────────────────────────────────────────
            ctx.textAlign = "center"
            for (j = 0; j <= nGX; j++) {
                var lx = px + j * pw / nGX
                var dt = -root.timeWindowSec + j * root.timeWindowSec / nGX
                ctx.fillText(dt.toFixed(0) + "s", lx, py + ph + 14)
            }

            // ── 边框 ──────────────────────────────────────────────
            ctx.strokeStyle = "#445566"
            ctx.lineWidth   = 1
            ctx.setLineDash([1, 0])
            ctx.beginPath(); ctx.rect(px, py, pw, ph); ctx.stroke()

            // ── 坐标映射 ─────────────────────────────────────────
            function mapX(t) { return px + (t - tMin) / root.timeWindowSec * pw }
            function mapY(v) { return py + (1.0 - (v - root.yMin) / yRng) * ph  }

            // ── 绘制实线曲线 ──────────────────────────────────────
            // 每次调用前都显式设置 [1,0]，确保不受之前 dash 状态影响
            function drawSolid(data, color, lw) {
                if (data.length < 2) return
                ctx.setLineDash([1, 0])
                ctx.strokeStyle = color
                ctx.lineWidth   = lw
                ctx.beginPath()
                var started = false
                for (var k = 0; k < data.length; k++) {
                    var pt = data[k]
                    if (pt.t < tMin) continue
                    var cx = mapX(pt.t)
                    var cy = Math.max(py, Math.min(py + ph, mapY(pt.v)))
                    if (!started) { ctx.moveTo(cx, cy); started = true }
                    else          { ctx.lineTo(cx, cy) }
                }
                ctx.stroke()
            }

            // ── 裁剪到绘图区 ──────────────────────────────────────
            ctx.save()
            ctx.beginPath(); ctx.rect(px, py, pw, ph); ctx.clip()

            // 反馈先画（橙色粗线），指令后画（青色细线）盖在上层
            drawSolid(root._feedData, root.feedColor, 2.0)
            drawSolid(root._cmdData,  root.cmdColor,  1.5)

            ctx.restore()

            // ── 标题 ──────────────────────────────────────────────
            ctx.fillStyle = "#e0e8f0"
            ctx.font      = "bold 11px sans-serif"
            ctx.textAlign = "center"
            var titleStr  = root.unit.length > 0
                            ? root.title + " (" + root.unit + ")"
                            : root.title
            ctx.fillText(titleStr, root.width / 2, root._tm - 5)

            // ── 图例 ──────────────────────────────────────────────
            var legX = px + pw - 76
            var legY = py + 6
            ctx.setLineDash([1, 0])

            // 反馈（橙色粗线）
            ctx.strokeStyle = root.feedColor
            ctx.lineWidth   = 2.0
            ctx.beginPath(); ctx.moveTo(legX, legY + 4); ctx.lineTo(legX + 18, legY + 4); ctx.stroke()
            ctx.fillStyle  = "#ccddee"
            ctx.font       = "10px sans-serif"
            ctx.textAlign  = "left"
            ctx.fillText("反馈", legX + 22, legY + 8)

            // 指令（青色细线）
            ctx.strokeStyle = root.cmdColor
            ctx.lineWidth   = 1.5
            ctx.beginPath(); ctx.moveTo(legX, legY + 16); ctx.lineTo(legX + 18, legY + 16); ctx.stroke()
            ctx.fillStyle  = "#ccddee"
            ctx.fillText("指令", legX + 22, legY + 20)
        }
    }
}
