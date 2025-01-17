//
//  PostRowView.swift
//  NGA
//
//  Created by Bugen Zhao on 6/28/21.
//

import Foundation
import SwiftUI
import SwiftUIX

struct PostRowView: View {
  let post: Post
  let isAuthor: Bool

  @Binding var vote: VotesModel.Vote

  @OptionalEnvironmentObject<TopicDetailsActionModel> var action
  @OptionalEnvironmentObject<PostReplyModel> var postReply
  @EnvironmentObject var textSelection: TextSelectionModel
  @Environment(\.enableAuthorOnly) var enableAuthorOnly

  @StateObject var authStorage = AuthStorage.shared
  @StateObject var pref = PreferencesStorage.shared
  @StateObject var users = UsersModel.shared
  @StateObject var attachments: AttachmentsModel

  @State var showAttachments = false

  static func build(post: Post, isAuthor: Bool = false, vote: Binding<VotesModel.Vote>) -> Self {
    let attachments = AttachmentsModel(post.attachments)
    return .init(post: post, isAuthor: isAuthor, vote: vote, attachments: attachments)
  }

  private var user: User? {
    users.localUser(id: post.authorID)
  }

  var mock: Bool {
    post.id.tid.isMNGAMockID
  }

  var dummy: Bool {
    post.id == .dummy
  }

  @ViewBuilder
  var floor: some View {
    if post.floor != 0 {
      (Text("#").font(.footnote) + Text("\(post.floor)").font(.callout))
        .fontWeight(.medium)
        .foregroundColor(.accentColor)
    }
  }

  @ViewBuilder
  var menuButton: some View {
    #if os(iOS)
      if #available(iOS 15.0, *) {
        Menu(content: { menu }) {
          Image(systemName: "ellipsis.circle.fill")
            .symbolRenderingMode(.hierarchical)
            .imageScale(.large)
        }
      } else {
        Menu(content: { menu }) {
          Image(systemName: "ellipsis")
            .imageScale(.large)
        }
      }
    #endif
  }

  @ViewBuilder
  var header: some View {
    HStack {
      PostRowUserView(post: post, compact: false, isAuthor: isAuthor)
      Spacer()
      floor
      if !dummy { menuButton }
    }
  }

  @ViewBuilder
  var footer: some View {
    HStack {
      voter
      Spacer()
      Group {
        if !post.alterInfo.isEmpty {
          Image(systemName: "pencil")
        }
        DateTimeTextView.build(timestamp: post.postDate)
          .id(pref.postRowDateTimeStrategy)
        Image(systemName: post.device.icon)
          .frame(width: 10)
      }.foregroundColor(.secondary)
        .font(.footnote)
    }
  }

  @ViewBuilder
  var comments: some View {
    if !post.comments.isEmpty {
      Divider()
      HStack {
        Spacer().frame(width: 6, height: 1)
        VStack {
          ForEach(post.comments, id: \.hashIdentifiable) { comment in
            PostCommentRowView(comment: comment)
              .fixedSize(horizontal: false, vertical: true)
          }
        }
      }
    }
  }

  @ViewBuilder
  var voter: some View {
    HStack(spacing: 4) {
      Button(action: { doVote(.upvote) }) {
        Image(systemName: vote.state == .up ? "hand.thumbsup.fill" : "hand.thumbsup")
          .foregroundColor(vote.state == .up ? .accentColor : .secondary)
          .frame(height: 24)
      }.buttonStyle(PlainButtonStyle())

      let font = Font.subheadline.monospacedDigit()
      Text("\(max(Int32(post.score) + vote.delta, 0))")
        .foregroundColor(vote.state == .up ? .accentColor : .secondary)
        .font(vote.state == .up ? font.bold() : font)

      Button(action: { doVote(.downvote) }) {
        Image(systemName: vote.state == .down ? "hand.thumbsdown.fill" : "hand.thumbsdown")
          .foregroundColor(vote.state == .down ? .accentColor : .secondary)
          .frame(height: 24)
      }.buttonStyle(PlainButtonStyle())
    }
  }

  @ViewBuilder
  var signature: some View {
    if pref.showSignature, let sig = user?.signature, !sig.spans.isEmpty {
      Divider()
      UserSignatureView(content: sig, font: .subheadline, color: .secondary)
    }
  }

  @ViewBuilder
  var content: some View {
    BlockedView(content: BlockWordsStorage.content(user: user?.name ?? .init(), content: post.content.raw), revealOnTap: false) {
      PostContentView(content: post.content, id: post.id)
    }
  }

  @ViewBuilder
  var menu: some View {
    Section {
      Button(action: { textSelection.text = post.content.raw.replacingOccurrences(of: "<br/>", with: "\n") }) {
        Label("Select Text", systemImage: "selection.pin.in.out")
      }
      if #available(iOS 15.0, *), !attachments.items.isEmpty {
        Button(action: { showAttachments = true }) {
          Label("Attachments (\(attachments.items.count))", systemImage: "paperclip")
        }
      }
    }
    if let model = postReply, !mock, !dummy {
      Section {
        Button(action: { doQuote(model: model) }) {
          Label("Quote", systemImage: "quote.bubble")
        }
        Button(action: { doComment(model: model) }) {
          Label("Comment", systemImage: "tag")
        }
        if authStorage.authInfo.uid == post.authorID {
          Button(action: { doEdit(model: model) }) {
            Label("Edit", systemImage: "pencil")
          }
        }
        Button(role: .destructive, action: { doReport(model: model) }) {
          Label("Report", systemImage: "exclamationmark.bubble")
        }
      }
    }
    if let action = action {
      Section {
        if enableAuthorOnly, !(user?.isAnonymous ?? false) {
          Button(action: { action.navigateToAuthorOnly = post.authorID }) {
            Label("This Author Only", systemImage: "person")
          }
        }
      }
    }
  }

  @ViewBuilder
  var navigation: some View {
    if #available(iOS 15.0, *) {
      NavigationLink(destination: AttachmentsView(model: attachments), isActive: $showAttachments) {}.hidden()
    }
  }

  var body: some View {
    let body = VStack(alignment: .leading, spacing: 10) {
      header
      content
      footer
      comments
      signature
    }.padding(.vertical, 2)
      .fixedSize(horizontal: false, vertical: true)
    #if os(macOS)
      .contextMenu { menu }
    #endif
    #if os(iOS)
    .listRowBackground(action?.scrollToPid == self.post.id.pid ? Color.tertiarySystemBackground : nil)
    #endif
    .background { navigation }
    .environmentObject(attachments)

    if #available(iOS 15.0, *), let model = postReply, !mock {
      body
        .swipeActions(edge: pref.postRowSwipeActionLeading ? .leading : .trailing) {
          Button(action: { self.doQuote(model: model) }) {
            Image(systemName: "quote.bubble")
          }.tint(.accentColor)
        }
    } else {
      body
    }
  }

  func doVote(_ operation: PostVoteRequest.Operation) {
    if mock || dummy {
      #if os(iOS)
        HapticUtils.play(type: .warning)
      #endif
      return
    }

    logicCallAsync(.postVote(.with {
      $0.postID = post.id
      $0.operation = operation
    })) { (response: PostVoteResponse) in
      if !response.hasError {
        withAnimation {
          self.vote.state = response.state
          self.vote.delta += response.delta
          #if os(iOS)
            if self.vote.state != .none {
              HapticUtils.play(style: .light)
            }
          #endif
        }
      } else {
        // not used
      }
    }
  }

  func doQuote(model: PostReplyModel) {
    if dummy { return }

    model.show(action: .with {
      $0.postID = self.post.id
      $0.forumID = .with { f in
        f.fid = post.fid
      }
      $0.operation = .quote
    }, pageToReload: .last)
  }

  func doComment(model: PostReplyModel) {
    model.show(action: .with {
      $0.postID = self.post.id
      $0.forumID = .with { f in
        f.fid = post.fid
      }
      $0.operation = .comment
    }, pageToReload: .exact(Int(post.atPage)))
  }

  func doEdit(model: PostReplyModel) {
    model.show(action: .with {
      $0.postID = self.post.id
      $0.forumID = .with { f in
        f.fid = post.fid
      }
      $0.operation = .modify
    }, pageToReload: .exact(Int(post.atPage)))
  }

  func doReport(model: PostReplyModel) {
    model.show(action: .with {
      $0.postID = self.post.id
      $0.operation = .report
    })
  }
}
