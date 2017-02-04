//
//  ResizableTagView.swift
//  Lunr
//
//  Created by Bobby Ren on 2/4/17.
//  Copyright © 2017 RenderApps. All rights reserved.
//

import Foundation
import UIKit

class Tag: NSObject {
    var text: String?
    var _view: UIView?
    
    // can contain other attributes like color, font, clickable, etc
    var view: UIView {
        if let existingView = _view {
            return existingView
        }
        else {
            var label = UILabel()
            label.numberOfLines = 1
            let font = UIFont(name: "Helvetica", size: 12.0)
            label.font = font
            label.text = self.text
            label.sizeToFit()
            _view = label
            return _view!
        }
    }
    
    func remove() {
        if let existingView = _view {
            existingView.removeFromSuperview()
        }
        _view = nil
    }
}

protocol ResizableTagViewDelegate {
    func didUpdateHeight(height: CGFloat)
}

class ResizableTagView: UIView {
    private var tags: [Tag] = [] {
        didSet {
            self.refresh()
        }
    }
    var delegate: ResizableTagViewDelegate?
    
    private var borderWidth: CGFloat = 5
    private var cellPadding: CGFloat = 5
    
    private func refresh() {
        self.clear()
        var x: CGFloat = borderWidth
        var y: CGFloat = borderWidth
        var height: CGFloat = 0
        for tag in tags {
            let view = tag.view
            if x + view.frame.size.width > self.frame.size.width - 2*borderWidth {
                x = borderWidth
                y = y + view.frame.size.height + cellPadding
            }
            self.addSubview(tag.view)
            x += view.frame.size.width + cellPadding
            height = y + view.frame.size.height + borderWidth
        }
        delegate?.didUpdateHeight(height: height)
    }
    
    func configureWithTags(tagStrings: [String]?) {
        var arr = [Tag]()
        if let strings = tagStrings {
            for str in strings {
                var tag = Tag()
                tag.text = str
                arr.append(tag)
            }
        }
        self.tags = arr
    }
    
    private func clear() {
        for tag in self.tags {
            tag.remove()
        }
    }

}
