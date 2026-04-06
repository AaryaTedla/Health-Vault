package com.teamtesla.healthvault

import android.content.Intent
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)

		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "healthvault/native_intent")
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"callPhoneNumber" -> {
						val phoneNumber = call.argument<String>("phoneNumber")?.trim().orEmpty()
						if (phoneNumber.isEmpty()) {
							result.success(false)
							return@setMethodCallHandler
						}

						val intent = Intent(Intent.ACTION_DIAL).apply {
							data = Uri.parse("tel:$phoneNumber")
						}
						startActivity(intent)
						result.success(true)
					}

					"composeSms" -> {
						val recipients = call.argument<List<*>>("recipients")
							?.mapNotNull { it?.toString()?.trim() }
							?.filter { it.isNotEmpty() }
							.orEmpty()
						val message = call.argument<String>("message") ?: ""
						if (recipients.isEmpty()) {
							result.success(false)
							return@setMethodCallHandler
						}

						val uri = Uri.parse("smsto:${recipients.joinToString(separator = ";")}")
						val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
							putExtra("sms_body", message)
						}
						startActivity(intent)
						result.success(true)
					}

					else -> result.notImplemented()
				}
			}
	}
}
