//
//  STGIFMaker.swift
//  STMovingImages
//
//  Created by nst on 21/11/15.
//  Copyright © 2015 Nicolas Seriot. All rights reserved.
//

#if os(OSX)
    import AppKit
    import CoreServices
    public typealias STImage = NSImage
#elseif os(iOS)
    import UIKit
    import MobileCoreServices
    import CoreGraphics
    import ImageIO
    public typealias STImage = UIImage
#endif

public class STGIFMaker {
    
    let imageDestination : CGImageDestination
    let outPath : String
    
    init?(destinationPath: String, loop: Bool) {
        
        guard let id = CGImageDestinationCreateWithURL(
            URL(fileURLWithPath: destinationPath) as CFURL,
            kUTTypeGIF,
            0,
            nil) else {
                return nil
        }
        
        self.imageDestination = id
        self.outPath = destinationPath
        
        let loopCount = loop ? 0 : 1
        let gifProperties = [ kCGImagePropertyGIFDictionary as String : [kCGImagePropertyGIFLoopCount as String:loopCount] ] as CFDictionary
        
        CGImageDestinationSetProperties(imageDestination, gifProperties)
    }
 
    func append(image : STImage, duration : Double) {
        #if os(OSX)
            let optCGImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil)
        #elseif os(iOS)
            let optCGImage = image.cgImage
        #endif
        
        guard let cgImage = optCGImage else { assertionFailure(); return }
        let frameProperties = [ kCGImagePropertyGIFDictionary as String : [kCGImagePropertyGIFDelayTime as String:duration] ] as CFDictionary
        CGImageDestinationAddImage(imageDestination, cgImage, frameProperties)
    }
    
    func write() -> Bool {
        
        let success = CGImageDestinationFinalize(imageDestination)
        
        if success {
            print("-- wrote \(outPath)")
        }
        
        return success
    }
    
}
