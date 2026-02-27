/****************************************************************************
 *
 * (c) 2009-2020 QGROUNDCONTROL PROJECT <http://www.qgroundcontrol.org>
 *
 * QGroundControl is licensed according to the terms in the file
 * COPYING.md in the root of the source code directory.
 *
 ****************************************************************************/

#pragma once

#include <QObject>
#include <QElapsedTimer>
#include "Vehicle.h"

class LinkInterface;

/// 控制调试控制器
/// 订阅 ATTITUDE 和 ATTITUDE_TARGET MAVLink 消息，向 QML 提供角度/角速度的
/// 指令值与反馈值（单位：度 / 度每秒）。
class ControlDebugController : public QObject
{
    Q_OBJECT

    // --- 反馈值 (ATTITUDE) ---
    Q_PROPERTY(double feedRoll      READ feedRoll      NOTIFY attitudeUpdated)
    Q_PROPERTY(double feedPitch     READ feedPitch     NOTIFY attitudeUpdated)
    Q_PROPERTY(double feedYaw       READ feedYaw       NOTIFY attitudeUpdated)
    Q_PROPERTY(double feedRollRate  READ feedRollRate  NOTIFY attitudeUpdated)
    Q_PROPERTY(double feedPitchRate READ feedPitchRate NOTIFY attitudeUpdated)
    Q_PROPERTY(double feedYawRate   READ feedYawRate   NOTIFY attitudeUpdated)

    // --- 指令值 (ATTITUDE_TARGET) ---
    Q_PROPERTY(double cmdRoll       READ cmdRoll       NOTIFY targetUpdated)
    Q_PROPERTY(double cmdPitch      READ cmdPitch      NOTIFY targetUpdated)
    Q_PROPERTY(double cmdYaw        READ cmdYaw        NOTIFY targetUpdated)
    Q_PROPERTY(double cmdRollRate   READ cmdRollRate   NOTIFY targetUpdated)
    Q_PROPERTY(double cmdPitchRate  READ cmdPitchRate  NOTIFY targetUpdated)
    Q_PROPERTY(double cmdYawRate    READ cmdYawRate    NOTIFY targetUpdated)

public:
    explicit ControlDebugController(QObject* parent = nullptr);

    double feedRoll()      const { return _feedRoll; }
    double feedPitch()     const { return _feedPitch; }
    double feedYaw()       const { return _feedYaw; }
    double feedRollRate()  const { return _feedRollRate; }
    double feedPitchRate() const { return _feedPitchRate; }
    double feedYawRate()   const { return _feedYawRate; }

    double cmdRoll()       const { return _cmdRoll; }
    double cmdPitch()      const { return _cmdPitch; }
    double cmdYaw()        const { return _cmdYaw; }
    double cmdRollRate()   const { return _cmdRollRate; }
    double cmdPitchRate()  const { return _cmdPitchRate; }
    double cmdYawRate()    const { return _cmdYawRate; }

    /// 返回控制器创建后经过的秒数，用作图表横轴时间戳
    Q_INVOKABLE double elapsedSeconds() const;

signals:
    void attitudeUpdated();
    void targetUpdated();

    /// 每收到一条 ATTITUDE 消息后发出，携带当前时间戳及全部 12 个数值
    void dataUpdated(double t,
                     double feedRoll,    double cmdRoll,
                     double feedPitch,   double cmdPitch,
                     double feedYaw,     double cmdYaw,
                     double feedRollRate,   double cmdRollRate,
                     double feedPitchRate,  double cmdPitchRate,
                     double feedYawRate,    double cmdYawRate);

private slots:
    void _mavlinkMessageReceived(LinkInterface* link, mavlink_message_t message);
    void _activeVehicleChanged(Vehicle* vehicle);

private:
    /// 四元数（w,x,y,z）转欧拉角（弧度）
    static void _quatToEuler(const float q[4], double& roll, double& pitch, double& yaw);

    Vehicle*      _activeVehicle = nullptr;
    QElapsedTimer _elapsed;

    double _feedRoll = 0, _feedPitch = 0, _feedYaw = 0;
    double _feedRollRate = 0, _feedPitchRate = 0, _feedYawRate = 0;
    double _cmdRoll = 0, _cmdPitch = 0, _cmdYaw = 0;
    double _cmdRollRate = 0, _cmdPitchRate = 0, _cmdYawRate = 0;
};
