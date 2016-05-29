//
//  GradientView.swift
//  Wallpapers
//
//  Created by Mic Pringle on 09/01/2015.
//  Copyright (c) 2015 Razeware LLC. All rights reserved.
//

import UIKit

@IBDesignable
class GradientView: UIView {
    static let lightGreen = UIColor(red: 0.8, green: 1, blue: 0.8, alpha: 1)
    static let lightPink = UIColor(red: 1, green: 0.7, blue: 0.7, alpha: 1.0)
    @IBInspectable var startColor = lightPink {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var midColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.5) {
        didSet {
            self.setNeedsDisplay()
        }
    }
    @IBInspectable var endColor = lightGreen {
        didSet {
            self.setNeedsDisplay()
        }
    }

  lazy private var gradientLayer: CAGradientLayer = {
    let layer = CAGradientLayer()
    layer.colors = [self.startColor.CGColor, self.endColor.CGColor]
    layer.locations = [NSNumber(float: 0.0), NSNumber(float: 1.0)]
//    layer.colors = [self.startColor.CGColor, self.midColor.CGColor, self.endColor.CGColor]
//    layer.locations = [NSNumber(float: 0.0), NSNumber(float: 0.5),NSNumber(float: 1.0)]
    return layer
    }()
  
  override func awakeFromNib() {
    super.awakeFromNib()
    backgroundColor = UIColor.clearColor()
    layer.addSublayer(gradientLayer)
  }
  
  override func layoutSubviews() {
    super.layoutSubviews()
    gradientLayer.frame = bounds
  }
  
}
