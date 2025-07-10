//
//  HTMLWebView.swift
//  Hanuman PDF Readers
//
//  Created by Neeshu Kumar on 22/06/25.
//


import SwiftUI
import WebKit

struct HTMLWebView: UIViewRepresentable {
    let fileName: String

    func makeUIView(context: Context) -> WKWebView {
        return WKWebView()
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if let filePath = Bundle.main.path(forResource: fileName, ofType: "html") {
            let fileURL = URL(fileURLWithPath: filePath)
            webView.loadFileURL(fileURL, allowingReadAccessTo: fileURL)
        }
    }
}

struct PrivacyPolicyView: View {
    var body: some View {
        NavigationView {
            HTMLWebView(fileName: "PrivacyPolicy")
                .navigationTitle("Privacy Policy")
                .navigationBarTitleDisplayMode(.inline)
        }
    }
}
