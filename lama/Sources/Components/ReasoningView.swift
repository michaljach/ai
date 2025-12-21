//
//  ReasoningView.swift
//  lama
//
//  Created by Michal Jach on 21/12/2025.
//

import SwiftUI

struct ReasoningView: View {
  let reasoning: String
  @State private var isExpanded = false
  
  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Button {
        withAnimation(.easeInOut(duration: 0.2)) {
          isExpanded.toggle()
        }
      } label: {
        Text(reasoning)
          .font(.caption)
          .foregroundStyle(.gray)
          .lineLimit(isExpanded ? nil : 2)
          .multilineTextAlignment(.leading)
          .padding(10)
          .background(Color.colorGray.opacity(0.5))
          .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
//    .padding(.horizontal, 16)
//    .padding(.vertical, 12)
  }
}

#Preview {
  ReasoningView(reasoning: "The user is asking about web search. I need to search for the latest information about web search and then provide a comprehensive answer with sources.")
}
