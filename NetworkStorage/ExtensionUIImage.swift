//
//  ExtensionUIImage.swift
//  DownloadImages
//
//  Created by Максим Игоревич on 23.11.2024.
//

import UIKit

extension UIImage {
    func makeCircular() -> UIImage {
            let minEdge = min(size.width, size.height)
            let rect = CGRect(x: 0, y: 0, width: minEdge, height: minEdge)
            UIGraphicsBeginImageContextWithOptions(rect.size, false, scale)
            defer { UIGraphicsEndImageContext() }

            let path = UIBezierPath(ovalIn: rect)
            path.addClip()
            draw(in: rect)

            return UIGraphicsGetImageFromCurrentImageContext() ?? self
        }

        func resized(to size: CGSize) -> UIImage {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            defer { UIGraphicsEndImageContext() }

            draw(in: CGRect(origin: .zero, size: size))
            return UIGraphicsGetImageFromCurrentImageContext() ?? self
        }
}
