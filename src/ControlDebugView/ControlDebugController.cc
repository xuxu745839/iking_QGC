/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#include "ControlDebugController.h"
#include "MAVLinkProtocol.h"
#include "MultiVehicleManager.h"
#include "QGCApplication.h"

#include <QtMath>

ControlDebugController::ControlDebugController(QObject* parent)
    : QObject(parent)
{
    _elapsed.start();

    // 订阅所有 MAVLink 消息
    MAVLinkProtocol* mavlinkProtocol = qgcApp()->toolbox()->mavlinkProtocol();
    connect(mavlinkProtocol, &MAVLinkProtocol::messageReceived,
            this, &ControlDebugController::_mavlinkMessageReceived);

    // 跟踪当前活跃飞机，用于过滤 sysid
    MultiVehicleManager* mgr = qgcApp()->toolbox()->multiVehicleManager();
    connect(mgr, &MultiVehicleManager::activeVehicleChanged,
            this, &ControlDebugController::_activeVehicleChanged);
    _activeVehicleChanged(mgr->activeVehicle());
}

double ControlDebugController::elapsedSeconds() const
{
    return _elapsed.elapsed() / 1000.0;
}

void ControlDebugController::_activeVehicleChanged(Vehicle* vehicle)
{
    _activeVehicle = vehicle;
}

void ControlDebugController::_quatToEuler(const float q[4],
                                           double& roll, double& pitch, double& yaw)
{
    // MAVLink 四元数顺序：w, x, y, z
    double w = static_cast<double>(q[0]);
    double x = static_cast<double>(q[1]);
    double y = static_cast<double>(q[2]);
    double z = static_cast<double>(q[3]);

    roll  = atan2(2.0 * (w * x + y * z), 1.0 - 2.0 * (x * x + y * y));
    double sinp = qBound(-1.0, 2.0 * (w * y - z * x), 1.0);
    pitch = asin(sinp);
    yaw   = atan2(2.0 * (w * z + x * y), 1.0 - 2.0 * (y * y + z * z));
}

void ControlDebugController::_mavlinkMessageReceived(LinkInterface*, mavlink_message_t message)
{
    // 仅处理当前活跃飞机的消息
    if (_activeVehicle && message.sysid != static_cast<uint8_t>(_activeVehicle->id())) {
        return;
    }

    if (message.msgid == MAVLINK_MSG_ID_ATTITUDE) {
        mavlink_attitude_t att;
        mavlink_msg_attitude_decode(&message, &att);

        _feedRoll      = qRadiansToDegrees(static_cast<double>(att.roll));
        _feedPitch     = qRadiansToDegrees(static_cast<double>(att.pitch));
        _feedYaw       = qRadiansToDegrees(static_cast<double>(att.yaw));
        _feedRollRate  = qRadiansToDegrees(static_cast<double>(att.rollspeed));
        _feedPitchRate = qRadiansToDegrees(static_cast<double>(att.pitchspeed));
        _feedYawRate   = qRadiansToDegrees(static_cast<double>(att.yawspeed));

        emit attitudeUpdated();

        double t = _elapsed.elapsed() / 1000.0;
        emit dataUpdated(t,
                         _feedRoll,     _cmdRoll,
                         _feedPitch,    _cmdPitch,
                         _feedYaw,      _cmdYaw,
                         _feedRollRate,   _cmdRollRate,
                         _feedPitchRate,  _cmdPitchRate,
                         _feedYawRate,    _cmdYawRate);
    }
    else if (message.msgid == MAVLINK_MSG_ID_ATTITUDE_TARGET) {
        mavlink_attitude_target_t tgt;
        mavlink_msg_attitude_target_decode(&message, &tgt);

        double roll, pitch, yaw;
        _quatToEuler(tgt.q, roll, pitch, yaw);

        _cmdRoll      = qRadiansToDegrees(roll);
        _cmdPitch     = qRadiansToDegrees(pitch);
        _cmdYaw       = qRadiansToDegrees(yaw);
        _cmdRollRate  = qRadiansToDegrees(static_cast<double>(tgt.body_roll_rate));
        _cmdPitchRate = qRadiansToDegrees(static_cast<double>(tgt.body_pitch_rate));
        _cmdYawRate   = qRadiansToDegrees(static_cast<double>(tgt.body_yaw_rate));

        emit targetUpdated();
    }
}
