//
//  ContentView.swift
//  Ghostly
//
//  Created by Jay Stakelon on 1/1/21.
//

import SwiftUI

struct ContentView: View {
    private var placeholder: String = "hello there"
    @FocusState private var isTextEditorFocused: Bool
    @ObservedObject var themeManager = ThemeManager()
    @AppStorage("text") private var text: String = ""

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 0) {
                HeaderView(themeManager: themeManager)
                ZStack(alignment: .topLeading) {
                    TextEditor(text: $text)
                        .focused($isTextEditorFocused)
                        .font(Font.system(.body, design: .monospaced))
                        .scrollContentBackground(.hidden)
                        .padding(.leading, -5)
                        .foregroundColor(themeManager.textColor)
                    if text.isEmpty {
                        Text(placeholder)
                            .font(Font.system(.body, design: .monospaced))
                            .foregroundColor(themeManager.textColor)
                            .opacity(0.4)
                    }
                }.accentColor(.yellow)
                .padding(12)
                .background(themeManager.bgColor)
            }
            ZStack {
//                if themeManager.isThemeEditor {
                    Color(.shadowColor)
                        .opacity(themeManager.isThemeEditor ? 0.5 : 0)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            themeManager.hideThemeEditor()
                            isTextEditorFocused = true
                        }
                        .animation(.easeOut(duration: 0.25), value: themeManager.isThemeEditor)
                    ThemeEditorView(themeManager: themeManager)
                        .frame(width: 240, height: 240)
                        .offset(y: themeManager.isThemeEditor ? 0 : 400)
                        .animation(.easeOut(duration: 0.25), value: themeManager.isThemeEditor)
//                }
                
            }
        }
        .background(Color(.windowBackgroundColor))
        .onAppear {
            isTextEditorFocused = true
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

