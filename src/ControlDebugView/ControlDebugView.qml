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

    // ── 控制器实例 ─────────────────────────────────────────────
    ControlDebugController { id: debugCtrl }

    // ── 20 Hz 刷新定时器（与数据到达速率解耦，避免过度重绘） ──────
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

    // ── 接收新数据，追加到对应图表 ────────────────────────────────
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

    // ── 顶部标题栏 ────────────────────────────────────────────────
    Rectangle {
        id:     titleBar
        width:  parent.width
        height: ScreenTools.defaultFontPixelHeight * 2
        color:  "#1a1a3e"

        QGCLabel {
            anchors.centerIn: parent
            text:             qsTr("控制参数整定")
            font.pointSize:   ScreenTools.mediumFontPointSize
            font.family:      ScreenTools.demiboldFontFamily
            color:            "#e0e8ff"
        }
    }

    // ── 6 张图表（3列×2行） ────────────────────────────────────────
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
            id:             rollChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:          qsTr("滚转角")
            unit:           "°"
            yMin:           -180
            yMax:           180
        }

        RealtimeChart {
            id:             pitchChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:          qsTr("俯仰角")
            unit:           "°"
            yMin:           -90
            yMax:           90
        }

        RealtimeChart {
            id:             yawChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:          qsTr("航向角")
            unit:           "°"
            yMin:           -180
            yMax:           180
        }

        // 第二行：三个角速度图
        RealtimeChart {
            id:             rollRateChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:          qsTr("滚转角速度")
            unit:           "°/s"
            yMin:           -200
            yMax:           200
        }

        RealtimeChart {
            id:             pitchRateChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:          qsTr("俯仰角速度")
            unit:           "°/s"
            yMin:           -200
            yMax:           200
        }

        RealtimeChart {
            id:             yawRateChart
            Layout.fillWidth:  true
            Layout.fillHeight: true
            title:          qsTr("航向角速度")
            unit:           "°/s"
            yMin:           -200
            yMax:           200
        }
    }
}
