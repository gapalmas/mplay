package com.mplay.mplay

import android.content.Intent
import android.media.audiofx.AudioEffect
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "mplay/audio_fx"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"openEqualizer" -> {
						val sessionId = call.argument<Int>("sessionId")
						if (sessionId == null || sessionId <= 0) {
							result.success(false)
							return@setMethodCallHandler
						}

						val intent = Intent(AudioEffect.ACTION_DISPLAY_AUDIO_EFFECT_CONTROL_PANEL).apply {
							putExtra(AudioEffect.EXTRA_AUDIO_SESSION, sessionId)
							putExtra(AudioEffect.EXTRA_PACKAGE_NAME, packageName)
							putExtra(AudioEffect.EXTRA_CONTENT_TYPE, AudioEffect.CONTENT_TYPE_MUSIC)
						}

						if (intent.resolveActivity(packageManager) != null) {
							startActivity(intent)
							result.success(true)
						} else {
							result.success(false)
						}
					}

					else -> result.notImplemented()
				}
			}
	}
}
