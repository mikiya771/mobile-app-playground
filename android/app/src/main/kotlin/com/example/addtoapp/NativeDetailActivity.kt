package com.example.addtoapp

import android.os.Bundle
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

/**
 * Native screen opened in response to Flutter's `openNativeScreen` MethodChannel call.
 *
 * Presentation strategy: new Activity (startActivity).
 * Rationale: starting a new Activity is the cleanest Android way to present a full-screen
 * native screen from Flutter. It avoids z-ordering and back-stack interactions with
 * the FlutterFragment inside MainActivity. The user presses back to return to Flutter.
 * See README §"Flutter→Native push".
 */
class NativeDetailActivity : AppCompatActivity() {

    companion object {
        const val EXTRA_ROUTE = "route"
        const val EXTRA_ARGS  = "args"
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val route = intent.getStringExtra(EXTRA_ROUTE) ?: "(none)"
        val args  = intent.getStringExtra(EXTRA_ARGS)  ?: "{}"

        val tv = TextView(this).apply {
            textSize = 18f
            setPadding(48, 96, 48, 48)
            text = buildString {
                appendLine("Native Detail Screen")
                appendLine()
                appendLine("Route: $route")
                appendLine("Args:  $args")
                appendLine()
                appendLine("Opened via Flutter→Native MethodChannel (openNativeScreen).")
                appendLine("Press Back to return to Flutter.")
            }
        }
        setContentView(tv)

        supportActionBar?.apply {
            title = "Native Screen"
            setDisplayHomeAsUpEnabled(true)
        }
    }

    override fun onSupportNavigateUp(): Boolean {
        finish()
        return true
    }
}
