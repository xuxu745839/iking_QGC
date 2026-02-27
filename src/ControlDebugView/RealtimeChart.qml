/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

import QtQuick          2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.11

Item {
    id: root

    // ── 外部可配置属性 ───────────────────────────────────────────
    property string title:         ""
    property string unit:          ""
    /// 纵轴半程：yMax = +yAmplitude，yMin = -yAmplitude
    property real   yAmplitude:    180
    /// 滑条可调范围
    property real   yAmplMin:      1
    property real   yAmplMax:      500
    property real   timeWindowSec: 30
    property string cmdColor:      "#00CFFF"   ///< 指令（青色）
    property string feedColor:     "#FFA040"   ///< 反馈（橙色）

    // 由振幅自动推导 yMin / yMax，供 Canvas 使用
    readonly property real yMin: -yAmplitude
    readonly property real yMax:  yAmplitude

    // ── 内部数据缓冲区 ───────────────────────────────────────────
    property var  _cmdData:  []
    property var  _feedData: []
    property real _latestT:  0

    // ── Canvas 布局常量 ──────────────────────────────────────────
    readonly property int _lm: 52
    readonly property int _rm: 8
    readonly property int _tm: 20
    readonly property int _bm: 22

    // ── 公共接口 ─────────────────────────────────────────────────
    function appendData(t, cmdVal, feedVal) {
        _latestT = t
        var tCut = t - timeWindowSec - 0.5
        _cmdData.push({ t: t, v: cmdVal })
        _feedData.push({ t: t, v: feedVal })
        while (_cmdData.length  > 1 && _cmdData[0].t  < tCut) { _cmdData.shift()  }
        while (_feedData.length > 1 && _feedData[0].t < tCut) { _feedData.shift() }
    }

    function redraw() { canvas.requestPaint() }

    // ── 整体布局：Canvas + 右侧纵轴滑条列 ───────────────────────
    RowLayout {
        anchors.fill: parent
        spacing:      2

        // ── 曲线 Canvas ──────────────────────────────────────────
        Canvas {
            id: canvas
            Layout.fillWidth:  true
            Layout.fillHeight: true

            onPaint: {
                var ctx  = getContext("2d")
                var pw   = canvas.width  - root._lm - root._rm
                var ph   = canvas.height - root._tm - root._bm
                var px   = root._lm
                var py   = root._tm
                var yRng = root.yMax - root.yMin
                var tNow = root._latestT
                var tMin = tNow - root.timeWindowSec

                // 背景
                ctx.fillStyle = "#1c1c2e"
                ctx.fillRect(0, 0, canvas.width, canvas.height)
                ctx.fillStyle = "#13132a"
                ctx.fillRect(px, py, pw, ph)

                // 网格虚线
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
                ctx.setLineDash([1, 0])   // 恢复实线

                // Y 轴标签
                ctx.fillStyle = "#99aabb"
                ctx.font      = "10px monospace"
                ctx.textAlign = "right"
                for (i = 0; i <= nGY; i++) {
                    var lv = root.yMax - i * yRng / nGY
                    var ly = py + i * ph / nGY
                    ctx.fillText(lv.toFixed(0), px - 4, ly + 4)
                }

                // X 轴标签
                ctx.textAlign = "center"
                for (j = 0; j <= nGX; j++) {
                    var lx = px + j * pw / nGX
                    var dt = -root.timeWindowSec + j * root.timeWindowSec / nGX
                    ctx.fillText(dt.toFixed(0) + "s", lx, py + ph + 14)
                }

                // 边框
                ctx.strokeStyle = "#445566"
                ctx.lineWidth   = 1
                ctx.setLineDash([1, 0])
                ctx.beginPath(); ctx.rect(px, py, pw, ph); ctx.stroke()

                // 坐标映射
                function mapX(t) { return px + (t - tMin) / root.timeWindowSec * pw }
                function mapY(v) { return py + (1.0 - (v - root.yMin) / yRng) * ph  }

                // 绘制实线曲线
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

                // 裁剪 + 绘制（反馈先，指令后盖在上层）
                ctx.save()
                ctx.beginPath(); ctx.rect(px, py, pw, ph); ctx.clip()
                drawSolid(root._feedData, root.feedColor, 2.0)
                drawSolid(root._cmdData,  root.cmdColor,  1.5)
                ctx.restore()

                // 标题
                ctx.fillStyle = "#e0e8f0"
                ctx.font      = "bold 11px sans-serif"
                ctx.textAlign = "center"
                var titleStr  = root.unit.length > 0
                                ? root.title + " (" + root.unit + ")"
                                : root.title
                ctx.fillText(titleStr, canvas.width / 2, root._tm - 5)

                // 图例
                var legX = px + pw - 76
                var legY = py + 6
                ctx.setLineDash([1, 0])

                ctx.strokeStyle = root.feedColor; ctx.lineWidth = 2.0
                ctx.beginPath(); ctx.moveTo(legX, legY + 4); ctx.lineTo(legX + 18, legY + 4); ctx.stroke()
                ctx.fillStyle = "#ccddee"; ctx.font = "10px sans-serif"; ctx.textAlign = "left"
                ctx.fillText("反馈", legX + 22, legY + 8)

                ctx.strokeStyle = root.cmdColor; ctx.lineWidth = 1.5
                ctx.beginPath(); ctx.moveTo(legX, legY + 16); ctx.lineTo(legX + 18, legY + 16); ctx.stroke()
                ctx.fillStyle = "#ccddee"
                ctx.fillText("指令", legX + 22, legY + 20)
            }
        }

        // ── 纵轴范围调节列（垂直滑条） ───────────────────────────
        ColumnLayout {
            Layout.preferredWidth: 22
            Layout.fillHeight:     true
            spacing:               1

            // 当前振幅数值（上方显示 +yAmplitude）
            Text {
                Layout.alignment:  Qt.AlignHCenter
                text:              "+" + root.yAmplitude.toFixed(0)
                color:             "#88aacc"
                font.pixelSize:    9
                horizontalAlignment: Text.AlignHCenter
            }

            // 垂直滑条：from=大在上，to=小在下，直觉一致
            Slider {
                id:                amplSlider
                Layout.fillHeight: true
                Layout.alignment:  Qt.AlignHCenter
                orientation:       Qt.Vertical
                from:              root.yAmplMax
                to:                root.yAmplMin
                stepSize:          1
                value:             root.yAmplitude
                // 仅响应用户拖动，避免绑定循环
                onMoved:           root.yAmplitude = Math.round(value)

                background: Rectangle {
                    x:      amplSlider.leftPadding + amplSlider.availableWidth / 2 - width / 2
                    y:      amplSlider.topPadding
                    width:  4
                    height: amplSlider.availableHeight
                    radius: 2
                    color:  "#2a3a50"
                    // 已选范围着色（从当前位置到底部 = 从小到当前振幅）
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width:          parent.width
                        height:         (1.0 - amplSlider.visualPosition) * parent.height
                        color:          "#3a6090"
                        radius:         2
                    }
                }

                handle: Rectangle {
                    x:            amplSlider.leftPadding + amplSlider.availableWidth / 2 - width / 2
                    y:            amplSlider.topPadding + amplSlider.visualPosition * amplSlider.availableHeight - height / 2
                    width:        12
                    height:       12
                    radius:       6
                    color:        amplSlider.pressed ? "#88bbff" : "#5599ee"
                    border.color: "#224466"
                    border.width: 1
                }
            }

            // 最小振幅标签（下方显示最小可调值）
            Text {
                Layout.alignment:  Qt.AlignHCenter
                text:              root.yAmplMin.toFixed(0)
                color:             "#445566"
                font.pixelSize:    9
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
