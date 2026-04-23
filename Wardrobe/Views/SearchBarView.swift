//
//  SearchBarView.swift
//  Wardrobe
//
//  Created by Shawon Ashraf on 23/04/2026.
//

import SwiftUI

struct SearchBarView: View {
    @Binding var searchQuery: String
    let onSearch: () -> Void
    var placeholder: String = "Search screenshots..."
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
            
            TextField(placeholder, text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 13))
                .onSubmit {
                    onSearch()
                }
                .onChange(of: searchQuery) { _, _ in
                    onSearch()
                }
            
            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                    onSearch()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 7)
                .fill(Color.secondary.opacity(0.15))
        )
    }
}

struct SemanticSearchBar: View {
    @Binding var searchQuery: String
    let onSearch: () -> Void
    let onClear: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
            
            TextField("Search screenshots...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 14))
                .focused($isFocused)
                .onSubmit {
                    onSearch()
                }
                .onChange(of: searchQuery) { _, _ in
                    onSearch()
                }
            
            if !searchQuery.isEmpty {
                Button {
                    onClear()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.secondary.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isFocused ? Color.accentColor.opacity(0.6) : Color.clear, lineWidth: 1)
                )
        )
    }
}

struct HeroSearchBar: View {
    @Binding var searchQuery: String
    let onSearch: () -> Void
    
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(.secondary)
            
            TextField("Search screenshots...", text: $searchQuery)
                .textFieldStyle(.plain)
                .font(.system(size: 16, weight: .medium))
                .focused($isFocused)
                .onSubmit(onSearch)
                .onChange(of: searchQuery) { _, _ in
                    onSearch()
                }
            
            Spacer(minLength: 0)
            
            HStack(spacing: 6) {
                Text("Semantic Search")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(Color.secondary.opacity(0.15))
                    )
                
                HStack(spacing: 2) {
                    Image(systemName: "command")
                        .font(.system(size: 10, weight: .semibold))
                    Text("K")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                )
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.secondary.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isFocused ? Color.accentColor.opacity(0.5) : Color.secondary.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        HeroSearchBar(searchQuery: .constant("rece"), onSearch: {})
            .frame(width: 540)
        
        SemanticSearchBar(searchQuery: .constant(""), onSearch: {}, onClear: {})
            .frame(width: 380)
        
        SearchBarView(searchQuery: .constant(""), onSearch: {})
            .frame(width: 300)
    }
    .padding(40)
    .preferredColorScheme(.dark)
}
