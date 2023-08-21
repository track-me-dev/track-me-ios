//
//  MovingCircle.swift
//  TrackMe
//
//  Created by 곽진현 on 2023/08/18.
//

import UIKit

class MovingCircleView: UIView {
    
    var circleCenter: CGPoint = .zero
    var circleRadius: CGFloat = 20.0
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.clear(rect)
        
        context.setFillColor(UIColor.blue.cgColor)
        context.addEllipse(in: CGRect(
            origin: CGPoint(x: circleCenter.x - circleRadius, y: circleCenter.y - circleRadius),
            size: CGSize(width: circleRadius * 2, height: circleRadius * 2)
        ))
        context.fillPath()
    }
}
