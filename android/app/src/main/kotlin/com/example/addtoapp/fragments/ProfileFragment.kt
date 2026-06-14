package com.example.addtoapp.fragments

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.fragment.app.Fragment

class ProfileFragment : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        return TextView(requireContext()).apply {
            textSize = 20f
            textAlignment = View.TEXT_ALIGNMENT_CENTER
            setPadding(32, 32, 32, 32)
            text = "Profile (Native)\n\nNative Android tab. Flutter engine idle but alive."
        }
    }
}
