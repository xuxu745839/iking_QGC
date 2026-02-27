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

Rectangle {
    id:     controlDebugView
    color:  qgcPal.window
    z:      QGroundControl.zOrderTopMost

    QGCPalette { id: qgcPal; colorGroupEnabled: true }

    readonly property real  _defaultTextHeight:     ScreenTools.defaultFontPixelHeight
    readonly property real  _defaultTextWidth:       ScreenTools.defaultFontPixelWidth
    readonly property real  _margins:               ScreenTools.defaultFontPixelWidth

    ColumnLayout {
        anchors.fill:       parent
        anchors.margins:    _margins
        spacing:            _defaultTextHeight

        QGCLabel {
            Layout.fillWidth:   true
            text:               qsTr("控制参数整定")
            font.pointSize:     ScreenTools.largeFontPointSize
            font.family:        ScreenTools.demiboldFontFamily
            horizontalAlignment: Text.AlignHCenter
        }

        Rectangle {
            Layout.fillWidth:   true
            height:             1
            color:              qgcPal.text
            opacity:            0.5
        }

        QGCLabel {
            Layout.fillWidth:   true
            text:               qsTr("此视图用于控制参数整定功能。")
            wrapMode:           Text.WordWrap
        }

        Item { Layout.fillHeight: true }
    }
}
