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

import QGroundControl               1.0
import QGroundControl.Palette       1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0
import QGroundControl.Controllers   1.0

Rectangle {
    id:     controlDebugView
    color:  "#111122"
    z:      QGroundControl.zOrderTopMost

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    // ── 全局时间窗口（秒），由顶部滑条控制，绑定到所有图表 ──────────
    property real _timeWindowSec: 30

    // ── 控制器实例 ─────────────────────────────────────────────────
    ControlDebugController { id: debugCtrl }

    // ── 20 Hz 刷新定时器 ────────────────────────────────────────────
    Timer {
        interval: 50
        running:  true
        repeat:   true
        onTriggered: {
            rollChart.redraw()
            pitchChart.redraw()
            yawChart.redraw()
            rollRateChart.redraw()
            pitchRateChart.redraw()
            yawRateChart.redraw()
        }
    }

    // ── 接收新数据，追加到对应图表 ──────────────────────────────────
    Connections {
        target: debugCtrl
        onDataUpdated: {
            rollChart.appendData     (t, cmdRoll,      feedRoll)
            pitchChart.appendData    (t, cmdPitch,     feedPitch)
            yawChart.appendData      (t, cmdYaw,       feedYaw)
            rollRateChart.appendData (t, cmdRollRate,  feedRollRate)
            pitchRateChart.appendData(t, cmdPitchRate, feedPitchRate)
            yawRateChart.appendData  (t, cmdYawRate,   feedYawRate)
        }
    }

    // ── 顶部标题 + 时间轴调节栏 ────────────────────────────────────
    Rectangle {
        id:     titleBar
        width:  parent.width
        height: ScreenTools.defaultFontPixelHeight * 2.6
        color:  "#1a1a3e"

        RowLayout {
            anchors.fill:        parent
            anchors.leftMargin:  ScreenTools.defaultFontPixelWidth * 2
            anchors.rightMargin: ScreenTools.defaultFontPixelWidth * 2
            spacing:             ScreenTools.defaultFontPixelWidth

            // 标题
            QGCLabel {
                text:           qsTr("姿态控制参数整定")
                font.pointSize: ScreenTools.mediumFontPointSize
                font.family:    ScreenTools.demiboldFontFamily
                color:          "#e0e8ff"
            }

            Item { Layout.fillWidth: true }

            // 时间轴标签
            QGCLabel {
                text:  qsTr("时间窗口：")
                color: "#aabbcc"
                font.pointSize: ScreenTools.defaultFontPointSize
            }

            // 时间轴滑条（5 s ~ 120 s，步长 5 s）
            Slider {
                id:                 timeSlider
                from:               5
                to:                 120
                stepSize:           5
                value:              controlDebugView._timeWindowSec
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 20
                onValueChanged:     controlDebugView._timeWindowSec = value

                background: Rectangle {
                    x:      timeSlider.leftPadding
                    y:      timeSlider.topPadding + timeSlider.availableHeight / 2 - height / 2
                    width:  timeSlider.availableWidth
                    height: 4
                    radius: 2
                    color:  "#334466"
                    Rectangle {
                        width:  timeSlider.visualPosition * parent.width
                        height: parent.height
                        color:  "#4488cc"
                        radius: 2
                    }
                }
                handle: Rectangle {
                    x:      timeSlider.leftPadding + timeSlider.visualPosition * timeSlider.availableWidth - width / 2
                    y:      timeSlider.topPadding  + timeSlider.availableHeight / 2 - height / 2
                    width:  14
                    height: 14
                    radius: 7
                    color:  timeSlider.pressed ? "#88bbff" : "#5599ee"
                }
            }

            // 当前时间窗口数值显示
            QGCLabel {
                text:           controlDebugView._timeWindowSec.toFixed(0) + " s"
                color:          "#88ccff"
                font.pointSize: ScreenTools.defaultFontPointSize
                Layout.preferredWidth: ScreenTools.defaultFontPixelWidth * 5
            }
        }
    }

    // ── 6 张图表（3列×2行） ─────────────────────────────────────────
    GridLayout {
        anchors.top:        titleBar.bottom
        anchors.left:       parent.left
        anchors.right:      parent.right
        anchors.bottom:     parent.bottom
        anchors.margins:    4
        columns:            3
        rowSpacing:         4
        columnSpacing:      4

        // 第一行：三个角度图
        RealtimeChart {
            id:                rollChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:             qsTr("滚转角")
            unit:              "°"
            yMin:              -30
            yMax:              30
            timeWindowSec:     controlDebugView._timeWindowSec
        }

        RealtimeChart {
            id:                pitchChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:             qsTr("俯仰角")
            unit:              "°"
            yMin:              -30
            yMax:              30
            timeWindowSec:     controlDebugView._timeWindowSec
        }

        RealtimeChart {
            id:                yawChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:             qsTr("航向角")
            unit:              "°"
            yMin:              -180
            yMax:              180
            timeWindowSec:     controlDebugView._timeWindowSec
        }

        // 第二行：三个角速度图
        RealtimeChart {
            id:                rollRateChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:             qsTr("滚转角速度")
            unit:              "°/s"
            yMin:              -50
            yMax:              50
            timeWindowSec:     controlDebugView._timeWindowSec
        }

        RealtimeChart {
            id:                pitchRateChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:             qsTr("俯仰角速度")
            unit:              "°/s"
            yMin:              -50
            yMax:              50
            timeWindowSec:     controlDebugView._timeWindowSec
        }

        RealtimeChart {
            id:                yawRateChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:             qsTr("航向角速度")
            unit:              "°/s"
            yMin:              -50
            yMax:              50
            timeWindowSec:     controlDebugView._timeWindowSec
        }
    }
}
