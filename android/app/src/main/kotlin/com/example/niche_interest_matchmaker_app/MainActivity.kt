package com.example.niche_interest_matchmaker_app

import android.content.Context
import android.hardware.Sensor
import android.hardware.SensorEvent
import android.hardware.SensorEventListener
import android.hardware.SensorManager
import android.view.Surface
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import kotlin.math.abs
import kotlin.math.roundToInt

class MainActivity : FlutterActivity() {
    private val headingChannelName = "niche_interest_matchmaker/device_heading"
    private var headingStreamHandler: DeviceHeadingStreamHandler? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        headingStreamHandler = DeviceHeadingStreamHandler(this)
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            headingChannelName
        ).setStreamHandler(headingStreamHandler)
    }

    override fun onDestroy() {
        headingStreamHandler?.stop()
        headingStreamHandler = null
        super.onDestroy()
    }
}

private class DeviceHeadingStreamHandler(
    private val context: Context
) : EventChannel.StreamHandler, SensorEventListener {
    private val sensorManager =
        context.getSystemService(Context.SENSOR_SERVICE) as SensorManager
    private val rotationVectorSensor =
        sensorManager.getDefaultSensor(Sensor.TYPE_ROTATION_VECTOR)
    private val accelerometerSensor =
        sensorManager.getDefaultSensor(Sensor.TYPE_ACCELEROMETER)
    private val magneticSensor =
        sensorManager.getDefaultSensor(Sensor.TYPE_MAGNETIC_FIELD)

    private var eventSink: EventChannel.EventSink? = null
    private var lastHeading: Float? = null
    private var lastSentHeading: Float? = null
    private var lastSentAt = 0L
    private var gravityValues: FloatArray? = null
    private var magneticValues: FloatArray? = null

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
        start()
    }

    override fun onCancel(arguments: Any?) {
        stop()
        eventSink = null
    }

    fun start() {
        stop()
        if (rotationVectorSensor != null) {
            sensorManager.registerListener(
                this,
                rotationVectorSensor,
                SensorManager.SENSOR_DELAY_UI
            )
            return
        }

        if (accelerometerSensor != null && magneticSensor != null) {
            sensorManager.registerListener(
                this,
                accelerometerSensor,
                SensorManager.SENSOR_DELAY_UI
            )
            sensorManager.registerListener(
                this,
                magneticSensor,
                SensorManager.SENSOR_DELAY_UI
            )
        } else {
            eventSink?.error(
                "COMPASS_UNAVAILABLE",
                "This device does not expose compass sensors.",
                null
            )
        }
    }

    fun stop() {
        sensorManager.unregisterListener(this)
        gravityValues = null
        magneticValues = null
    }

    override fun onAccuracyChanged(sensor: Sensor?, accuracy: Int) = Unit

    override fun onSensorChanged(event: SensorEvent) {
        when (event.sensor.type) {
            Sensor.TYPE_ROTATION_VECTOR -> {
                val rotationMatrix = FloatArray(9)
                SensorManager.getRotationMatrixFromVector(rotationMatrix, event.values)
                emitHeading(rotationMatrix)
            }
            Sensor.TYPE_ACCELEROMETER -> {
                gravityValues = lowPass(event.values, gravityValues)
                emitFallbackHeading()
            }
            Sensor.TYPE_MAGNETIC_FIELD -> {
                magneticValues = lowPass(event.values, magneticValues)
                emitFallbackHeading()
            }
        }
    }

    private fun emitFallbackHeading() {
        val gravity = gravityValues ?: return
        val magnetic = magneticValues ?: return
        val rotationMatrix = FloatArray(9)
        val success = SensorManager.getRotationMatrix(
            rotationMatrix,
            null,
            gravity,
            magnetic
        )
        if (success) emitHeading(rotationMatrix)
    }

    private fun emitHeading(rotationMatrix: FloatArray) {
        val adjustedMatrix = FloatArray(9)
        when (context.displayRotation()) {
            Surface.ROTATION_90 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_Y,
                SensorManager.AXIS_MINUS_X,
                adjustedMatrix
            )
            Surface.ROTATION_180 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_MINUS_X,
                SensorManager.AXIS_MINUS_Y,
                adjustedMatrix
            )
            Surface.ROTATION_270 -> SensorManager.remapCoordinateSystem(
                rotationMatrix,
                SensorManager.AXIS_MINUS_Y,
                SensorManager.AXIS_X,
                adjustedMatrix
            )
            else -> {
                System.arraycopy(rotationMatrix, 0, adjustedMatrix, 0, rotationMatrix.size)
            }
        }

        val orientation = FloatArray(3)
        SensorManager.getOrientation(adjustedMatrix, orientation)
        val rawHeading = normalizeDegrees(Math.toDegrees(orientation[0].toDouble()).toFloat())
        val smoothedHeading = smoothHeading(lastHeading, rawHeading)
        lastHeading = smoothedHeading

        val now = System.currentTimeMillis()
        val previousSent = lastSentHeading
        if (
            previousSent == null ||
            now - lastSentAt >= 120L &&
            angularDistance(previousSent, smoothedHeading) >= 1.0f
        ) {
            lastSentAt = now
            lastSentHeading = smoothedHeading
            eventSink?.success((smoothedHeading * 10).roundToInt() / 10.0)
        }
    }

    private fun lowPass(values: FloatArray, previous: FloatArray?): FloatArray {
        if (previous == null) return values.clone()
        val alpha = 0.18f
        return FloatArray(values.size) { index ->
            previous[index] + alpha * (values[index] - previous[index])
        }
    }

    private fun smoothHeading(previous: Float?, current: Float): Float {
        if (previous == null) return current
        val delta = ((current - previous + 540f) % 360f) - 180f
        return normalizeDegrees(previous + delta * 0.28f)
    }

    private fun angularDistance(a: Float, b: Float): Float {
        return abs(((b - a + 540f) % 360f) - 180f)
    }

    private fun normalizeDegrees(value: Float): Float {
        return (value % 360f + 360f) % 360f
    }
}

private fun Context.displayRotation(): Int {
    return if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.R) {
        display?.rotation ?: Surface.ROTATION_0
    } else {
        @Suppress("DEPRECATION")
        (getSystemService(Context.WINDOW_SERVICE) as android.view.WindowManager)
            .defaultDisplay
            .rotation
    }
}
