package com.mplay.mplay

import android.content.ContentValues
import android.content.Intent
import android.media.audiofx.AudioEffect
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : AudioServiceActivity() {
	private val audioFxChannel = "mplay/audio_fx"
	private val lyricsStorageChannel = "mplay/lyrics_storage"
	private val lyricsRelativePath = "${Environment.DIRECTORY_DOCUMENTS}/lyrics/"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, audioFxChannel)
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

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, lyricsStorageChannel)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"writeLyricsFiles" -> {
						val baseName = call.argument<String>("baseName")
						val jsonContent = call.argument<String>("jsonContent")
						val lrcContent = call.argument<String>("lrcContent")

						if (baseName.isNullOrBlank() || jsonContent == null) {
							result.success(false)
							return@setMethodCallHandler
						}

						try {
							val jsonOk = upsertPublicTextFile("$baseName.json", "application/json", jsonContent)
							val lrcOk = if (!lrcContent.isNullOrBlank()) {
								upsertPublicTextFile("$baseName.lrc", "text/plain", lrcContent)
							} else {
								deletePublicFileIfExists("$baseName.lrc")
								true
							}
							result.success(jsonOk && lrcOk)
						} catch (_: Exception) {
							result.success(false)
						}
					}

					"readLyricsJson" -> {
						val baseName = call.argument<String>("baseName")
						if (baseName.isNullOrBlank()) {
							result.success(null)
							return@setMethodCallHandler
						}

						try {
							result.success(readPublicTextFile("$baseName.json"))
						} catch (_: Exception) {
							result.success(null)
						}
					}

					else -> result.notImplemented()
				}
			}
	}

	private fun upsertPublicTextFile(displayName: String, mimeType: String, content: String): Boolean {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
			val existingUri = findPublicFileUri(displayName)
			val uri = existingUri ?: run {
				val values = ContentValues().apply {
					put(MediaStore.MediaColumns.DISPLAY_NAME, displayName)
					put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
					put(MediaStore.MediaColumns.RELATIVE_PATH, lyricsRelativePath)
				}
				contentResolver.insert(collection, values)
			} ?: return false

			contentResolver.openOutputStream(uri, "wt")?.use { output ->
				output.write(content.toByteArray(Charsets.UTF_8))
			} ?: return false

			return true
		}

		@Suppress("DEPRECATION")
		val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "lyrics")
		if (!dir.exists()) {
			dir.mkdirs()
		}
		val file = File(dir, displayName)
		file.writeText(content, Charsets.UTF_8)
		return true
	}

	private fun readPublicTextFile(displayName: String): String? {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val uri = findPublicFileUri(displayName) ?: return null
			return contentResolver.openInputStream(uri)?.bufferedReader(Charsets.UTF_8)?.use { it.readText() }
		}

		@Suppress("DEPRECATION")
		val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "lyrics")
		val file = File(dir, displayName)
		if (!file.exists()) return null
		return file.readText(Charsets.UTF_8)
	}

	private fun deletePublicFileIfExists(displayName: String) {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val uri = findPublicFileUri(displayName) ?: return
			contentResolver.delete(uri, null, null)
			return
		}

		@Suppress("DEPRECATION")
		val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "lyrics")
		val file = File(dir, displayName)
		if (file.exists()) {
			file.delete()
		}
	}

	private fun findPublicFileUri(displayName: String): android.net.Uri? {
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
			val collection = MediaStore.Files.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
			val projection = arrayOf(MediaStore.MediaColumns._ID)
			val selection = "${MediaStore.MediaColumns.DISPLAY_NAME}=? AND ${MediaStore.MediaColumns.RELATIVE_PATH}=?"
			val args = arrayOf(displayName, lyricsRelativePath)

			contentResolver.query(collection, projection, selection, args, null)?.use { cursor ->
				if (cursor.moveToFirst()) {
					val id = cursor.getLong(cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID))
					return android.net.Uri.withAppendedPath(collection, id.toString())
				}
			}
			return null
		}

		@Suppress("DEPRECATION")
		val dir = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOCUMENTS), "lyrics")
		val file = File(dir, displayName)
		return if (file.exists()) android.net.Uri.fromFile(file) else null
	}
}
