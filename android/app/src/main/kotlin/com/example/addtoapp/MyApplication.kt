package com.example.addtoapp

import android.app.Application
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor

/**
 * Warms up the single shared FlutterEngine at Application.onCreate().
 *
 * Architecture constraint: exactly one FlutterEngine is created for the lifetime
 * of the app process. It hosts both the Search and Shop Flutter branches.
 * A second engine must never be created — that would break shared-state semantics
 * and double memory/CPU cost.
 *
 * Why Application.onCreate() and not MainActivity.onCreate()?
 * Warming up here decouples engine readiness from Activity lifecycle.
 * The engine is ready before the first frame, avoiding cold-start jank when
 * the user navigates to a Flutter tab.
 */
class MyApplication : Application() {

    companion object {
        /** Cache key — used wherever the engine must be retrieved. */
        const val ENGINE_ID = "main_flutter_engine"
    }

    override fun onCreate() {
        super.onCreate()

        val engine = FlutterEngine(this)
        engine.dartExecutor.executeDartEntrypoint(
            DartExecutor.DartEntrypoint.createDefault()
        )
        FlutterEngineCache.getInstance().put(ENGINE_ID, engine)
    }
}
