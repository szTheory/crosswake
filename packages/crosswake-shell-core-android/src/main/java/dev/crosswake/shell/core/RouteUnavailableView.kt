package dev.crosswake.shell.core

import android.content.Context
import android.graphics.Color
import android.graphics.Typeface
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class RouteUnavailableView(
    context: Context,
    private val denial: RouteDenialPresentation,
    private val onAction: (RouteUnavailableAction) -> Unit
) : LinearLayout(context) {

    init {
        orientation = VERTICAL
        val padding = dpToPx(24)
        setPadding(padding, padding, padding, padding)
        setBackgroundColor(Color.parseColor("#F2F2F7"))
        gravity = Gravity.START or Gravity.TOP

        addView(TextView(context).apply {
            text = denial.title
            textSize = 32f
            setTypeface(null, Typeface.BOLD)
            setTextColor(Color.BLACK)
            setPadding(0, 0, 0, dpToPx(18))
        })

        addView(TextView(context).apply {
            text = denial.message
            textSize = 16f
            setTextColor(Color.BLACK)
            setPadding(0, 0, 0, dpToPx(18))
        })

        denial.hint?.let { hint ->
            addView(TextView(context).apply {
                text = hint
                textSize = 14f
                setTextColor(Color.DKGRAY)
                setPadding(0, 0, 0, dpToPx(18))
            })
        }

        denial.routeId?.let { routeId ->
            addView(TextView(context).apply {
                text = "Route: $routeId"
                textSize = 12f
                typeface = Typeface.MONOSPACE
                setTextColor(Color.DKGRAY)
                setPadding(0, 0, 0, dpToPx(18))
            })
        }

        val actionsContainer = LinearLayout(context).apply {
            orientation = VERTICAL
            layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT)
        }

        denial.actions.forEach { action ->
            actionsContainer.addView(Button(context).apply {
                text = actionTitle(action)
                setOnClickListener { onAction(action) }
                layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT).apply {
                    setMargins(0, 0, 0, dpToPx(10))
                }
            })
        }

        addView(actionsContainer)
    }

    private fun actionTitle(action: RouteUnavailableAction): String {
        return when (action) {
            RouteUnavailableAction.RETRY -> "Retry"
            RouteUnavailableAction.UPDATE_APP -> "Update app"
            RouteUnavailableAction.SAFE_FALLBACK -> "Open safe fallback"
        }
    }

    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
}
