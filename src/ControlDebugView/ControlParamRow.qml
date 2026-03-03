/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

// 控制参数调整行组件：角色标签 + 参数名下拉选择 + 实时值读写框

import QtQuick          2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.11

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

RowLayout {
    id:      root
    spacing: 4
    Layout.fillWidth: true

    // 角色标签（P / I / D / F）
    property string roleLabel:        "P"
    // 默认绑定的飞控参数名（可为空）
    property string defaultParamName: ""
    // 由父级传入的 FactPanelController 实例
    property var    factController:   null

    // ── PID 角色标签 ─────────────────────────────────────────────────
    QGCLabel {
        text:              root.roleLabel
        color:             "#aabbcc"
        font.pixelSize:    11
        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 1.5
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
        verticalAlignment: Text.AlignVCenter
    }

    // ── 参数名选择框（可编辑 ComboBox，支持直接输入任意参数名）──────
    ComboBox {
        id:       _combo
        editable: true
        model:    root.defaultParamName.length > 0 ? [root.defaultParamName] : [""]
        Layout.fillWidth:       true
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
        font.pixelSize: 11

        Component.onCompleted: editText = root.defaultParamName

        // 深色主题调色板
        palette.text:            "#ccddee"
        palette.base:            "#0d1020"
        palette.button:          "#0d1020"
        palette.window:          "#1a1a3e"
        palette.windowText:      "#ccddee"
        palette.highlight:       "#2a3a5e"
        palette.highlightedText: "#e0e8ff"

        background: Rectangle {
            color:        "#0d1020"
            border.color: _combo.activeFocus ? "#4488cc" : "#334466"
            border.width: 1
            radius:       2
        }

        delegate: ItemDelegate {
            width:       _combo.width
            height:      ScreenTools.defaultFontPixelHeight * 1.8
            highlighted: _combo.highlightedIndex === index
            contentItem: Text {
                text:              modelData
                color:             parent.highlighted ? "#e0e8ff" : "#ccddee"
                font.pixelSize:    11
                elide:             Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                leftPadding:       4
            }
            background: Rectangle {
                color: parent.highlighted ? "#2a3a5e" : "#0d1020"
            }
        }

        popup: Popup {
            y:              _combo.height
            width:          _combo.width
            padding:        1
            implicitHeight: _listView.contentHeight + 2
            contentItem: ListView {
                id:             _listView
                clip:           true
                model:          _combo.delegateModel
                implicitHeight: contentHeight
            }
            background: Rectangle {
                color:        "#0d1020"
                border.color: "#334466"
                border.width: 1
                radius:       2
            }
        }
    }

    // ── 参数当前值（自动从飞控读取，可编辑后回写飞控）────────────────
    TextField {
        id: _valueTF

        // 动态绑定 Fact 对象（随参数名变化而更新）
        property var _fact: {
            var n    = _combo.editText.trim()
            var ctrl = root.factController
            var av   = QGroundControl.multiVehicleManager.activeVehicle
            if (!av || !ctrl || !n) return null
            return ctrl.parameterExists(-1, n)
                   ? ctrl.getParameterFact(-1, n) : null
        }

        text:     _fact ? _fact.valueString : "---"
        color:    _fact ? "#e0e8ff" : "#445566"
        readOnly: !_fact

        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 9
        Layout.preferredHeight: ScreenTools.defaultFontPixelHeight * 1.5
        font.pixelSize:         11
        horizontalAlignment:    Text.AlignRight
        padding:      2
        leftPadding:  4
        rightPadding: 4

        // 编辑完成后将新值写回飞控，并重新绑定显示
        onEditingFinished: {
            if (_fact) {
                _fact.value = text
                text = Qt.binding(function() {
                    return _valueTF._fact ? _valueTF._fact.valueString : "---"
                })
            }
        }

        background: Rectangle {
            color:        "#0d1020"
            border.color: _valueTF.activeFocus ? "#4488cc"
                        : (_valueTF._fact      ? "#334466" : "#223344")
            border.width: 1
            radius:       2
        }
    }
}
