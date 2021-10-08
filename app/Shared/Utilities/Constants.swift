//
//  Constants.swift
//  NGA
//
//  Created by Bugen Zhao on 7/12/21.
//

import Foundation

struct Constants {
  struct Activity {
    private static let base = "com.bugenzhao.NGA"

    static let openTopic = "\(base).openTopic"
    static let openForum = "\(base).openForum"
  }

  struct URL {
    static let base = "https://ngabbs.com/"
    static let attachmentBase = "https://img.nga.178.com/attachments/"
    static let testFlight = "https://testflight.apple.com/join/qFDuytLt"
  }

  struct Key {
    static let groupStore = "group.com.bugenzhao.MNGA"
    static let favoriteForums = "favoriteForums"
  }
}
