import QtQuick          2.11
import QtQuick.Controls 2.4
import QtQuick.Layouts  1.11

import QGroundControl               1.0
import QGroundControl.Controls      1.0
import QGroundControl.ScreenTools   1.0

RowLayout {
    id:      root
    spacing: 6
    Layout.fillWidth: true

    // 角色标签（P / I / D / F）
    property string roleLabel:        "P"
    // 默认绑定的飞控参数名（可为空）
    property string defaultParamName: ""
    // 由父级传入的 FactPanelController 实例
    property var    factController:   null

    // ---- 关键：统一行高（你可以调 2.0~2.6 之间）
    readonly property int _rowH:  Math.round(ScreenTools.defaultFontPixelHeight * 2.25)
    readonly property int _fontPx: 11

    // 让布局系统知道这一行需要多高
    implicitHeight: _rowH
    Layout.minimumHeight: _rowH
    Layout.preferredHeight: _rowH

    // ── PID 角色标签 ───────────────────────────────────────────
    QGCLabel {
        text:           root.roleLabel
        color:          "#aabbcc"
        font.pixelSize: root._fontPx

        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 1.7
        Layout.minimumHeight:   root._rowH
        Layout.preferredHeight: root._rowH

        verticalAlignment: Text.AlignVCenter
        horizontalAlignment: Text.AlignHCenter
    }

    // ── 参数名选择框（可编辑 ComboBox）──────────────────────────
    ComboBox {
        id:       _combo
        editable: true
        model:    root.defaultParamName.length > 0 ? [root.defaultParamName] : [""]

        Layout.fillWidth:       true
        Layout.minimumHeight:   root._rowH
        Layout.preferredHeight: root._rowH

        font.pixelSize: root._fontPx

        Component.onCompleted: editText = root.defaultParamName

        // 深色主题调色板
        palette.text:            "#ccddee"
        palette.base:            "#0d1020"
        palette.button:          "#0d1020"
        palette.window:          "#1a1a3e"
        palette.windowText:      "#ccddee"
        palette.highlight:       "#2a3a5e"
        palette.highlightedText: "#e0e8ff"

        // 关键：把输入区的上下 padding 调大一点，避免文字贴边
        contentItem: TextInput {
            text: _combo.editText
            color: "#ccddee"
            font.pixelSize: root._fontPx
            verticalAlignment: Text.AlignVCenter
            leftPadding: 6
            rightPadding: 18   // 给右侧箭头留空间
            clip: true

            // 让编辑行为仍然归 ComboBox 管（保持原功能）
            readOnly: !_combo.editable
            selectByMouse: true
            validator: _combo.validator
            inputMethodHints: _combo.inputMethodHints

            onTextEdited: _combo.editText = text
        }

        background: Rectangle {
            implicitHeight: root._rowH
            color:        "#0d1020"
            border.color: _combo.activeFocus ? "#4488cc" : "#334466"
            border.width: 1
            radius:       3
        }

        delegate: ItemDelegate {
            width:  _combo.width
            height: Math.round(ScreenTools.defaultFontPixelHeight * 2.0)
            highlighted: _combo.highlightedIndex === index

            contentItem: Text {
                text:              modelData
                color:             parent.highlighted ? "#e0e8ff" : "#ccddee"
                font.pixelSize:    root._fontPx
                elide:             Text.ElideRight
                verticalAlignment: Text.AlignVCenter
                leftPadding:       6
            }
            background: Rectangle {
                color: parent.highlighted ? "#2a3a5e" : "#0d1020"
            }
        }

        popup: Popup {
            y:              _combo.height
            width:          _combo.width
            padding:        1
            implicitHeight: Math.min(_listView.contentHeight + 2,
                                     ScreenTools.defaultFontPixelHeight * 18)

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
                radius:       3
            }
        }
    }

    // ── 参数当前值（自动读取，可编辑回写）──────────────────────────
    TextField {
        id: _valueTF

        property var _fact: {
            var n    = _combo.editText.trim()
            var ctrl = root.factController
            var av   = QGroundControl.multiVehicleManager.activeVehicle
            if (!av || !ctrl || !n) return null
            // 显式访问 parametersReady，让 QML 将其注册为绑定依赖项。
            // 当飞控参数下载完成时，binding 会自动重新求值。
            if (!av.parameterManager.parametersReady) return null
            return ctrl.parameterExists(-1, n)
                   ? ctrl.getParameterFact(-1, n) : null
        }

        text:     _fact ? _fact.valueString : "---"
        color:    _fact ? "#e0e8ff" : "#445566"
        readOnly: !_fact

        Layout.preferredWidth:  ScreenTools.defaultFontPixelWidth * 9
        Layout.minimumHeight:   root._rowH
        Layout.preferredHeight: root._rowH

        font.pixelSize:      root._fontPx
        horizontalAlignment: Text.AlignRight
        verticalAlignment:   Text.AlignVCenter

        padding:      4
        leftPadding:  6
        rightPadding: 6

        onEditingFinished: {
            if (_fact) {
                _fact.value = text
                text = Qt.binding(function() {
                    return _valueTF._fact ? _valueTF._fact.valueString : "---"
                })
            }
        }

        background: Rectangle {
            implicitHeight: root._rowH
            color:        "#0d1020"
            border.color: _valueTF.activeFocus ? "#4488cc"
                        : (_valueTF._fact      ? "#334466" : "#223344")
            border.width: 1
            radius:       3
        }
    }
}