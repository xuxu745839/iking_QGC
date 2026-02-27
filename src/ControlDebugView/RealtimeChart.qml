/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

/**
 * RealtimeChart.qml
 *
 * 实时双曲线滚动图表组件。
 *   - cmdColor  (青色)  ：指令曲线
 *   - feedColor (橙色)  ：反馈曲线
 *
 * 使用方法：
 *   1. 调用 appendData(t, cmdVal, feedVal) 追加数据点
 *   2. 调用 redraw() 触发重绘（通常由外部 Timer 以固定频率调用）
 */

import QtQuick 2.11

Item {
    id: root

    // ---- 外部可配置属性 ----
    property string title:          ""          ///< 图表标题
    property string unit:           ""          ///< Y 轴单位（显示在标题括号内）
    property real   yMin:           -180        ///< Y 轴最小值
    property real   yMax:           180         ///< Y 轴最大值
    property real   timeWindowSec:  30          ///< 显示最近 N 秒的数据
    property string cmdColor:       "#00CFFF"   ///< 指令曲线颜色（青色）
    property string feedColor:      "#FFA040"   ///< 反馈曲线颜色（橙色）

    // ---- 内部数据缓冲区（JS 数组，每条 {t, v}） ----
    property var _cmdData:  []
    property var _feedData: []
    property real _latestT: 0

    // ---- 布局常量 ----
    readonly property int _lm: 52   ///< 左边距（Y轴标签）
    readonly property int _rm: 8    ///< 右边距
    readonly property int _tm: 20   ///< 上边距（标题）
    readonly property int _bm: 22   ///< 下边距（X轴标签）

    // ---- 公共接口 ----

    /// 追加一组数据点
    function appendData(t, cmdVal, feedVal) {
        _latestT = t
        var tCut  = t - timeWindowSec - 0.5  // 多保留 0.5s 避免曲线首端截断

        _cmdData.push({ t: t, v: cmdVal })
        _feedData.push({ t: t, v: feedVal })

        // 丢弃超出时间窗口的旧数据
        while (_cmdData.length  > 1 && _cmdData[0].t  < tCut) { _cmdData.shift()  }
        while (_feedData.length > 1 && _feedData[0].t < tCut) { _feedData.shift() }
    }

    /// 触发重绘
    function redraw() {
        canvas.requestPaint()
    }

    // ---- Canvas 绘图 ----
    Canvas {
        id: canvas
        anchors.fill: parent

        onPaint: {
            var ctx = getContext("2d")

            // 绘图区尺寸
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

            // ── 网格（5×4） ───────────────────────────────────────
            var nGX = 5
            var nGY = 4
            ctx.strokeStyle = "#253050"
            ctx.lineWidth   = 1
            ctx.setLineDash([3, 3])

            var i, j
            for (i = 0; i <= nGY; i++) {
                var gy = py + i * ph / nGY
                ctx.beginPath(); ctx.moveTo(px, gy); ctx.lineTo(px + pw, gy); ctx.stroke()
            }
            for (j = 0; j <= nGX; j++) {
                var gx = px + j * pw / nGX
                ctx.beginPath(); ctx.moveTo(gx, py); ctx.lineTo(gx, py + ph); ctx.stroke()
            }
            ctx.setLineDash([])

            // ── Y 轴标签 ──────────────────────────────────────────
            ctx.fillStyle  = "#99aabb"
            ctx.font       = "10px monospace"
            ctx.textAlign  = "right"
            for (i = 0; i <= nGY; i++) {
                var labelVal = root.yMax - i * yRng / nGY
                var labelY   = py + i * ph / nGY
                ctx.fillText(labelVal.toFixed(0), px - 4, labelY + 4)
            }

            // ── X 轴标签 ──────────────────────────────────────────
            ctx.textAlign = "center"
            for (j = 0; j <= nGX; j++) {
                var labelX  = px + j * pw / nGX
                var dtLabel = -root.timeWindowSec + j * root.timeWindowSec / nGX
                ctx.fillText(dtLabel.toFixed(0) + "s", labelX, py + ph + 14)
            }

            // ── 边框 ──────────────────────────────────────────────
            ctx.strokeStyle = "#445566"
            ctx.lineWidth   = 1
            ctx.beginPath()
            ctx.rect(px, py, pw, ph)
            ctx.stroke()

            // ── 坐标映射函数 ──────────────────────────────────────
            function mapX(t) { return px + (t - tMin) / root.timeWindowSec * pw }
            function mapY(v) { return py + (1.0 - (v - root.yMin) / yRng) * ph  }

            // ── 裁剪到绘图区 ──────────────────────────────────────
            ctx.save()
            ctx.beginPath()
            ctx.rect(px, py, pw, ph)
            ctx.clip()

            // ── 绘制曲线 ─────────────────────────────────────────
            function drawCurve(data, color, dashArr) {
                if (data.length < 2) return
                ctx.strokeStyle = color
                ctx.lineWidth   = 1.5
                ctx.setLineDash(dashArr || [])
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
                ctx.setLineDash([])
            }

            drawCurve(root._cmdData,  root.cmdColor,  [6, 3])   // 指令：虚线
            drawCurve(root._feedData, root.feedColor, [])        // 反馈：实线

            ctx.restore()

            // ── 标题 ──────────────────────────────────────────────
            ctx.fillStyle  = "#e0e8f0"
            ctx.font       = "bold 11px sans-serif"
            ctx.textAlign  = "center"
            var titleText  = root.unit.length > 0
                             ? root.title + " (" + root.unit + ")"
                             : root.title
            ctx.fillText(titleText, root.width / 2, root._tm - 5)

            // ── 图例 ──────────────────────────────────────────────
            var legX = px + pw - 76
            var legY = py + 6

            // 指令（虚线 + 文字）
            ctx.strokeStyle = root.cmdColor
            ctx.lineWidth   = 1.5
            ctx.setLineDash([5, 3])
            ctx.beginPath(); ctx.moveTo(legX, legY + 4); ctx.lineTo(legX + 18, legY + 4); ctx.stroke()
            ctx.setLineDash([])
            ctx.fillStyle  = "#ccddee"
            ctx.font       = "10px sans-serif"
            ctx.textAlign  = "left"
            ctx.fillText("指令", legX + 22, legY + 8)

            // 反馈（实线 + 文字）
            ctx.strokeStyle = root.feedColor
            ctx.lineWidth   = 1.5
            ctx.beginPath(); ctx.moveTo(legX, legY + 16); ctx.lineTo(legX + 18, legY + 16); ctx.stroke()
            ctx.fillStyle  = "#ccddee"
            ctx.fillText("反馈", legX + 22, legY + 20)
        }
    }
}
