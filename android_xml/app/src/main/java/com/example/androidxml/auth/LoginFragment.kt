package com.example.androidxml.auth

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import androidx.fragment.app.Fragment
import androidx.navigation.fragment.findNavController
import com.example.androidxml.R

// Step 13 で WebView + JS Bridge に差し替える
class LoginFragment : Fragment() {
    override fun onCreateView(inflater: LayoutInflater, container: ViewGroup?, savedInstanceState: Bundle?): View {
        return LinearLayout(requireContext()).apply {
            orientation = LinearLayout.VERTICAL
            gravity = android.view.Gravity.CENTER
            addView(Button(requireContext()).apply {
                text = "ログイン（モック）"
                setOnClickListener {
                    findNavController().navigate(R.id.action_login_to_home)
                }
            })
        }
    }
}
