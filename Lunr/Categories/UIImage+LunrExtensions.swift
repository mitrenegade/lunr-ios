//
//  UIImage+LunrExtensions.swift
//  Lunr
//
//  Created by Brent Raines on 9/20/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import Foundation

extension UIImage {
    func fixOrientation() -> UIImage {
        guard imageOrientation != .Up else { return self }
        var transform = CGAffineTransformIdentity
        
        switch imageOrientation {
        case .Down, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI))
            break
        case .Left, .LeftMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformRotate(transform, CGFloat(M_PI_2))
            break
        case .Right, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, size.height)
            transform = CGAffineTransformRotate(transform, CGFloat(-M_PI_2))
            break
        default:
            break
        }
        
        switch imageOrientation {
        case .UpMirrored, .DownMirrored:
            transform = CGAffineTransformTranslate(transform, size.width, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
            break
        case .LeftMirrored, .RightMirrored:
            transform = CGAffineTransformTranslate(transform, size.height, 0)
            transform = CGAffineTransformScale(transform, -1, 1)
            break
        default:
            break
        }
        
        let context = CGBitmapContextCreate(
            UnsafeMutablePointer(nil),
            Int(size.width),
            Int(size.height),
            CGImageGetBitsPerComponent(self.CGImage),
            0,
            CGImageGetColorSpace(self.CGImage),
            CGImageGetBitmapInfo(self.CGImage).rawValue
        )
        
        CGContextConcatCTM(context, transform)
        switch imageOrientation {
        case .Left, .LeftMirrored, .Right, .RightMirrored:
            CGContextDrawImage(context, CGRect(x: 0, y: 0, width: size.height, height: size.width), self.CGImage)
            break
        default:
            CGContextDrawImage(context, CGRect(x: 0, y: 0, width: size.width, height: size.height), self.CGImage)
            break
        }
        
        let cgImage = CGBitmapContextCreateImage(context)!
        
        return UIImage(CGImage: cgImage)
    }
}